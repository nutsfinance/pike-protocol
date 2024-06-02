// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPikeOracleGetter {
    event AssetFeedUpdated(address indexed asset, bytes32 indexed feed);

    function getAssetPrice(
        /// @dev priceId is set in constructor
        uint16 chainId,
        address tokenAddress
    )
        external
        view
        returns (uint256, uint8);
}
