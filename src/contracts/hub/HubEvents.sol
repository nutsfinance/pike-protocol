// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

abstract contract HubEvents {
    event PikeDepositActionProcessed(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        uint256 amountDeposited
    );

    event PikeBorrowActionProcessed(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        bool usdcMintRequired,
        uint256 borrowAmount
    );

    event PikeRepayActionProcessed(
        uint16 indexed targetChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint16 sourceChainId,
        uint256 nonce,
        uint256 timestamp,
        address sourceToken,
        address targetToken,
        uint256 repaidAmount
    );

    event PikeWithdrawalActionProcessed(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address assetToken,
        uint256 withdrawAmount,
        bool usdcMintRequired
    );

    event PikeLiquidationActionProcessed(
        uint16 indexed spokeChainId,
        DataTypes.Asset indexed asset,
        address indexed user,
        uint256 nonce,
        uint256 timestamp,
        address sourceToken,
        address targetToken,
        address liquidator,
        uint256 repayAmount,
        bool usdcMintRequired,
        uint256 totalDiscounted,
        uint256 seizedShare
    );
}
