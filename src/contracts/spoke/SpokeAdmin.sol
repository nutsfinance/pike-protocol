// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {SpokeStorage} from "@spoke/SpokeStorage.sol";
import {SpokeModifiers} from "@spoke/SpokeModifiers.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract SpokeAdmin is SpokeStorage, SpokeModifiers, PausableUpgradeable {
    function setAllowedToken(address token, bool allowed) external onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroValueNotValid();
        }
        allowedTokens[token] = allowed;
    }

    function setNativeAssetAddress(address token) external onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroValueNotValid();
        }
        nativeAsset = token;
    }

    function setUsdcTokenAddress(address token) external onlyOwner {
        if (token == address(0)) {
            revert Errors.ZeroValueNotValid();
        }
        usdcTokenAddress = token;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setAssetType(address token, DataTypes.Asset assetType) external onlyOwner {
        if (token == address(0) || assetType == DataTypes.Asset.NULL) {
            revert Errors.ZeroValueNotValid();
        }
        assetTypes[token] = assetType;
    }
}
