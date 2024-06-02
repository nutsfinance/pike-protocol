//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {HubStorage} from "./HubStorage.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract HubModifiers is HubStorage {
    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyAuthorizedGateway() {
        if (msg.sender != address(intraGateway) && msg.sender != address(gateway)) {
            revert Errors.InvalidGateway();
        }
        _;
    }

    modifier onlyAuthorizedChannels(bytes32 channel) {
        if (!authorizedContracts[address(uint160(uint256(channel)))] == true) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyValidChains(uint16 chainId, address token) {
        if (markets[chainId][token].isListed != true) {
            revert Errors.SpokeNotFound();
        }
        _;
    }
}
