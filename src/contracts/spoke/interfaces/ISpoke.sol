// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

interface ISpoke {
    event PikeDepositActionInitiated(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        uint256 amountDeposited
    );

    event PikeBorrowActionCompleted(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        bool usdcMintRequired,
        uint256 borrowAmount
    );

    event PikeRepayActionInitiated(
        uint16 indexed sourceChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        uint16 targetChainId,
        address sourceToken,
        address targetToken,
        uint256 repaidAmount
    );

    event PikeWithdrawalActionCompleted(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        uint256 withdrawAmount,
        bool usdcMintRequired
    );

    event PikeLiquidationActionCompleted(
        uint16 indexed spokeChainId,
        DataTypes.Asset asset,
        address indexed liquidator,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address targetToken,
        uint256 totalDiscounted,
        uint256 seizedShare
    );

    event SupplyRequestDeclined(address indexed user, uint256 amount);
    event BorrowRequestDeclined(address indexed user, uint256 amount);
    event RepayRequestDeclined(address indexed user, uint256 amount);
    event WithdrawalRequestDeclined(address indexed user, uint256 amount);
    event LiquidationRequestDeclined(address indexed user, uint256 amount);

    event WithdrawalQueued(
        address indexed user,
        address indexed assetToken,
        bytes32 key,
        uint256 amount,
        uint256 timestamp,
        uint16 indexed targetChainId
    );

    function supplyErc(
        address token,
        uint256 amount,
        uint256 forwardCost
    )
        external
        payable;

    function supply(uint256 depositAmount, uint256 forwardCost) external payable;

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
        payable;

    function repayErc(
        address token,
        address targetToken,
        uint16 targetChainId,
        uint256 amount,
        uint256 forwardCost
    )
        external
        payable;

    function repay(uint256 repayAmount, uint256 forwardCost) external payable;

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
        payable;

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
        payable;

    function borrowApproved(DataTypes.SpokeBorrowForward memory args) external;
    function withdrawalApproved(DataTypes.SpokeWithdrawalForward memory args) external;
    function liquidationApproved(DataTypes.SpokeLiquidateForward memory args) external;

    function supplyDeclined(DataTypes.SpokeDecline memory args) external;
    function borrowDeclined(DataTypes.SpokeDecline memory args) external;
    function repayDeclined(DataTypes.SpokeDecline memory args) external;
    function withdrawalDeclined(DataTypes.SpokeDecline memory args) external;
    function liquidationDeclined(DataTypes.SpokeDecline memory args) external;
}
