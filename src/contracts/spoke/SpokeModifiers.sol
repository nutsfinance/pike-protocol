// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SpokeStorage} from "@spoke/SpokeStorage.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract SpokeModifiers is SpokeStorage {
    modifier onlyActiveChain() {
        if (!isActive) {
            revert Errors.SpokeNotActive();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyGateway() {
        if (msg.sender != address(gateway) && msg.sender != address(hubGateway)) {
            revert Errors.InvalidGateway();
        }
        _;
    }

    modifier onlyHubChain() {
        if (spokeChainId != hubChainId) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyERC20Supply(DataTypes.Asset assetType, address assetToken) {
        if (assetType != DataTypes.Asset.ERC && assetType != DataTypes.Asset.USDC) {
            revert Errors.AssetTransferFailed();
        }
        if (!allowedTokens[assetToken]) {
            revert Errors.InvalidArguments();
        }
        _;
    }

    modifier onlyValidArgs(address user, uint256 amount) {
        if (user == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        if (amount == 0) {
            revert Errors.InvalidArguments();
        }
        _;
    }

    modifier meetsFirstMintDeposit(uint256 depositAmount) {
        if (depositAmount <= MIN_DEPOSIT) {
            revert Errors.InvalidArguments();
        }
        _;
    }
}
