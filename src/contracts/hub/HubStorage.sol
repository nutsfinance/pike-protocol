// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import {IInterestRateModel} from "@hub/interest/interfaces/IInterestRateModel.sol";
import {IRiskEngine} from "@hub/collateral/interfaces/IRiskEngine.sol";
import {DataTypes} from "@types/DataTypes.sol";

abstract contract HubStorage {
    /**
     * @dev Pike infrastructure
     */
    IGateway public gateway;
    IGateway public intraGateway;
    IPikeOracle public pikeOracle;
    IInterestRateModel public interestRateModel;
    IRiskEngine public riskEngine;
    address public admin;
    uint16 public hubChainId;

    uint256 internal constant DECIMALS = 1e18;
    uint256 internal constant ONE = 1e18;
    uint256 internal constant GAS_LIMIT = 1e6;
    uint256 internal constant GAS_LIMIT_FORWARDS = 500_000;
    uint256 internal nonce;
    uint256 public initialExchangeRate;

    mapping(uint16 => mapping(address => DataTypes.Market)) public markets;
    mapping(uint16 => mapping(address => address)) public pikeTokens;

    /**
     * @notice Wormhole-related service variables
     * @dev chains for loop convenience array of chainIds
     */
    uint16[] public chains;
    address[] public tokens;
    mapping(uint16 => address[]) public chainTokens;
    mapping(address => bool) internal authorizedContracts;
    mapping(uint16 => address) internal authorizedChannels;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
