// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {RiskEngineStorage} from "./RiskEngineStorage.sol";

abstract contract RiskEngineMath is RiskEngineStorage {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b / DECIMALS;
    }

    function mul_add(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return a * b / DECIMALS + c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a * DECIMALS / b;
    }
}
