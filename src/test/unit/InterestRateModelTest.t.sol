// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {InterestRateModel} from "@hub/interest/InterestRateModel.sol";
import {IInterestRateModel} from "@hub/interest/interfaces/IInterestRateModel.sol";
import {MockHub} from "../mocks/MockHub.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract InterestRateModelUnitTest is DSTestFull {
    InterestRateModel interestRateModel;
    MockHub mockHub;
    uint16 immutable ethChainId = 30;
    uint16 immutable opChainId = 31;
    address immutable ethToken = address(12_345_678);
    address immutable opToken = address(87_654_321);
    address immutable alice = address(444_555_666);

    function setUp() public {
        mockHub = new MockHub();

        address interestRateModelImplementation = address(new InterestRateModel());
        bytes memory interestRateModelData =
            abi.encodeCall(InterestRateModel.initialize, address(mockHub));
        address interestRateModelProxy = address(
            new ERC1967Proxy(interestRateModelImplementation, interestRateModelData)
        );
        interestRateModel = InterestRateModel(interestRateModelProxy);
    }

    function test_GetUtilizationRate() public {
        uint256 resultEth = interestRateModel.getUtilizationRate(ethChainId, ethToken);
        assertEq(resultEth, 142_857_142_857_142_857);
        uint256 resultOp = interestRateModel.getUtilizationRate(opChainId, ethToken);
        assertEq(resultOp, 0);
    }

    function test_GetSupplyRate() public {
        uint256 resultEth = interestRateModel.getSupplyRate(ethChainId, ethToken);
        assertEq(resultEth, 1_304_081_632_653_060);
        uint256 resultOp = interestRateModel.getSupplyRate(opChainId, ethToken);
        assertEq(resultOp, 0);
    }

    function test_CalculateVariableBorrowRate() public {
        uint256 resultUnder = interestRateModel.calculateVariableBorrowRate(70e16);
        assertEq(resultUnder, 10_700_000_000_000_000);
        uint256 resultOver = interestRateModel.calculateVariableBorrowRate(90e16);
        assertEq(resultOver, 11_100_000_000_000_000);
    }

    function test_CalculateStableBorrowRate() public {
        uint256 resultUnder = interestRateModel.calculateStableBorrowRate(70e16);
        assertEq(resultUnder, 30_700_000_000_000_000);
        uint256 resultOver = interestRateModel.calculateStableBorrowRate(90e16);
        assertEq(resultOver, 31_100_000_000_000_000);
    }

    function test_GetSupplyRates() public {
        uint16[] memory chainIds = new uint16[](2);
        address[][] memory chainTokens = new address[][](2);
        chainIds[0] = ethChainId;
        chainIds[1] = opChainId;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = ethToken;
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = opToken;
        IInterestRateModel.TokenSupplyRate[][] memory results =
            interestRateModel.getSupplyRates(chainIds, chainTokens);
        assertEq(results.length, 2);
        assertEq(results[0].length, 1);
        assertEq(results[1].length, 1);
        assertEq(results[0][0].supplyRate, 1_304_081_632_653_060);
        assertEq(results[1][0].supplyRate, 0);
    }

    function test_GetBorrowRatess() public {
        uint16[] memory chainIds = new uint16[](2);
        address[][] memory chainTokens = new address[][](2);
        chainIds[0] = ethChainId;
        chainIds[1] = opChainId;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = ethToken;
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = opToken;
        IInterestRateModel.TokenBorrowRate[][] memory results =
            interestRateModel.getBorrowRates(chainIds, chainTokens);
        assertEq(results.length, 2);
        assertEq(results[0].length, 1);
        assertEq(results[1].length, 1);
        assertEq(results[0][0].borrowRate, 10_142_857_142_857_142);
        assertEq(results[1][0].borrowRate, 10_000_000_000_000_000);
    }
}
