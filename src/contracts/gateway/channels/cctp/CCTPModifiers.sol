// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {CCTPStorage} from "./CCTPStorage.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract CCTPModifiers is CCTPStorage {
    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != address(localSpoke)) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }
}
