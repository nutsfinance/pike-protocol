// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IChannel} from "../interfaces/IChannel.sol";
import {IntraChainModifiers} from "./IntraChainModifiers.sol";
import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {Errors} from "@utils/Errors.sol";

contract IntraChainChannel is
    IChannel,
    IntraChainModifiers,
    Initializable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint16 chain) public initializer {
        __UUPSUpgradeable_init();
        chainId = chain;
        admin = msg.sender;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setGatewayAddress(address _gatewayLocal) public onlyOwner {
        if (_gatewayLocal == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        gatewayLocal = IGateway(_gatewayLocal);
    }

    function pike_send(
        uint16 targetChainId,
        bytes memory payload,
        uint256 // forwardCost
    )
        public
        payable
        onlyIntraChainCalls(chainId, targetChainId)
        onlyGateway
    {
        gatewayLocal.pike_receive{value: msg.value}(
            payload, targetChainId, bytes32(uint256(uint160(address(this))))
        );
    }
}
