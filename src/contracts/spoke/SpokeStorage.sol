// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGateway} from "../gateway/interfaces/IGateway.sol";
import {DataTypes} from "@types/DataTypes.sol";

abstract contract SpokeStorage {
    bool public isActive;
    uint16 public hubChainId;
    uint16 public spokeChainId;
    uint256 constant GAS_LIMIT = 1e6;

    address public admin;
    IGateway public gateway;
    IGateway public hubGateway;
    address public endpoint;
    address payable public cctpChannel;

    mapping(bytes32 => bool) internal deliveryHashes;
    uint256 public chainProtocolReserves;

    // ERC20 tokens allowed for circulating
    mapping(address => bool) public allowedTokens;
    address public usdcTokenAddress;
    address public nativeAsset;
    uint256 internal nonce;

    mapping(address => DataTypes.Asset) internal assetTypes;

    /**
     * @notice MIN_DEPOSIT is the minimum amount of the underlying asset
     * that must be deposited by the first user
     * @dev MIN_DEPOSIT = mul(MIN_LIQUIDITY, INITIAL_EXCHANGE_RATE) = 1000 * 0.02
     */
    uint256 internal constant MIN_DEPOSIT = 20;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
