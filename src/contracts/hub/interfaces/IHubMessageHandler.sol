// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

interface IHubMessageHandler {
    function processDeposit(
        DataTypes.HubDeposit memory args,
        bytes32 sourceAddress
    )
        external
        payable;

    function processBorrow(
        DataTypes.HubBorrow memory args,
        bytes32 sourceAddress
    )
        external
        payable;

    function processRepay(
        DataTypes.HubRepay memory args,
        bytes32 sourceAddress
    )
        external
        payable;

    function processWithdrawal(
        DataTypes.HubWithdrawal memory args,
        bytes32 sourceAddress
    )
        external
        payable;

    function processLiquidation(
        DataTypes.HubLiquidate memory args,
        bytes32 sourceAddress
    )
        external
        payable;
}
