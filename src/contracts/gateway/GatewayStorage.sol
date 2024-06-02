// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";
import {IChannel} from "@gateway/channels/interfaces/IChannel.sol";
import {IHubMessageHandler} from "@hub/interfaces/IHubMessageHandler.sol";
import {ISpoke} from "@spoke/interfaces/ISpoke.sol";
import {DataTypes} from "@types/DataTypes.sol";

abstract contract GatewayStorage {
    uint16 public chainId;
    address public admin;
    IHubMessageHandler public hub;
    ISpoke public spoke;

    mapping(DataTypes.Transport => IChannel) public channels;
    mapping(address => bool) public authorizedChannels;
    mapping(bytes32 => DataTypes.Message) public messages;
    mapping(address => DataTypes.Asset) public assetTypes;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
