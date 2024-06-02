// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

contract MockTransferToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        return true;
    }
}
