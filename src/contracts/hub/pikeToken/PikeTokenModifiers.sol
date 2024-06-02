// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PikeTokenStorage} from "./PikeTokenStorage.sol";
import {Operations} from "../../libraries/Operations.sol";
import {DataTypes} from "../../types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract PikeTokenModifiers is PikeTokenStorage {
    modifier onlyActiveChain() {
        if (!isActive) revert Errors.SpokeNotActive();
        _;
    }

    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Errors.InvalidGateway();
        _;
    }

    modifier onlyMintAuthority() {
        if (msg.sender != address(hub)) revert Errors.CallerNotAuthorized();
        _;
    }

    modifier onlyValidAddress(address account) {
        if (account == address(0)) revert Errors.ZeroAddressNotValid();
        _;
    }

    modifier onlyRiskEngine() {
        if (msg.sender != address(riskEngine)) revert Errors.CallerNotAuthorized();
        _;
    }

    modifier normalizeDeposits(DataTypes.HubDeposit memory a) {
        a.amountDeposited = Operations.normalize(a.assetType, a.amountDeposited);
        _;
        a.amountDeposited = Operations.denormalize(a.assetType, a.amountDeposited);
    }

    modifier normalizeRepayments(DataTypes.HubLiquidate memory a) {
        a.repayAmount = Operations.normalize(a.assetType, a.repayAmount);
        _;
        a.repayAmount = Operations.denormalize(a.assetType, a.repayAmount);
    }
}
