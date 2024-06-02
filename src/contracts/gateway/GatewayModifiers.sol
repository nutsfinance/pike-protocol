// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./GatewayStorage.sol";
import "@utils/Errors.sol";

abstract contract GatewayModifiers is GatewayStorage {
    event IncomingMessage(address, bool);

    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyAuthorizedChannels() {
        if (authorizedChannels[msg.sender] != true) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }
}
