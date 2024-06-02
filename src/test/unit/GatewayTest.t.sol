// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {Spoke} from "@spoke/Spoke.sol";
import {Hub} from "@hub/Hub.sol";
import {Gateway} from "@gateway/Gateway.sol";
import {InterestRateModel} from "@hub/interest/InterestRateModel.sol";
import {IChannel} from "@gateway/channels/interfaces/IChannel.sol";
import {PikeOracle} from "../mocks/MockPikeOracle.sol";
import {MockHub} from "../mocks/MockHub.sol";
import {MockSpoke} from "../mocks/MockSpoke.sol";
import {IPyth} from "@pyth-network/IPyth.sol";
import {MockPyth} from "@pyth-network/MockPyth.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract GatewayUnitTest is DSTestFull {
    Gateway gateway;
    MockHub mockHub;
    MockSpoke mockSpoke;
    uint16 immutable chainId = 30;
    address immutable alice = address(12_345_678);
    address immutable bob = address(87_654_321);

    function setUp() public {
        mockHub = new MockHub();
        mockSpoke = new MockSpoke();

        address gatewayImplementation = address(new Gateway());
        bytes memory gatewayData =
            abi.encodeCall(Gateway.initialize, (chainId, address(mockHub)));
        address gatewayProxy =
            address(new ERC1967Proxy(gatewayImplementation, gatewayData));
        gateway = Gateway(gatewayProxy);
        gateway.setLocalSpoke(address(mockSpoke));
    }

    function test_ChangeAdmin() public {
        gateway.changeAdmin(alice);
        assertEq(gateway.admin(), alice);
    }

    function test_ChangeAdmin_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        gateway.changeAdmin(bob);
    }

    function test_SetLocalSpoke() public {
        gateway.setLocalSpoke(alice);
        assertEq(address(gateway.spoke()), alice);
    }

    function test_SetLocalSpoke_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        gateway.setLocalSpoke(alice);
    }

    function test_ChangeChannelAuthorizedStatus() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        assertEq(gateway.authorizedChannels(alice), true);
    }

    function test_ChangeChannelAuthorizedStatus_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        gateway.changeChannelAuthorizedStatus(alice, true);
    }

    function test_AddChannel() public {
        gateway.addChannel(DataTypes.Transport.WORMHOLE, IChannel(alice));
        assertEq(address(gateway.channels(DataTypes.Transport.WORMHOLE)), alice);
    }

    function test_AddChannel_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        gateway.addChannel(DataTypes.Transport.WORMHOLE, IChannel(alice));
    }

    function test_ProcessDepositActions_HubDeposit() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.HubDeposit memory hubDeposit = DataTypes.HubDeposit({
            action: DataTypes.Action.HUB_DEPOSIT,
            assetType: DataTypes.Asset.EVM,
            nonce: 123,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            assetToken: address(3),
            amountDeposited: 4,
            forwardCost: 6,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(hubDeposit);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.HubDeposit memory received = mockHub.getStoredDeposit();
        assertEq(abi.encode(hubDeposit), abi.encode(received));
    }

    function test_ProcessDepositActions_SupplyDeclined() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeDecline memory declined = DataTypes.SpokeDecline({
            action: DataTypes.Action.SPOKE_DEPOSIT_DECLINE,
            user: address(1),
            amount: 4,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(declined);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeDecline memory received = mockSpoke.getStoredSupplyDeclined();
        assertEq(abi.encode(declined), abi.encode(received));
    }

    function test_ProcessBorrowActions_HubBorrow() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.HubBorrow memory hubBorrow = DataTypes.HubBorrow({
            action: DataTypes.Action.HUB_BORROW,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            assetToken: address(2),
            borrowAmount: 3,
            usdcMintRequired: true,
            targetAddress: address(4),
            forwardCost: 5,
            sourceChainId: 6,
            targetChainId: 7,
            cctpTargetChainId: 8
        });
        bytes memory data = abi.encode(hubBorrow);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.HubBorrow memory received = mockHub.getStoredBorrow();
        assertEq(abi.encode(hubBorrow), abi.encode(received));
    }

    function test_ProcessBorrowActions_BorrowForward() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeBorrowForward memory payload = DataTypes.SpokeBorrowForward({
            action: DataTypes.Action.SPOKE_BORROW_FORWARD,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            assetToken: address(2),
            borrowAmount: 3,
            usdcMintRequired: true,
            targetAddress: address(4),
            sourceChainId: 6,
            targetChainId: 7,
            cctpTargetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeBorrowForward memory received = mockSpoke.getStoredBorrowForward();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessBorrowActions_BorrowDeclined() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeDecline memory payload = DataTypes.SpokeDecline({
            action: DataTypes.Action.SPOKE_BORROW_DECLINE,
            user: address(1),
            amount: 4,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeDecline memory received = mockSpoke.getStoredBorrowDeclined();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessRepayActions_HubRepay() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.HubRepay memory payload = DataTypes.HubRepay({
            action: DataTypes.Action.HUB_REPAY,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            sourceToken: address(2),
            targetToken: address(3),
            fullRepayment: true,
            repaidAmount: 4,
            forwardCost: 6,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.HubRepay memory received = mockHub.getStoredRepay();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessRepayActions_RepayDeclined() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeDecline memory payload = DataTypes.SpokeDecline({
            action: DataTypes.Action.SPOKE_REPAY_DECLINE,
            user: address(1),
            amount: 4,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeDecline memory received = mockSpoke.getStoredRepayDeclined();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessWithdrawActions_HubWithdrawal() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.HubWithdrawal memory payload = DataTypes.HubWithdrawal({
            action: DataTypes.Action.HUB_WITHDRAWAL,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            assetToken: address(2),
            withdrawAmount: 3,
            usdcMintRequired: true,
            targetAddress: address(4),
            fullWithdrawal: true,
            forwardCost: 5,
            sourceChainId: 6,
            targetChainId: 7,
            cctpTargetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.HubWithdrawal memory received = mockHub.getStoredWithdrawl();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessWithdrawActions_WithdrawlForward() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeWithdrawalForward memory payload = DataTypes.SpokeWithdrawalForward({
            action: DataTypes.Action.SPOKE_WITHDRAWAL_FORWARD,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            assetToken: address(2),
            withdrawAmount: 3,
            usdcMintRequired: true,
            sourceChainId: 6,
            targetChainId: 7,
            cctpTargetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeWithdrawalForward memory received =
            mockSpoke.getStoredWithdrawlForward();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessWithdrawActions_WithdrawlDeclined() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeDecline memory payload = DataTypes.SpokeDecline({
            action: DataTypes.Action.SPOKE_WITHDRAWAL_DECLINE,
            user: address(1),
            amount: 4,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeDecline memory received = mockSpoke.getStoredWithdrawlDeclined();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessLiquidations_HubLiquidate() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.HubLiquidate memory payload = DataTypes.HubLiquidate({
            action: DataTypes.Action.HUB_LIQUIDATE,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            sourceToken: address(2),
            targetToken: address(3),
            liquidator: address(4),
            repayAmount: 5,
            usdcMintRequired: true,
            forwardCost: 6,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.HubLiquidate memory received = mockHub.getStoredLiquidate();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessLiquidations_LiquidateForward() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeLiquidateForward memory payload = DataTypes.SpokeLiquidateForward({
            action: DataTypes.Action.SPOKE_LIQUIDATE_FORWARD,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: address(1),
            sourceToken: address(2),
            targetToken: address(3),
            liquidator: address(4),
            totalDiscounted: 5,
            seizedShare: 6,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeLiquidateForward memory received =
            mockSpoke.getStoredLiquidateForward();
        assertEq(abi.encode(payload), abi.encode(received));
    }

    function test_ProcessLiquidations_LiquidatelDeclined() public {
        gateway.changeChannelAuthorizedStatus(alice, true);
        DataTypes.SpokeDecline memory payload = DataTypes.SpokeDecline({
            action: DataTypes.Action.SPOKE_LIQUIDATE_DECLINE,
            user: address(1),
            amount: 4,
            sourceChainId: 7,
            targetChainId: 8
        });
        bytes memory data = abi.encode(payload);
        gateway.changeChannelAuthorizedStatus(alice, true);
        vm.prank(alice);
        gateway.pike_receive(data, 7, bytes32(uint256(uint160(alice))));
        DataTypes.SpokeDecline memory received = mockSpoke.getStoredLiquidateDeclined();
        assertEq(abi.encode(payload), abi.encode(received));
    }
}
