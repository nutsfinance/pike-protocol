// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";
import {ISpoke} from "./interfaces/ISpoke.sol";
import {SpokeStorage} from "./SpokeStorage.sol";
import {SpokeModifiers} from "./SpokeModifiers.sol";
import {CCTPChannel} from "@gateway/channels/cctp/CCTPChannel.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract SpokeInternals is ISpoke, SpokeStorage, SpokeModifiers {
    function confirmBorrow(DataTypes.SpokeBorrowForward memory a)
        internal
        onlyValidArgs(a.user, a.borrowAmount)
    {
        emit PikeBorrowActionCompleted(
            spokeChainId,
            a.assetType,
            a.user,
            a.nonce,
            block.timestamp,
            a.assetToken,
            a.usdcMintRequired,
            a.borrowAmount
        );

        transferAssets(a.assetType, a.assetToken, a.user, a.borrowAmount);
    }

    function confirmWithdrawal(DataTypes.SpokeWithdrawalForward memory a) internal {
        if (a.withdrawAmount == 0) {
            revert Errors.ZeroValueProvided();
        }
        if (a.user == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }

        emit PikeWithdrawalActionCompleted(
            spokeChainId,
            a.assetType,
            a.user,
            a.nonce,
            block.timestamp,
            a.assetToken,
            a.withdrawAmount,
            a.usdcMintRequired
        );

        transferAssets(a.assetType, a.assetToken, a.user, a.withdrawAmount);
    }

    function confirmLiquidation(DataTypes.SpokeLiquidateForward memory a) internal {
        if (a.sourceChainId != spokeChainId) revert Errors.SpokeNotFound();
        if (a.user == a.liquidator) revert Errors.InvalidArguments();
        if (a.liquidator == address(0)) revert Errors.ZeroAddressNotValid();

        emit PikeLiquidationActionCompleted(
            spokeChainId,
            a.assetType,
            a.liquidator,
            a.user,
            block.timestamp,
            a.nonce,
            a.targetToken,
            a.totalDiscounted,
            a.seizedShare
        );
    }

    function transferAssets(
        DataTypes.Asset asset,
        address token,
        address user,
        uint256 amount
    )
        internal
    {
        if (asset == DataTypes.Asset.EVM) {
            if (address(this).balance < amount) revert Errors.ReserveNotEnough();

            (bool success,) = payable(user).call{value: amount}("");

            if (!success) revert Errors.AssetTransferFailed();
        } else if (asset == DataTypes.Asset.USDC) {
            if (!CCTPChannel(payable(cctpChannel)).safeTransfer(user, amount)) {
                revert Errors.AssetTransferFailed();
            }
        } else if (asset == DataTypes.Asset.ERC) {
            if (!IERC20(token).transfer(user, amount)) {
                revert Errors.AssetTransferFailed();
            }
        } else {
            revert Errors.AssetTransferFailed();
        }
    }

    function getTransport() internal view returns (DataTypes.Transport transport) {
        transport = spokeChainId == hubChainId
            ? DataTypes.Transport.INTRACHAIN
            : DataTypes.Transport.WORMHOLE;
    }

    function inferAssetType(address token) internal view returns (DataTypes.Asset) {
        DataTypes.Asset assetType = assetTypes[token];
        if (assetType == DataTypes.Asset.NULL) revert Errors.InvalidArguments();
        return assetType;
    }
}
