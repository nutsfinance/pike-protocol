// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IHub} from "@hub/interfaces/IHub.sol";

contract InterestRateModelStorage {
    IHub internal hub;
    address internal admin;
    uint256 public constant DECIMALS = 1e18;
    uint256 public constant ONE = 1e18;

    uint256 public constant OPTIMAL_UTILIZATION = 80e16; // 80%

    uint256 public constant BASE_VARIABLE = 1e16;
    uint256 public constant VARIABLE_SLOPE1 = 1e15; // 0.1%
    uint256 public constant VARIABLE_SLOPE2 = 3e15; // 0.3%

    uint256 public constant BASE_STABLE = 2e16; // 2%
    uint256 public constant STABLE_SLOPE1 = 1e15; // 0.1%
    uint256 public constant STABLE_SLOPE2 = 3e15; // 0.3%

    uint256 public constant RESERVE_FACTOR = 10e16; // 10%

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
