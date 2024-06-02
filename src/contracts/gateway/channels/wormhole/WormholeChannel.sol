// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IWormholeReceiver} from "./interfaces/IWormholeReceiver.sol";
import {IWormholeRelayer, VaaKey} from "./interfaces/IWormholeRelayer.sol";
import {WormholeModifiers} from "./WormholeModifiers.sol";
import {WormholeStorage} from "./WormholeStorage.sol";
import {IGateway} from "../../interfaces/IGateway.sol";
import {IChannel} from "../interfaces/IChannel.sol";
import {Errors} from "@utils/Errors.sol";

contract WormholeChannel is
    IWormholeReceiver,
    IChannel,
    WormholeStorage,
    WormholeModifiers,
    Initializable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint16 chain,
        address _wormholeRelayer,
        address _gatewayLocal,
        address _gatewayHub,
        address _whChannelHub
    )
        public
        initializer
    {
        __UUPSUpgradeable_init();
        chainId = chain;
        admin = address(msg.sender);
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        gatewayLocal = IGateway(_gatewayLocal);
        gatewayHub = IGateway(_gatewayHub);
        whChannelHub = IChannel(_whChannelHub);
        hubChainId = 30;
        gasLimit = 500_000;
        gasLimitForwards = 500_000;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pike_send(
        uint16 targetChainId,
        bytes memory payload,
        uint256 forwardCost
    )
        public
        payable
        onlyGateway
    {
        if (targetChainId == hubChainId) {
            sendToHub(
                SendHubArgs({
                    targetChainId: targetChainId,
                    payload: payload,
                    forwardCost: forwardCost
                })
            );
        } else {
            sendFromHub(
                SendHubArgs({
                    targetChainId: targetChainId,
                    payload: payload,
                    forwardCost: forwardCost
                })
            );
        }
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    )
        public
        payable
        onlyRelayerContract
        onlyUniqueDeliveryHashes(deliveryHash)
    {
        gatewayLocal.pike_receive{value: msg.value}(payload, sourceChain, sourceAddress);
    }

    function sendToHub(SendHubArgs memory a) private {
        (uint256 forwardCost,) =
            wormholeRelayer.quoteEVMDeliveryPrice(a.targetChainId, 0, gasLimitForwards);
        if (msg.value != forwardCost || a.forwardCost != msg.value) {
            revert Errors.InvalidWormholeFees();
        }
        wormholeRelayer.sendToEvm{value: a.forwardCost}(
            a.targetChainId,
            pikes[a.targetChainId],
            a.payload,
            0,
            0,
            gasLimit,
            chainId,
            address(this),
            wormholeRelayer.getDefaultDeliveryProvider(),
            new VaaKey[](0),
            200
        );
    }

    function sendFromHub(SendHubArgs memory a) private {
        (uint256 forwardCost,) =
            wormholeRelayer.quoteEVMDeliveryPrice(a.targetChainId, 0, gasLimitForwards);
        if (msg.value != forwardCost || a.forwardCost != msg.value) {
            revert Errors.InvalidWormholeFees();
        }
        wormholeRelayer.sendToEvm{value: forwardCost}(
            a.targetChainId,
            pikes[a.targetChainId],
            a.payload,
            0,
            0,
            gasLimitForwards,
            chainId,
            address(this),
            wormholeRelayer.getDefaultDeliveryProvider(),
            new VaaKey[](0),
            200
        );
    }

    function estimateForwardCost(uint16 targetChainId)
        public
        view
        returns (uint256 forwardCost)
    {
        (forwardCost,) =
            wormholeRelayer.quoteEVMDeliveryPrice(targetChainId, 0, gasLimitForwards);
    }

    function estimateRoundTripCost(
        uint16 targetChainId,
        uint256 forwardCost
    )
        public
        view
        returns (uint256 deliveryCost)
    {
        (deliveryCost,) =
            wormholeRelayer.quoteEVMDeliveryPrice(targetChainId, forwardCost, gasLimit);
    }

    // Forwarded gas for chained calls
    receive() external payable {}
}
