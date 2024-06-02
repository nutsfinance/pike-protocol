// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";
import {PikeSetup} from "../setup/PikeSetup.sol";

import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";

import {SlimRelayer} from "../mocks/SlimRelayer.sol";
import {IWormholeRelayer} from
    "@gateway/channels/wormhole/interfaces/IWormholeRelayer.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {Spoke} from "@spoke/Spoke.sol";
import {Hub} from "@hub/Hub.sol";
import {Gateway} from "@gateway/Gateway.sol";
import {InterestRateModel} from "@hub/interest/InterestRateModel.sol";
import {WormholeChannel} from "@gateway/channels/wormhole/WormholeChannel.sol";
import {PikeOracle} from "../mocks/MockPikeOracle.sol";
import {IPyth} from "@pyth-network/IPyth.sol";
import {MockPyth} from "@pyth-network/MockPyth.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract PikeGeneralE2E is PikeSetup, DSTestFull {
    function test_DepositAction() public {
        assertEq(spokeEthereum.isActive(), true);
        vm.deal(alice, 10_000 ether);

        vm.prank(alice);
        (uint256 cost,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeEthereum.supply{value: 1 ether + cost}(1 ether, cost);
        slimRelayer.performRecordedDeliveries();

        assertGt(IERC20(pikeTokenEth).balanceOf(alice), 0, "Zero balance");
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(
            ethChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidity, 1 ether);
    }

    function test_BorrowAction() public {
        assertEq(spokeEthereum.isActive(), true);
        vm.deal(alice, 10_000 ether);
        vm.deal(address(pikeTokenEth), 10_000 ether);
        vm.deal(address(pikeTokenOpt), 10_000 ether);

        vm.prank(alice);
        (uint256 cost,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeEthereum.supply{value: 100 ether + cost}(100 ether, cost);
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidityA) = hub.getTotalLiquidity(
            ethChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidityA, 100 ether);

        // Borrow OP from Ethereum
        vm.warp(1 hours);
        vm.prank(alice);
        (uint256 cost2,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeHub.borrow{value: cost2}(
            // DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            10 ether,
            false,
            ethChainId,
            alice,
            ethChainId,
            cost2
        );
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidityB) = hub.getTotalLiquidity(
            ethChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidityB, 90 ether);
    }

    function test_DepositAndBorrowAction() public {
        assertEq(spokeEthereum.isActive(), true);
        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);

        (uint256 cost,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeEthereum.supply{value: 1 ether + cost}(1 ether, cost);
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidityA) = hub.getTotalLiquidity(
            ethChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidityA, 1 ether);

        vm.warp(1 hours);
        (uint256 cost2,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(bob);
        spokeOptimism.supply{value: 1 ether + cost2}(1 ether, cost2);
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidityB) = hub.getTotalLiquidity(
            optChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidityB, 1 ether);

        vm.warp(2 hours);
        (uint256 cost3,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeHub.borrow{value: cost3}(
            DataTypes.Transport.WORMHOLE,
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            0.5 ether,
            false,
            optChainId,
            alice,
            optChainId,
            cost3
        );
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidityC) = hub.getTotalLiquidity(
            ethChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        (,, uint256 totalLiquidityD) = hub.getTotalLiquidity(
            optChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidityC, 1 ether);
        assertEq(totalLiquidityD, 0.5 ether);
    }

    function test_RepayAction() public {
        assertEq(spokeEthereum.isActive(), true);
        vm.deal(alice, 10_000 ether);

        (uint256 cost,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeOptimism.supply{value: 50 ether + cost}(50 ether, cost);
        slimRelayer.performRecordedDeliveries();

        /// @dev Perform borrow
        vm.warp(1 hours);
        (uint256 cost2,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeHub.borrow{value: cost2}(
            DataTypes.Transport.WORMHOLE,
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            10 ether,
            false,
            optChainId,
            alice,
            optChainId,
            cost2
        );
        slimRelayer.performRecordedDeliveries();

        /// @dev Perform repay on correct chain
        vm.warp(2 hours);
        (uint256 cost3,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeOptimism.repay{value: 1 ether + cost3}(1 ether, cost3);
        slimRelayer.performRecordedDeliveries();
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(
            optChainId, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        );
        assertEq(totalLiquidity, 41 ether);
    }

    function test_WithdrawalAction() public {
        assertEq(spokeEthereum.isActive(), true);
        vm.deal(alice, 10_000 ether);

        (uint256 cost,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeOptimism.supply{value: 100 ether + cost}(100 ether, cost);
        slimRelayer.performRecordedDeliveries();

        vm.warp(1 hours);
        (uint256 cost2,) = slimRelayer.quoteEVMDeliveryPrice(ethChainId, 0, 500_000);
        vm.prank(alice);
        spokeHub.withdraw{value: cost2}(
            DataTypes.Transport.WORMHOLE,
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            1 ether,
            false,
            optChainId,
            alice,
            ethChainId,
            cost2
        );
        slimRelayer.performRecordedDeliveries();
    }
}
