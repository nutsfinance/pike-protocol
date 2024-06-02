// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IWormholeRelayer} from "./interfaces/IWormholeRelayer.sol";
import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {IChannel} from "../interfaces/IChannel.sol";
import {IHubMessageHandler} from "@hub/interfaces/IHubMessageHandler.sol";

abstract contract WormholeStorage {
    uint16 internal chainId;
    uint16 internal hubChainId; // 10_160;
    address internal admin;
    IGateway internal gatewayLocal;
    IGateway internal gatewayHub;
    IChannel internal whChannelHub;
    IHubMessageHandler internal hubState;
    IWormholeRelayer public wormholeRelayer;

    mapping(bytes32 => bool) internal deliveryHashes;
    mapping(uint16 => address) internal pikes;

    uint256 public gasLimit;
    uint256 public gasLimitForwards;

    enum Route {
        NULL,
        DEPOSIT, // 1
        DEPOSIT_FORWARD, // 2
        BORROW, // 3
        BORROW_FORWARD, // 4
        BORROW_USDC_FORWARD, // 5
        REPAY, // 6
        REPAY_FORWARD, // 7
        WITHDRAW, // 8
        WITHDRAW_FORWARD, // 9
        LIQUIDATION,
        LIQUIDATION_FORWARD
    }

    struct SendHubArgs {
        uint16 targetChainId;
        bytes payload;
        uint256 forwardCost;
    }

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
