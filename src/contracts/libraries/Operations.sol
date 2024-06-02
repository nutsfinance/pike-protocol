// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

library Operations {
    function normalize(
        DataTypes.Asset assetType,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        if (assetType == DataTypes.Asset.USDC) {
            return amount * (10 ** 12);
        } else {
            return amount;
        }
    }

    function denormalize(
        DataTypes.Asset assetType,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        if (assetType == DataTypes.Asset.USDC) {
            return amount / (10 ** 12);
        } else {
            return amount;
        }
    }

    function getTransport(
        uint16 hubChainId,
        uint16 targetChainId
    )
        internal
        pure
        returns (DataTypes.Transport channel)
    {
        if (hubChainId == targetChainId) channel = DataTypes.Transport.INTRACHAIN;
        else channel = DataTypes.Transport.WORMHOLE;
    }
}
