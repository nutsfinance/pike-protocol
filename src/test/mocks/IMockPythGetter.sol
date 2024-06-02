// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PythStructs} from "@pyth-network/PythStructs.sol";

interface IPikeOracleGetter {
    event AssetFeedUpdated(address indexed asset, bytes32 indexed feed);

    function getAssetPrice(
        /// @dev priceId is set in constructor
        address getter
    )
        external
        view
        returns (int64, int32);

    function getPythFee(bytes[] memory data) external view returns (uint256 fee);
}
