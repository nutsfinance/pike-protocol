// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {RiskEngine} from "@hub/collateral/RiskEngine.sol";
import {PikePriceOracle} from "@hub/oracle/PikePriceOracle.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract RiskEngineUnitTest is DSTestFull {
    PikePriceOracle pikeOracle;
    RiskEngine riskEngine;
    uint16 immutable ethChainId = 30;
    uint16 immutable opChainId = 31;
    address immutable hub = address(127_345_678);
    address immutable ethToken = address(12_345_678);
    address immutable opToken = address(87_654_321);
    address immutable alice = address(444_555_666);

    function setUp() public {
        address riskEngineImplementation = address(new RiskEngine());
        bytes memory riskEngineData =
            abi.encodeCall(RiskEngine.initialize, (address(hub), address(pikeOracle)));
        address riskEngineProxy =
            address(new ERC1967Proxy(riskEngineImplementation, riskEngineData));
        riskEngine = RiskEngine(riskEngineProxy);

        uint16[] memory chainIds = new uint16[](2);
        uint256[][] memory ltvs = new uint256[][](2);
        address[][] memory chainTokens = new address[][](2);
        uint256[][] memory liqThresholds = new uint256[][](2);
        uint256[][] memory liqPenalties = new uint256[][](2);
        uint256[][] memory liqDiscounts = new uint256[][](2);
        uint256[][] memory reserveFactors = new uint256[][](2);
        uint256[][] memory shares = new uint256[][](2);
        uint256[][] memory closeFactors = new uint256[][](2);
        chainIds[0] = ethChainId;
        chainIds[1] = opChainId;
        ltvs[0] = new uint256[](1);
        ltvs[0][0] = 80e16;
        ltvs[1] = new uint256[](1);
        ltvs[1][0] = 75e16;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = ethToken;
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = opToken;
        liqThresholds[0] = new uint256[](1);
        liqThresholds[0][0] = 85e16;
        liqThresholds[1] = new uint256[](1);
        liqThresholds[1][0] = 80e16;
        liqDiscounts[0] = new uint256[](1);
        liqDiscounts[0][0] = 15e16;
        liqDiscounts[1] = new uint256[](1);
        liqDiscounts[1][0] = 10e16;
        liqPenalties[0] = new uint256[](1);
        liqPenalties[0][0] = 10e16;
        liqPenalties[1] = new uint256[](1);
        liqPenalties[1][0] = 5e16;
        reserveFactors[0] = new uint256[](1);
        reserveFactors[0][0] = 25e16;
        reserveFactors[1] = new uint256[](1);
        reserveFactors[1][0] = 20e16;
        shares[0] = new uint256[](1);
        shares[0][0] = 10e16;
        shares[1] = new uint256[](1);
        shares[1][0] = 5e16;
        closeFactors[0] = new uint256[](1);
        closeFactors[0][0] = 75e16;
        closeFactors[1] = new uint256[](1);
        closeFactors[1][0] = 70e16;
        riskEngine.setChainLtvRatios(chainIds, chainTokens, ltvs);
        riskEngine.setLiquidationThresholds(chainIds, chainTokens, liqThresholds);
        riskEngine.setLiquidationDiscounts(chainIds, chainTokens, liqDiscounts);
        riskEngine.setLiquidationPenalties(chainIds, chainTokens, liqPenalties);
        riskEngine.setReserveFactors(chainIds, chainTokens, reserveFactors);
        riskEngine.setSeizeShares(chainIds, chainTokens, shares);
        riskEngine.setCloseFactors(chainIds, chainTokens, closeFactors);
    }

    function test_GetRiskParameterSnaphot_Eth() public {
        (
            uint256 maxLTV,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            uint256 liquidationPenalty,
            uint256 seizeShare,
            uint256 reserveFactor,
            uint256 closeFactor
        ) = riskEngine.getRiskParameterSnaphot(ethChainId, ethToken);
        assertEq(maxLTV, 80e16);
        assertEq(liquidationThreshold, 85e16);
        assertEq(liquidationDiscount, 15e16);
        assertEq(liquidationPenalty, 10e16);
        assertEq(seizeShare, 10e16);
        assertEq(reserveFactor, 25e16);
        assertEq(closeFactor, 75e16);
    }

    function test_GetRiskParameterSnaphot_Op() public {
        (
            uint256 maxLTV,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            uint256 liquidationPenalty,
            uint256 seizeShare,
            uint256 reserveFactor,
            uint256 closeFactor
        ) = riskEngine.getRiskParameterSnaphot(opChainId, opToken);
        assertEq(maxLTV, 75e16);
        assertEq(liquidationThreshold, 80e16);
        assertEq(liquidationDiscount, 10e16);
        assertEq(liquidationPenalty, 5e16);
        assertEq(seizeShare, 5e16);
        assertEq(reserveFactor, 20e16);
        assertEq(closeFactor, 70e16);
    }

    function test_GetMaxLTV() public {
        uint256 valueEth = riskEngine.getMaxLTV(ethChainId, ethToken);
        assertEq(valueEth, 80e16);
        uint256 valueOp = riskEngine.getMaxLTV(opChainId, opToken);
        assertEq(valueOp, 75e16);
    }

    function test_GetLiquidationThreshold() public {
        uint256 valueEth = riskEngine.getLiquidationThreshold(ethChainId, ethToken);
        assertEq(valueEth, 85e16);
        uint256 valueOp = riskEngine.getLiquidationThreshold(opChainId, opToken);
        assertEq(valueOp, 80e16);
    }

    function test_GetLiquidationPenalty() public {
        uint256 valueEth = riskEngine.getLiquidationPenalty(ethChainId, ethToken);
        assertEq(valueEth, 10e16);
        uint256 valueOp = riskEngine.getLiquidationPenalty(opChainId, opToken);
        assertEq(valueOp, 5e16);
    }

    function test_GetLiquidationDiscount() public {
        uint256 valueEth = riskEngine.getLiquidationDiscount(ethChainId, ethToken);
        assertEq(valueEth, 15e16);
        uint256 valueOp = riskEngine.getLiquidationDiscount(opChainId, opToken);
        assertEq(valueOp, 10e16);
    }

    function test_GetReserveFactor() public {
        uint256 valueEth = riskEngine.getReserveFactor(ethChainId, ethToken);
        assertEq(valueEth, 25e16);
        uint256 valueOp = riskEngine.getReserveFactor(opChainId, opToken);
        assertEq(valueOp, 20e16);
    }

    function test_GetSeizeShare() public {
        uint256 valueEth = riskEngine.getSeizeShare(ethChainId, ethToken);
        assertEq(valueEth, 10e16);
        uint256 valueOp = riskEngine.getSeizeShare(opChainId, opToken);
        assertEq(valueOp, 5e16);
    }

    function test_GetCloseFactor() public {
        uint256 valueEth = riskEngine.getCloseFactor(ethChainId, ethToken);
        assertEq(valueEth, 75e16);
        uint256 valueOp = riskEngine.getCloseFactor(opChainId, opToken);
        assertEq(valueOp, 70e16);
    }

    function test_GetTotalSeizeShare() public {
        uint256 valueEth = riskEngine.getTotalSeizeShare(10 ether, ethChainId, ethToken);
        assertEq(valueEth, 9 ether);
        uint256 valueOp = riskEngine.getTotalSeizeShare(10 ether, opChainId, opToken);
        assertEq(valueOp, 9.5 ether);
    }

    function test_SetMaxLTV() public {
        riskEngine.setChainLtvRatio(ethChainId, ethToken, 90e16);
        uint256 valueEth = riskEngine.getMaxLTV(ethChainId, ethToken);
        assertEq(valueEth, 90e16);
    }

    function test_SetLiquidationThreshold() public {
        riskEngine.setLiquidationThreshold(ethChainId, ethToken, 65e16);
        uint256 valueEth = riskEngine.getLiquidationThreshold(ethChainId, ethToken);
        assertEq(valueEth, 65e16);
    }

    function test_SetLiquidationPenalty() public {
        riskEngine.setLiquidationPenalty(ethChainId, ethToken, 5e16);
        uint256 valueEth = riskEngine.getLiquidationPenalty(ethChainId, ethToken);
        assertEq(valueEth, 5e16);
    }

    function test_SetLiquidationDiscount() public {
        riskEngine.setLiquidationDiscount(ethChainId, ethToken, 20e16);
        uint256 valueEth = riskEngine.getLiquidationDiscount(ethChainId, ethToken);
        assertEq(valueEth, 20e16);
    }

    function test_SetReserveFactor() public {
        riskEngine.setReserveFactor(ethChainId, ethToken, 35e16);
        uint256 valueEth = riskEngine.getReserveFactor(ethChainId, ethToken);
        assertEq(valueEth, 35e16);
    }

    function test_SetSeizeShare() public {
        riskEngine.setSeizeShare(ethChainId, ethToken, 20e16);
        uint256 valueEth = riskEngine.getSeizeShare(ethChainId, ethToken);
        assertEq(valueEth, 20e16);
    }

    function test_SetCloseFactor() public {
        riskEngine.setCloseFactor(ethChainId, ethToken, 45e16);
        uint256 valueEth = riskEngine.getCloseFactor(ethChainId, ethToken);
        assertEq(valueEth, 45e16);
    }

    function test_SetMaxLTV_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setChainLtvRatio(ethChainId, ethToken, 90e16);
    }

    function test_SetLiquidationThreshold_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setLiquidationThreshold(ethChainId, ethToken, 65e16);
    }

    function test_SetLiquidationPenalty_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setLiquidationPenalty(ethChainId, ethToken, 5e16);
    }

    function test_SetLiquidationDiscount_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setLiquidationDiscount(ethChainId, ethToken, 20e16);
    }

    function test_SetReserveFactor_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setReserveFactor(ethChainId, ethToken, 35e16);
    }

    function test_SetSeizeShare_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setSeizeShare(ethChainId, ethToken, 20e16);
    }

    function test_SetCloseFactor_NotAuthorized() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        riskEngine.setCloseFactor(ethChainId, ethToken, 45e16);
    }

    function test_SetMaxLTV_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setChainLtvRatio(0, ethToken, 90e16);
    }

    function test_SetLiquidationThreshold_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setLiquidationThreshold(0, ethToken, 65e16);
    }

    function test_SetLiquidationPenalty_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setLiquidationPenalty(0, ethToken, 5e16);
    }

    function test_SetLiquidationDiscount_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setLiquidationDiscount(0, ethToken, 20e16);
    }

    function test_SetReserveFactor_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setReserveFactor(0, ethToken, 35e16);
    }

    function test_SetSeizeShare_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setSeizeShare(0, ethToken, 20e16);
    }

    function test_SetCloseFactor_InvalidArgument() public {
        vm.expectRevert(Errors.InvalidArguments.selector);
        riskEngine.setCloseFactor(0, ethToken, 45e16);
    }
}
