// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";
import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {SpokeInternals} from "./SpokeInternals.sol";
import {DataTypes} from "@types/DataTypes.sol";

import {Errors} from "@utils/Errors.sol";

abstract contract SpokeHandler is SpokeInternals {
    /**
     * @notice Contains the general supply logic
     */
    function initiateSupply(
        address depositor,
        uint256 depositAmount,
        uint256 forwardCost
    )
        internal
        onlyActiveChain
        meetsFirstMintDeposit(depositAmount)
    {
        uint256 _nonce = nonce++;
        emit PikeDepositActionInitiated(
            spokeChainId,
            DataTypes.Asset.EVM,
            depositor,
            _nonce,
            block.timestamp,
            nativeAsset,
            depositAmount
        );

        IGateway(gateway).pike_send{value: forwardCost}(
            getTransport(),
            hubChainId,
            abi.encode(
                DataTypes.HubDeposit({
                    action: DataTypes.Action.HUB_DEPOSIT,
                    nonce: _nonce,
                    assetType: DataTypes.Asset.EVM,
                    transport: getTransport(),
                    user: depositor,
                    assetToken: nativeAsset,
                    amountDeposited: depositAmount,
                    forwardCost: forwardCost,
                    sourceChainId: spokeChainId,
                    targetChainId: spokeChainId
                })
            ),
            forwardCost
        );
    }

    function initiateSupplyErc(DataTypes.SupplyErcInputVars memory a)
        internal
        onlyActiveChain
        meetsFirstMintDeposit(a.depositAmount)
        onlyValidArgs(a.assetToken, a.depositAmount)
    {
        if (a.assetType == DataTypes.Asset.USDC) {
            if (
                !IERC20(a.assetToken).transferFrom(
                    msg.sender, cctpChannel, a.depositAmount
                )
            ) {
                revert Errors.AssetTransferFailed();
            }
        } else {
            if (
                !IERC20(a.assetToken).transferFrom(
                    msg.sender, address(this), a.depositAmount
                )
            ) {
                revert Errors.AssetTransferFailed();
            }
        }
        uint256 _nonce = nonce++;
        emit PikeDepositActionInitiated(
            spokeChainId,
            a.assetType,
            msg.sender,
            _nonce,
            block.timestamp,
            a.assetToken,
            a.depositAmount
        );

        IGateway(gateway).pike_send{value: a.forwardCost}(
            getTransport(),
            hubChainId,
            abi.encode(
                DataTypes.HubDeposit({
                    action: DataTypes.Action.HUB_DEPOSIT,
                    nonce: _nonce,
                    assetType: a.assetType,
                    transport: getTransport(),
                    user: msg.sender,
                    assetToken: a.assetToken,
                    amountDeposited: a.depositAmount,
                    forwardCost: a.forwardCost,
                    sourceChainId: spokeChainId,
                    targetChainId: spokeChainId
                })
            ),
            a.forwardCost
        );
    }

    /**
     * @notice Contains the general borrow logic
     */
    function initiateBorrow(DataTypes.BorrowInputVars memory a)
        internal
        onlyActiveChain
        onlyHubChain
        onlyValidArgs(a.borrower, a.borrowAmount)
    {
        IGateway(gateway).pike_send{value: a.forwardCost}(
            DataTypes.Transport.INTRACHAIN,
            hubChainId,
            abi.encode(
                DataTypes.HubBorrow({
                    action: DataTypes.Action.HUB_BORROW,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.borrower,
                    assetToken: a.assetToken,
                    borrowAmount: a.borrowAmount,
                    usdcMintRequired: a.usdcMintRequired,
                    targetAddress: a.targetAddress,
                    forwardCost: a.forwardCost,
                    sourceChainId: spokeChainId,
                    targetChainId: a.targetChainId,
                    cctpTargetChainId: a.cctpTargetChainId
                })
            ),
            a.forwardCost
        );
    }

    /**
     * @notice Contains the general repay logic
     */
    function initiateRepay(
        address repayer,
        uint256 repayAmount,
        uint256 forwardCost
    )
        internal
        onlyActiveChain
        onlyValidArgs(repayer, msg.value)
    {
        uint256 _nonce = nonce++;
        emit PikeRepayActionInitiated(
            spokeChainId,
            DataTypes.Asset.EVM,
            repayer,
            _nonce,
            block.timestamp,
            spokeChainId,
            nativeAsset,
            nativeAsset,
            repayAmount
        );

        IGateway(gateway).pike_send{value: forwardCost}(
            getTransport(),
            hubChainId,
            abi.encode(
                DataTypes.HubRepay({
                    action: DataTypes.Action.HUB_REPAY,
                    nonce: _nonce,
                    assetType: DataTypes.Asset.EVM,
                    transport: getTransport(),
                    user: repayer,
                    sourceToken: nativeAsset,
                    targetToken: nativeAsset,
                    repaidAmount: repayAmount,
                    forwardCost: forwardCost,
                    fullRepayment: repayAmount == ~uint256(0),
                    sourceChainId: spokeChainId,
                    targetChainId: spokeChainId
                })
            ),
            forwardCost
        );
    }

    function initiateRepayErc(DataTypes.RepayErcInputVars memory a)
        internal
        onlyActiveChain
        onlyValidArgs(a.repayer, a.repayAmount)
    {
        uint256 _nonce = nonce++;
        emit PikeRepayActionInitiated(
            spokeChainId,
            a.assetType,
            a.repayer,
            _nonce,
            block.timestamp,
            a.targetChainId,
            a.assetToken,
            a.targetToken,
            a.repayAmount
        );

        if (a.assetType == DataTypes.Asset.USDC) {
            if (
                !IERC20(a.assetToken).transferFrom(msg.sender, cctpChannel, a.repayAmount)
            ) {
                revert Errors.AssetTransferFailed();
            }
        } else {
            if (
                !IERC20(a.assetToken).transferFrom(
                    msg.sender, address(this), a.repayAmount
                )
            ) {
                revert Errors.AssetTransferFailed();
            }
        }
        IGateway(gateway).pike_send{value: a.forwardCost}(
            getTransport(),
            hubChainId,
            abi.encode(
                DataTypes.HubRepay({
                    action: DataTypes.Action.HUB_REPAY,
                    nonce: _nonce,
                    assetType: a.assetType,
                    transport: getTransport(),
                    user: a.repayer,
                    sourceToken: a.assetToken,
                    targetToken: a.targetToken,
                    repaidAmount: a.repayAmount,
                    forwardCost: a.forwardCost,
                    fullRepayment: a.repayAmount == ~uint256(0),
                    sourceChainId: spokeChainId,
                    targetChainId: a.targetChainId
                })
            ),
            a.forwardCost
        );
    }

    /**
     * @notice Contains the general withdraw logic
     */
    function initiateWithdraw(DataTypes.WithdrawalInputVars memory a)
        internal
        onlyActiveChain
        onlyHubChain
        onlyValidArgs(a.withdrawer, a.withdrawAmount)
    {
        IGateway(gateway).pike_send{value: a.forwardCost}(
            DataTypes.Transport.INTRACHAIN,
            hubChainId,
            abi.encode(
                DataTypes.HubWithdrawal({
                    action: DataTypes.Action.HUB_WITHDRAWAL,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.withdrawer,
                    assetToken: a.assetToken,
                    withdrawAmount: a.withdrawAmount,
                    usdcMintRequired: a.usdcMintRequired,
                    targetAddress: a.targetAddress,
                    forwardCost: a.forwardCost,
                    fullWithdrawal: a.withdrawAmount == ~uint256(0),
                    sourceChainId: spokeChainId,
                    targetChainId: a.targetChainId,
                    cctpTargetChainId: a.cctpTargetChainId
                })
            ),
            a.forwardCost
        );
    }

    function initiateLiquidation(DataTypes.LiquidationInputVars memory a)
        internal
        onlyActiveChain
        onlyHubChain
        onlyValidArgs(a.borrower, a.repayAmount)
    {
        if (a.borrower == msg.sender) {
            revert Errors.InvalidArguments();
        }
        if (a.assetType == DataTypes.Asset.EVM) {
            if (msg.value != a.repayAmount + a.forwardCost) {
                revert Errors.InvalidArguments();
            }
        } else {
            /// @dev For ERC20 tokens, incl. USDC asset
            if (msg.value != a.forwardCost) {
                revert Errors.InvalidArguments();
            }

            if (
                !IERC20(a.assetToken).transferFrom(
                    msg.sender, address(this), a.repayAmount
                )
            ) {
                revert Errors.AssetTransferFailed();
            }
        }

        IGateway(gateway).pike_send{value: a.forwardCost}(
            DataTypes.Transport.INTRACHAIN,
            hubChainId,
            abi.encode(
                DataTypes.HubLiquidate({
                    action: DataTypes.Action.HUB_LIQUIDATE,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.borrower,
                    sourceToken: a.assetToken,
                    targetToken: a.targetToken,
                    liquidator: msg.sender,
                    repayAmount: a.repayAmount,
                    usdcMintRequired: a.usdcMintRequired,
                    forwardCost: a.forwardCost,
                    sourceChainId: spokeChainId,
                    targetChainId: a.targetChainId
                })
            ),
            a.forwardCost
        );
    }
}
