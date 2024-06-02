// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PythStructs} from "@pyth-network/PythStructs.sol";

interface IPikeOracle {
    function getAssetPrice(
        uint16 chainId,
        address tokenAddress
    )
        external
        view
        returns (uint256 price, uint256 decimals);

    event PrimaryFeedUpdated(uint16 chainId, address asset, address feed);
}
