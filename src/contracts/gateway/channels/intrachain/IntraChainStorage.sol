// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGateway} from "@gateway/interfaces/IGateway.sol";

abstract contract IntraChainStorage {
    uint16 public chainId;
    address internal admin;
    IGateway public gatewayLocal;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;
}
