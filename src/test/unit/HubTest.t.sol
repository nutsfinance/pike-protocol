// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {Hub} from "@hub/Hub.sol";
import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {RiskEngine} from "@hub/collateral/RiskEngine.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {InterestRateModel} from "@hub/interest/InterestRateModel.sol";
import {PikePriceOracle} from "@hub/oracle/PikePriceOracle.sol";
import {MockGateway} from "../mocks/MockGateway.sol";
import {MockPythOracle} from "../mocks/MockPythOracle.sol";
import {PythFeedGetter} from "../mocks/MockPythGetter.sol";
import {PikeOracle} from "../mocks/MockPikeOracle.sol";
import {IPikeOracleGetter} from "../mocks/IMockPythGetter.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract HubUnitTest is DSTestFull {
    Hub hub;
    RiskEngine riskEngine;
    InterestRateModel interestRateModel;
    PikePriceOracle pikeOracle;
    PikeToken pikeTokenEth;
    PikeToken pikeTokenOpt;
    MockGateway mockGateway;
    uint256 immutable initialExchangeRate = 2e16;
    uint16 immutable hubChainId = 10;
    uint16 immutable ethChainId = 30;
    uint16 immutable opChainId = 31;
    address immutable ethToken = address(12_345_678);
    address immutable opToken = address(87_654_321);
    address immutable alice = address(444_555_666);
    address immutable bob = address(777_555_666);

    function setUpRiskEngine() internal {
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
        hub.addNewChains(chainIds);
        hub.addNewTokens(chainTokens);
        hub.setRiskEngine(address(riskEngine));
    }

    function setUpInterestRateModel() internal {
        address interestRateModelImplementation = address(new InterestRateModel());
        bytes memory interestRateModelData =
            abi.encodeCall(InterestRateModel.initialize, address(hub));
        address interestRateModelProxy = address(
            new ERC1967Proxy(interestRateModelImplementation, interestRateModelData)
        );
        interestRateModel = InterestRateModel(interestRateModelProxy);
        hub.setInterestRateModel(address(interestRateModel));
    }

    function setUpPikeTokens() internal {
        address pikeTokenImplementation = address(new PikeToken());
        bytes memory pikeTokenEthData = abi.encodeCall(
            PikeToken.initialize,
            (
                "Pike Ethereum",
                "PIKE",
                ethChainId,
                address(hub),
                address(riskEngine),
                address(pikeOracle)
            )
        );
        address pikeTokenEthProxy =
            address(new ERC1967Proxy(pikeTokenImplementation, pikeTokenEthData));
        bytes memory pikeTokenOptData = abi.encodeCall(
            PikeToken.initialize,
            (
                "Pike Optimism",
                "PIKE",
                opChainId,
                address(hub),
                address(riskEngine),
                address(pikeOracle)
            )
        );
        address pikeTokenOptProxy =
            address(new ERC1967Proxy(pikeTokenImplementation, pikeTokenOptData));
        pikeTokenEth = PikeToken(pikeTokenEthProxy);
        pikeTokenOpt = PikeToken(pikeTokenOptProxy);
        pikeTokenEth.setHubAddress(address(hub));
        pikeTokenOpt.setHubAddress(address(hub));
    }

    function setUpOracle() internal {
        MockPythOracle pythOracle = new MockPythOracle(86_400, 0);
        PythFeedGetter pythGetter = new PythFeedGetter( // Abstracted Pyth price getter
        address(pythOracle), bytes32("OP/USD price feed"), int64(15e6));
        pythGetter.addPriceFeed();
        // PikeOracle pikeOracle =
        //     new PikeOracle(hubChainId, address(pythGetter), address(pythOracle));
        IPikeOracleGetter[] memory getters = new IPikeOracleGetter[](2);
        uint16[] memory chainIds = new uint16[](2);
        address[] memory oracles = new address[](2);
        chainIds[0] = ethChainId; // Optimism
        oracles[0] = address(pythOracle);
        getters[0] = IPikeOracleGetter(pythGetter);
        chainIds[1] = opChainId; // Ethereum
        oracles[1] = address(pythOracle);
        getters[1] = IPikeOracleGetter(pythGetter);
        // pikeOracle.setOracleFeeds(chainIds, oracles, getters);
        hub.setPikeOracle(address(pikeOracle));
    }

    function setUp() public {
        address hubImplementation = address(new Hub());
        bytes memory hubData =
            abi.encodeCall(Hub.initialize, (hubChainId, initialExchangeRate)); // initial exchange rate is 0.02
        address hubProxy = address(new ERC1967Proxy(hubImplementation, hubData));
        hub = Hub(hubProxy);

        mockGateway = new MockGateway();
        setUpPikeTokens();

        hub.addNewMarket(ethChainId, ethToken, 0, "A", "A", true, false, 18);
        hub.addNewMarket(opChainId, opToken, 0, "ETH", "ETH", true, false, 18);
        hub.addChainPikeToken(ethChainId, ethToken, address(pikeTokenEth));
        hub.addChainPikeToken(opChainId, opToken, address(pikeTokenOpt));
        hub.changeLocalGateway(IGateway(address(mockGateway)));

        setUpInterestRateModel();
        setUpRiskEngine();
        setUpOracle();
    }

    function deposit() internal {
        DataTypes.HubDeposit memory payload = DataTypes.HubDeposit({
            action: DataTypes.Action.HUB_DEPOSIT,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            amountDeposited: 10 ether,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: hubChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        hub.processDeposit(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function borrow() internal {
        DataTypes.HubBorrow memory payload = DataTypes.HubBorrow({
            action: DataTypes.Action.HUB_BORROW,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            borrowAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        hub.processBorrow(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessDeposit() public {
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        DataTypes.HubDeposit memory payload = DataTypes.HubDeposit({
            action: DataTypes.Action.HUB_DEPOSIT,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            amountDeposited: 10 ether,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: hubChainId
        });
        hub.processDeposit(payload, bytes32(uint256(uint160(address(mockGateway)))));
        // (,, uint256 userDeposit) = hub.getDeposits(ethChainId, ethToken, alice);
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(ethChainId, ethToken);
        // assertEq(userDeposit, 10 ether);
        assertEq(totalLiquidity, 10 ether);
    }

    function test_ProcessBorrow_NotEnoughReserve() public {
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        DataTypes.HubBorrow memory payload = DataTypes.HubBorrow({
            action: DataTypes.Action.HUB_BORROW,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            borrowAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.expectRevert(Errors.ReserveNotEnough.selector);
        hub.processBorrow(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessBorrow_NotEnoughTime() public {
        deposit();
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        DataTypes.HubBorrow memory payload = DataTypes.HubBorrow({
            action: DataTypes.Action.HUB_BORROW,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            borrowAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.expectRevert(Errors.NotEnoughTimePassed.selector);
        hub.processBorrow(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessBorrow() public {
        deposit();
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        DataTypes.HubBorrow memory payload = DataTypes.HubBorrow({
            action: DataTypes.Action.HUB_BORROW,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            borrowAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.warp(1 hours);
        hub.processBorrow(payload, bytes32(uint256(uint160(address(mockGateway)))));
        (,, uint256 totalBorrow) = hub.getTotalBorrows(ethChainId, ethToken);
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(ethChainId, ethToken);
        assertEq(totalBorrow, 1 ether);
        assertEq(totalLiquidity, 9 ether);
    }

    function test_ProcessRepay_NoBalance() public {
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        DataTypes.HubRepay memory payload = DataTypes.HubRepay({
            action: DataTypes.Action.HUB_REPAY,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            repaidAmount: 1 ether,
            fullRepayment: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.expectRevert(Errors.InvalidArguments.selector);
        hub.processRepay(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessRepay_NotEnoughTime() public {
        deposit();
        vm.warp(1 hours);
        borrow();

        DataTypes.HubRepay memory payload = DataTypes.HubRepay({
            action: DataTypes.Action.HUB_REPAY,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            repaidAmount: 1 ether,
            fullRepayment: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.expectRevert(Errors.NotEnoughTimePassed.selector);
        hub.processRepay(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessRepay() public {
        deposit();
        vm.warp(1 hours);
        borrow();
        DataTypes.HubRepay memory payload = DataTypes.HubRepay({
            action: DataTypes.Action.HUB_REPAY,
            nonce: 123,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            repaidAmount: 1 ether,
            fullRepayment: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.warp(2 hours);
        hub.processRepay(payload, bytes32(uint256(uint160(address(mockGateway)))));
        (,, uint256 totalBorrow) = hub.getTotalBorrows(ethChainId, ethToken);
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(ethChainId, ethToken);
        assertLt(totalBorrow, 1000);
        assertEq(totalLiquidity, 10 ether);
    }

    function test_ProcessWithdrawl_NotEnoughReserve() public {
        DataTypes.HubWithdrawal memory payload = DataTypes.HubWithdrawal({
            action: DataTypes.Action.HUB_WITHDRAWAL,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            withdrawAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            fullWithdrawal: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.expectRevert(Errors.ReserveNotEnough.selector);
        hub.processWithdrawal(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessWithdrawl_NotEnoughTime() public {
        deposit();
        DataTypes.HubWithdrawal memory payload = DataTypes.HubWithdrawal({
            action: DataTypes.Action.HUB_WITHDRAWAL,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            withdrawAmount: 1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            fullWithdrawal: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.expectRevert(Errors.NotEnoughTimePassed.selector);
        hub.processWithdrawal(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessWithdrawl() public {
        deposit();
        DataTypes.HubWithdrawal memory payload = DataTypes.HubWithdrawal({
            action: DataTypes.Action.HUB_WITHDRAWAL,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            assetToken: ethToken,
            withdrawAmount: 0.1 ether,
            usdcMintRequired: false,
            targetAddress: bob,
            fullWithdrawal: true,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId,
            cctpTargetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.warp(2 hours);
        hub.processWithdrawal(payload, bytes32(uint256(uint160(address(mockGateway)))));
        (,, uint256 totalBorrow) = hub.getTotalBorrows(ethChainId, ethToken);
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(ethChainId, ethToken);
        assertEq(totalBorrow, 0);
        assertEq(totalLiquidity, 9.9 ether);
    }

    function test_ProcessLiquidation_InvalidAmount() public {
        DataTypes.HubLiquidate memory payload = DataTypes.HubLiquidate({
            action: DataTypes.Action.HUB_LIQUIDATE,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            liquidator: bob,
            repayAmount: 1 ether,
            usdcMintRequired: false,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.expectRevert(Errors.InvalidLiquidationAmount.selector);
        hub.processLiquidation(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessLiquidation_NotEnoughTime() public {
        deposit();
        vm.warp(1 hours);
        borrow();
        uint256[][] memory ltvs = new uint256[][](2);
        address[][] memory chainTokens = new address[][](2);
        uint16[] memory chainIds = new uint16[](2);
        ltvs[0] = new uint256[](1);
        ltvs[0][0] = 60e16;
        ltvs[1] = new uint256[](1);
        ltvs[1][0] = 60e16;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = address(ethToken);
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = address(opToken);
        chainIds[0] = ethChainId;
        chainIds[1] = opChainId;
        riskEngine.setChainLtvRatios(chainIds, chainTokens, ltvs);
        DataTypes.HubLiquidate memory payload = DataTypes.HubLiquidate({
            action: DataTypes.Action.HUB_LIQUIDATE,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            liquidator: bob,
            repayAmount: 1 ether,
            usdcMintRequired: false,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.expectRevert(Errors.NotEnoughTimePassed.selector);
        hub.processLiquidation(payload, bytes32(uint256(uint160(address(mockGateway)))));
    }

    function test_ProcessLiquidation() public {
        deposit();
        vm.warp(1 hours);
        borrow();
        uint256[][] memory ltvs = new uint256[][](2);
        address[][] memory chainTokens = new address[][](2);
        uint16[] memory chainIds = new uint16[](2);
        ltvs[0] = new uint256[](1);
        ltvs[0][0] = 10e16;
        ltvs[1] = new uint256[](1);
        ltvs[1][0] = 10e16;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = address(ethToken);
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = address(opToken);
        chainIds[0] = ethChainId;
        chainIds[1] = opChainId;
        riskEngine.setChainLtvRatios(chainIds, chainTokens, ltvs);
        DataTypes.HubLiquidate memory payload = DataTypes.HubLiquidate({
            action: DataTypes.Action.HUB_LIQUIDATE,
            assetType: DataTypes.Asset.EVM,
            transport: DataTypes.Transport.WORMHOLE,
            user: alice,
            sourceToken: ethToken,
            targetToken: ethToken,
            liquidator: bob,
            repayAmount: 0.1 ether,
            usdcMintRequired: false,
            forwardCost: 6,
            sourceChainId: ethChainId,
            targetChainId: ethChainId
        });
        vm.prank(address(mockGateway));
        hub.changeContractAuthorizedStatus(address(mockGateway), true);
        vm.warp(2 hours);
        hub.processLiquidation(payload, bytes32(uint256(uint160(address(mockGateway)))));
        (,, uint256 totalBorrow) = hub.getTotalBorrows(ethChainId, ethToken);
        (,, uint256 totalLiquidity) = hub.getTotalLiquidity(ethChainId, ethToken);
        assertGt(totalBorrow, 1 ether);
        assertEq(totalLiquidity, 9.09 ether);
    }
}
