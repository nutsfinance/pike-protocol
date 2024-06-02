// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {GatewayStorage} from "./GatewayStorage.sol";
import {GatewayModifiers} from "./GatewayModifiers.sol";
import {IGateway} from "./interfaces/IGateway.sol";
import {DataTypes} from "@types/DataTypes.sol";

abstract contract GatewayInternals is IGateway, GatewayStorage, GatewayModifiers {
    function processDepositActions(
        uint8 _selector,
        bytes memory data,
        bytes32 sourceAddress
    )
        internal
    {
        DataTypes.Action selector = DataTypes.Action(_selector);

        if (selector == DataTypes.Action.HUB_DEPOSIT) {
            DataTypes.HubDeposit memory d = abi.decode(data, (DataTypes.HubDeposit));
            hub.processDeposit{value: msg.value}(d, sourceAddress);
        } else if (selector == DataTypes.Action.SPOKE_DEPOSIT_DECLINE) {
            spoke.supplyDeclined(abi.decode(data, (DataTypes.SpokeDecline)));
        }
    }

    function processBorrowActions(
        uint8 _selector,
        bytes memory data,
        bytes32 sourceAddress
    )
        internal
    {
        DataTypes.Action selector = DataTypes.Action(_selector);

        if (selector == DataTypes.Action.HUB_BORROW) {
            DataTypes.HubBorrow memory d = abi.decode(data, (DataTypes.HubBorrow));
            hub.processBorrow{value: msg.value}(d, sourceAddress);
        } else if (selector == DataTypes.Action.SPOKE_BORROW_FORWARD) {
            DataTypes.SpokeBorrowForward memory d =
                abi.decode(data, (DataTypes.SpokeBorrowForward));
            spoke.borrowApproved(d);
        } else if (selector == DataTypes.Action.SPOKE_BORROW_USDC_FORWARD) {
            DataTypes.SpokeBorrowForward memory d =
                abi.decode(data, (DataTypes.SpokeBorrowForward));
            channels[DataTypes.Transport.CCTP].pike_send(
                d.cctpTargetChainId, data, DataTypes.ZERO_COST
            );
        } else if (selector == DataTypes.Action.SPOKE_BORROW_DECLINE) {
            spoke.borrowDeclined(abi.decode(data, (DataTypes.SpokeDecline)));
        }
    }

    function processRepayActions(
        uint8 _selector,
        bytes memory data,
        bytes32 sourceAddress
    )
        internal
    {
        DataTypes.Action selector = DataTypes.Action(_selector);

        if (selector == DataTypes.Action.HUB_REPAY) {
            DataTypes.HubRepay memory d = abi.decode(data, (DataTypes.HubRepay));
            hub.processRepay{value: msg.value}(d, sourceAddress);
        } else if (selector == DataTypes.Action.SPOKE_REPAY_DECLINE) {
            spoke.repayDeclined(abi.decode(data, (DataTypes.SpokeDecline)));
        }
    }

    function processWithdrawActions(
        uint8 _selector,
        bytes memory data,
        bytes32 sourceAddress
    )
        internal
    {
        DataTypes.Action selector = DataTypes.Action(_selector);

        if (selector == DataTypes.Action.HUB_WITHDRAWAL) {
            DataTypes.HubWithdrawal memory d = abi.decode(data, (DataTypes.HubWithdrawal));
            hub.processWithdrawal{value: msg.value}(d, sourceAddress);
        } else if (selector == DataTypes.Action.SPOKE_WITHDRAWAL_FORWARD) {
            DataTypes.SpokeWithdrawalForward memory d =
                abi.decode(data, (DataTypes.SpokeWithdrawalForward));
            spoke.withdrawalApproved(d);
        } else if (selector == DataTypes.Action.SPOKE_WITHDRAWAL_USDC_FORWARD) {
            DataTypes.SpokeWithdrawalForward memory d =
                abi.decode(data, (DataTypes.SpokeWithdrawalForward));
            channels[DataTypes.Transport.CCTP].pike_send(
                d.cctpTargetChainId, data, DataTypes.ZERO_COST
            );
        } else if (selector == DataTypes.Action.SPOKE_WITHDRAWAL_DECLINE) {
            spoke.withdrawalDeclined(abi.decode(data, (DataTypes.SpokeDecline)));
        }
    }

    function processLiquidations(
        uint8 _selector,
        bytes memory data,
        bytes32 sourceAddress
    )
        internal
    {
        DataTypes.Action selector = DataTypes.Action(_selector);

        if (selector == DataTypes.Action.HUB_LIQUIDATE) {
            DataTypes.HubLiquidate memory d = abi.decode(data, (DataTypes.HubLiquidate));
            hub.processLiquidation{value: msg.value}(d, sourceAddress);
        } else if (selector == DataTypes.Action.SPOKE_LIQUIDATE_FORWARD) {
            DataTypes.SpokeLiquidateForward memory d =
                abi.decode(data, (DataTypes.SpokeLiquidateForward));
            spoke.liquidationApproved(d);
        } else if (selector == DataTypes.Action.SPOKE_LIQUIDATE_DECLINE) {
            spoke.liquidationDeclined(abi.decode(data, (DataTypes.SpokeDecline)));
        }
    }
}
