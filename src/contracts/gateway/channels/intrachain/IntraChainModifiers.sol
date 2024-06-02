// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IntraChainStorage} from "./IntraChainStorage.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract IntraChainModifiers is IntraChainStorage {
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

    modifier onlyIntraChainCalls(uint16 sourceChainId, uint16 targetChainId) {
        if (sourceChainId != targetChainId) {
            revert Errors.NotIntraChainCall();
        }
        _;
    }
}
