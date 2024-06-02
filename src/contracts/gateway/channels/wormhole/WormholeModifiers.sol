// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {WormholeStorage} from "./WormholeStorage.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract WormholeModifiers is WormholeStorage {
    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyGateway() {
        if (msg.sender != address(gatewayLocal)) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyRelayerContract() {
        if (msg.sender != address(wormholeRelayer)) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyUniqueDeliveryHashes(bytes32 deliveryHash) {
        if (deliveryHashes[deliveryHash] != false) {
            revert Errors.MessageHashDuplicate();
        }
        deliveryHashes[deliveryHash] = true;
        _;
    }

    function setTrustedPikes(uint16 remoteChainId, address remotePike) public onlyOwner {
        pikes[remoteChainId] = remotePike;
    }

    function setGasLimits(
        uint256 _gasLimit,
        uint256 _gasLimitForwards
    )
        external
        onlyOwner
    {
        gasLimit = _gasLimit;
        gasLimitForwards = _gasLimitForwards;
    }
}
