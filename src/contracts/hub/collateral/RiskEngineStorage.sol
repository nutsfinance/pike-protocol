// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IHub} from "@hub/interfaces/IHub.sol";
import {IRiskEngine} from "./interfaces/IRiskEngine.sol";
import {PikePriceOracle} from "@hub/oracle/PikePriceOracle.sol";

abstract contract RiskEngineStorage {
    address internal admin;
    IHub internal hub;
    PikePriceOracle internal pikeOracle;

    mapping(uint16 => mapping(address => IRiskEngine)) internal riskModels;

    uint256 internal ltvRatioDecimals;
    uint256 internal constant DECIMALS = 1e18;

    /**
     * @dev System-wide risk parameters
     *
     * | State variable         | Value     | Percent |
     * |------------------------|-----------|---------|
     * | maxLTV                 | 0.75e18   |   75%   |
     * | liquidationThreshold   | 0.80e18   |   80%   |
     * | liquidationDiscount    | 0.1e18    |   10%   |
     * | liquidationPenalty     | 0.05e18   |   5%    |
     * | protocolSeizeShare     | 0.05e18   |   5%    |
     * | reserveFactor set to 0 | 0.2e18    |   20%   |
     * | closeFactor            | 0.7e18    |   70%   |
     */
    mapping(uint16 => mapping(address => uint256)) public maxLTVs;
    mapping(uint16 => mapping(address => uint256)) public liquidationThresholds;
    mapping(uint16 => mapping(address => uint256)) public liquidationDiscounts;
    mapping(uint16 => mapping(address => uint256)) public liquidationPenalties;
    mapping(uint16 => mapping(address => uint256)) public protocolSeizeShares;
    mapping(uint16 => mapping(address => uint256)) public reserveFactors;
    mapping(uint16 => mapping(address => uint256)) public closeFactors;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
