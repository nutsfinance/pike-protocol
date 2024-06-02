// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPikeOracle {
    function getAssetPrice(
        uint16 chainId,
        address tokenAddress
    )
        external
        returns (uint256 price, uint256 decimals);

    event PrimaryFeedUpdated(uint16 chainId, address asset, address feed);
}
