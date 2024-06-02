// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {IRiskEngine} from "@hub/collateral/interfaces/IRiskEngine.sol";
import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import {IHub} from "@hub/interfaces/IHub.sol";
import {DataTypes} from "@types/DataTypes.sol";

abstract contract PikeTokenStorage {
    uint256 internal spokeChainId;
    IHub public hub;
    IRiskEngine public riskEngine;
    IPikeOracle public pikeOracle;
    bool public isActive;

    uint16 public chainId;
    address public token;
    uint256 internal constant DECIMALS = 1e18;

    IGateway internal gateway;

    /**
     * @notice Markets-related storage
     * @dev totalBorrows: Total amount of assets borrowed per chain
     * @dev totalLiquidity: Total liquidity available per chain
     * @dev totalReserves: Total reserves held by the protocol per chain
     * @dev lastUpdatedTimestamps: Last time the interest rates were updated per chain
     */
    uint256 public totalBorrowIndex;
    uint256 public totalBorrows;
    uint256 public totalLiquidity; // available cash
    // uint256 internal totalSupply; // total supply of PikeTokens
    // mapping(address => uint256) internal accountTokens;
    uint256 public totalReserves;
    uint256 public lastUpdatedTimestamp;

    /**
     * @notice Users-related storage
     * @dev userDeposits maps chainId => token => user => (deposit, interest)
     * @dev userBorrows maps chainId => token => user => (principal, interest)
     */
    mapping(address => uint256) public userDeposits;
    mapping(address => DataTypes.BorrowSnapshot) public userBorrows;

    /**
     * @notice MIN_LIQUIDITY is the min amount of liquidity tokens minted to address(0)
     * when initializing the pool to prevent precision loss exploits
     * @notice MIN_DEPOSIT is the minimum amount of the underlying asset
     * that must be deposited by the first user
     * @dev MIN_DEPOSIT = mul(MIN_LIQUIDITY, INITIAL_EXCHANGE_RATE) = 1000 * 0.02
     */
    uint256 internal constant MIN_LIQUIDITY = 1000;
    address internal constant PLACEHOLDER_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
