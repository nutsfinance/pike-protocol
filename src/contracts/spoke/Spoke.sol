// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {SpokeHandler} from "./SpokeHandler.sol";
import {SpokeAdmin} from "./SpokeAdmin.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract Spoke is SpokeHandler, Initializable, UUPSUpgradeable, SpokeAdmin {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _gateway,
        address _hubGateway,
        address _endpoint,
        address payable _cctpChannel,
        uint16 _hubChainId,
        uint16 _spokeChainId
    )
        public
        initializer
    {
        __UUPSUpgradeable_init();
        gateway = IGateway(_gateway);
        hubGateway = IGateway(_hubGateway);
        hubChainId = _hubChainId;
        spokeChainId = _spokeChainId;
        admin = msg.sender;
        endpoint = _endpoint;
        cctpChannel = _cctpChannel;
        isActive = true;
        nativeAsset = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function supplyErc(
        address assetToken,
        uint256 depositAmount,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        DataTypes.Asset assetType = inferAssetType(assetToken);
        initiateSupplyErc(
            DataTypes.SupplyErcInputVars({
                assetType: assetType,
                assetToken: assetToken,
                depositAmount: depositAmount,
                forwardCost: forwardCost
            })
        );
    }

    function supply(
        uint256 depositAmount,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        if (msg.value != depositAmount + forwardCost) revert Errors.InvalidArguments();
        initiateSupply(address(msg.sender), depositAmount, forwardCost);
    }

    /**
     * @notice Initiates a borrow operation for a user
     * @param borrowAmount The amount of the asset to borrow
     * @param usdcMintRequired If true, the user borrows at a stable interest rate
     * @param targetChainId ID of the chain where the asset is borrowed
     * @param targetAddress The address where the borrowed asset is sent
     */
    function borrow(
        DataTypes.Transport transport,
        address assetToken,
        uint256 borrowAmount,
        bool usdcMintRequired,
        uint16 targetChainId,
        address targetAddress,
        uint16 cctpTargetChainId,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        DataTypes.Asset assetType = inferAssetType(assetToken);
        initiateBorrow(
            DataTypes.BorrowInputVars({
                assetType: assetType,
                transport: transport,
                assetToken: assetToken,
                borrower: address(msg.sender),
                borrowAmount: borrowAmount,
                usdcMintRequired: usdcMintRequired,
                targetChainId: targetChainId,
                targetAddress: targetAddress,
                cctpTargetChainId: cctpTargetChainId,
                forwardCost: forwardCost
            })
        );
    }

    function repayErc(
        address assetToken,
        address targetToken,
        uint16 targetChainId,
        uint256 repayAmount,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        DataTypes.Asset assetType = inferAssetType(assetToken);
        initiateRepayErc(
            DataTypes.RepayErcInputVars({
                assetType: assetType,
                repayer: address(msg.sender),
                assetToken: assetToken,
                targetToken: targetToken,
                targetChainId: targetChainId,
                repayAmount: repayAmount,
                forwardCost: forwardCost
            })
        );
    }

    function repay(
        uint256 repayAmount,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        if (msg.value != repayAmount + forwardCost) revert Errors.InvalidArguments();
        initiateRepay(address(msg.sender), repayAmount, forwardCost);
    }

    /**
     * @notice Initiates a withdrawal from `sourceChainId` to `targetChainId`
     * @param withdrawAmount Amount of the asset to withdraw
     * @param targetChainId ID of the chain to which to withdraw
     */
    function withdraw(
        DataTypes.Transport transport,
        address assetToken,
        uint256 withdrawAmount,
        bool usdcMintRequired,
        uint16 targetChainId,
        address targetAddress,
        uint16 cctpTargetChainId,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        DataTypes.Asset assetType = inferAssetType(assetToken);
        bytes32 key = keccak256(
            abi.encode(
                transport,
                assetType,
                assetToken,
                address(msg.sender),
                targetAddress,
                withdrawAmount,
                block.timestamp,
                usdcMintRequired,
                forwardCost,
                spokeChainId,
                targetChainId,
                cctpTargetChainId
            )
        );
        queuedWithdrawals[key] = QueuedWithdrawal({
            transport: transport,
            assetType: assetType,
            assetToken: assetToken,
            user: address(msg.sender),
            targetAddress: targetAddress,
            amount: withdrawAmount,
            timestamp: block.timestamp,
            usdcMintRequired: usdcMintRequired,
            forwardCost: forwardCost,
            sourceChainId: spokeChainId,
            targetChainId: targetChainId,
            cctpTargetChainId: cctpTargetChainId
        });

        emit WithdrawalQueued(
            msg.sender, assetToken, key, withdrawAmount, block.timestamp, targetChainId
        );
    }

    function executeWithdrawal(bytes32 key) external whenNotPaused {
        QueuedWithdrawal memory w = queuedWithdrawals[key];
        if (block.timestamp < w.timestamp + 1 hours) revert Errors.OperationTooSoon();

        delete queuedWithdrawals[key];

        initiateWithdraw(
            DataTypes.WithdrawalInputVars({
                assetType: w.assetType,
                transport: w.transport,
                assetToken: w.assetToken,
                withdrawer: w.user,
                withdrawAmount: w.amount,
                usdcMintRequired: w.usdcMintRequired,
                targetChainId: w.targetChainId,
                targetAddress: w.targetAddress,
                cctpTargetChainId: w.cctpTargetChainId,
                forwardCost: w.forwardCost
            })
        );
    }

    /**
     * @notice Initiates the liquidation process for a borrower's position
     * @param chainId ID of the chain where the borrower's position is held
     * @param borrower Address of the borrower whose position is being liquidated
     * @param repayAmount Amount the liquidator is repaying on behalf of borrower
     */
    function liquidate(
        DataTypes.Transport transport,
        address assetToken,
        address targetToken,
        uint16 chainId,
        address borrower,
        uint256 repayAmount,
        bool usdcMintRequired,
        uint256 forwardCost
    )
        external
        payable
        whenNotPaused
    {
        DataTypes.Asset assetType = inferAssetType(assetToken);
        initiateLiquidation(
            DataTypes.LiquidationInputVars({
                assetType: assetType,
                transport: transport,
                assetToken: assetToken,
                targetToken: targetToken,
                borrower: borrower,
                repayAmount: repayAmount,
                usdcMintRequired: usdcMintRequired,
                targetChainId: chainId,
                forwardCost: forwardCost
            })
        );
    }

    function borrowApproved(DataTypes.SpokeBorrowForward memory args)
        public
        onlyGateway
    {
        confirmBorrow(args);
    }

    function withdrawalApproved(DataTypes.SpokeWithdrawalForward memory args)
        public
        onlyGateway
    {
        confirmWithdrawal(args);
    }

    function liquidationApproved(DataTypes.SpokeLiquidateForward memory args)
        public
        onlyGateway
    {
        confirmLiquidation(args);
    }

    function supplyDeclined(DataTypes.SpokeDecline memory args) public onlyGateway {
        emit SupplyRequestDeclined(args.user, args.amount);
    }

    function borrowDeclined(DataTypes.SpokeDecline memory args) public onlyGateway {
        emit BorrowRequestDeclined(args.user, args.amount);
    }

    function repayDeclined(DataTypes.SpokeDecline memory args) public onlyGateway {
        emit RepayRequestDeclined(args.user, args.amount);
    }

    function withdrawalDeclined(DataTypes.SpokeDecline memory args) public onlyGateway {
        emit WithdrawalRequestDeclined(args.user, args.amount);
    }

    function liquidationDeclined(DataTypes.SpokeDecline memory args) public onlyGateway {
        emit LiquidationRequestDeclined(args.user, args.amount);
    }

    /// @notice Fallback function to accept native transfers
    receive() external payable {}
}
