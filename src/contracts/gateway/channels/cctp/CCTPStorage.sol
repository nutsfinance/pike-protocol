// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {IMessageTransmitter} from "./interfaces/IMessageTransmitter.sol";
import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";

abstract contract CCTPStorage {
    event OutcomingPikeMessage(
        uint16 cctpTargetChainId, uint32 circleDomain, address user, uint256 borrowAmount
    );

    uint16 internal chainId;
    address internal admin;
    IERC20 internal USDC;
    ITokenMessenger internal tokenMessenger;
    IMessageTransmitter messageTransmitter;
    address public localSpoke;

    mapping(uint16 => uint32) public circleDestinationChains;
    mapping(uint16 => address) public usdc;
    mapping(uint16 => bytes32) public pikeCctpInstances;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
