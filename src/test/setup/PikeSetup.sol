// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {SlimRelayer} from "../mocks/SlimRelayer.sol";
import {MockPythOracle} from "../mocks/MockPythOracle.sol";

import {IWormholeRelayer} from "@wormhole/interfaces/IWormholeRelayer.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {Spoke} from "@spoke/Spoke.sol";
import {Hub} from "@hub/Hub.sol";
import {Gateway} from "@gateway/Gateway.sol";
import {WormholeChannel} from "@gateway/channels/wormhole/WormholeChannel.sol";
import {IntraChainChannel} from "@gateway/channels/intrachain/IntraChainChannel.sol";
import {PikeOracle} from "../mocks/MockPikeOracle.sol";
import {PythFeedGetter} from "../mocks/MockPythGetter.sol";
import {IPikeOracleGetter} from "../mocks/IMockPythGetter.sol";
import {InterestRateModel} from "@hub/interest/InterestRateModel.sol";
import {RiskEngine} from "@hub/collateral/RiskEngine.sol";

import {DataTypes} from "@types/DataTypes.sol";

contract PikeSetup {
    Gateway gatewayHub;
    Gateway gatewaySpokeEth;
    Gateway gatewaySpokeOpt;
    Hub hub;
    Spoke spokeHub;
    Spoke spokeEthereum;
    Spoke spokeOptimism;
    PikeToken pikeTokenEth;
    PikeToken pikeTokenOpt;
    InterestRateModel interestRateModel;
    RiskEngine riskEngine;

    MockPythOracle pythOracle;
    PythFeedGetter pythGetter;
    PikeOracle pikeOracle;

    // IWormholeRelayer relayer;
    SlimRelayer slimRelayer;
    WormholeChannel whChannelHub;
    WormholeChannel whChannelSpokeEth;
    WormholeChannel whChannelSpokeOpt;
    IntraChainChannel intraChannel;

    uint16 immutable hubChainId = 30; // 10_160; // Base hub
    uint16 immutable ethChainId = 2; // 10_121; // Ethereum spoke
    uint16 immutable optChainId = 24; // 10_132; // Optimism spoke
    address immutable TOKEN_ETH_UNIVERSAL =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address immutable TOKEN_ARB = address(0xF861378B543525ae0C47d33C90C954Dc774Ac1F9);
    address immutable TOKEN_OP = address(0x32307adfFE088e383AFAa721b06436aDaBA47DBE);
    address immutable TOKEN_BASE = address(0xF175520C52418dfE19C8098071a252da48Cd1C19);
    address alice = address(12_345_678);
    address bob = address(87_654_321);
    uint256 initialExchangeRate = 1e18;

    function setUp() public {
        /// @dev Infrastructure
        hub = Hub(
            Upgrades.deployUUPSProxy(
                "Hub.sol:Hub",
                abi.encodeCall(Hub.initialize, (hubChainId, initialExchangeRate))
            )
        );

        gatewayHub = Gateway(
            Upgrades.deployUUPSProxy(
                "Gateway.sol",
                abi.encodeCall(Gateway.initialize, (hubChainId, address(hub)))
            )
        );
        gatewaySpokeEth = Gateway(
            Upgrades.deployUUPSProxy(
                "Gateway.sol",
                abi.encodeCall(Gateway.initialize, (ethChainId, address(hub)))
            )
        );
        gatewaySpokeOpt = Gateway(
            Upgrades.deployUUPSProxy(
                "Gateway.sol",
                abi.encodeCall(Gateway.initialize, (optChainId, address(hub)))
            )
        );

        pythOracle = new MockPythOracle(86_400, 0);
        pythGetter = new PythFeedGetter( // Abstracted Pyth price getter
        address(pythOracle), bytes32("OP/USD price feed"), int64(15e6));
        pythGetter.addPriceFeed();
        pikeOracle = new PikeOracle(30, address(pythGetter), address(pythOracle));

        interestRateModel = InterestRateModel(
            Upgrades.deployUUPSProxy(
                "InterestRateModel.sol",
                abi.encodeCall(InterestRateModel.initialize, address(hub))
            )
        );

        riskEngine = RiskEngine(
            Upgrades.deployUUPSProxy(
                "RiskEngine.sol",
                abi.encodeCall(RiskEngine.initialize, (address(hub), address(pikeOracle)))
            )
        );

        pikeTokenEth = PikeToken(
            Upgrades.deployUUPSProxy(
                "PikeToken.sol",
                abi.encodeCall(
                    PikeToken.initialize,
                    (
                        "Pike Ethereum",
                        "PIKE",
                        ethChainId,
                        address(hub),
                        address(riskEngine),
                        address(pikeOracle)
                    )
                )
            )
        );
        pikeTokenOpt = PikeToken(
            Upgrades.deployUUPSProxy(
                "PikeToken.sol",
                abi.encodeCall(
                    PikeToken.initialize,
                    (
                        "Pike Optimism",
                        "PIKE",
                        optChainId,
                        address(hub),
                        address(riskEngine),
                        address(pikeOracle)
                    )
                )
            )
        );

        // relayer = IWormholeRelayer(relayer);
        slimRelayer = new SlimRelayer();
        whChannelHub = WormholeChannel(
            payable(
                Upgrades.deployUUPSProxy(
                    "WormholeChannel.sol",
                    abi.encodeCall(
                        WormholeChannel.initialize,
                        (
                            hubChainId,
                            address(slimRelayer),
                            address(gatewayHub),
                            address(gatewayHub),
                            address(0)
                        )
                    )
                )
            )
        );

        whChannelSpokeEth = WormholeChannel(
            payable(
                Upgrades.deployUUPSProxy(
                    "WormholeChannel.sol",
                    abi.encodeCall(
                        WormholeChannel.initialize,
                        (
                            ethChainId,
                            address(slimRelayer),
                            address(gatewaySpokeEth),
                            address(gatewayHub),
                            address(whChannelHub)
                        )
                    )
                )
            )
        );

        whChannelSpokeOpt = WormholeChannel(
            payable(
                Upgrades.deployUUPSProxy(
                    "WormholeChannel.sol",
                    abi.encodeCall(
                        WormholeChannel.initialize,
                        (
                            optChainId,
                            address(slimRelayer),
                            address(gatewaySpokeOpt),
                            address(gatewayHub),
                            address(whChannelHub)
                        )
                    )
                )
            )
        );

        whChannelHub.setTrustedPikes(ethChainId, address(whChannelSpokeEth));
        whChannelHub.setTrustedPikes(optChainId, address(whChannelSpokeOpt));
        whChannelSpokeEth.setTrustedPikes(hubChainId, address(whChannelHub));
        whChannelSpokeEth.setTrustedPikes(optChainId, address(whChannelSpokeOpt));
        whChannelSpokeOpt.setTrustedPikes(hubChainId, address(whChannelHub));
        whChannelSpokeOpt.setTrustedPikes(ethChainId, address(whChannelSpokeEth));

        intraChannel = IntraChainChannel(
            Upgrades.deployUUPSProxy(
                "IntraChainChannel.sol",
                abi.encodeCall(IntraChainChannel.initialize, hubChainId)
            )
        );

        spokeEthereum = Spoke(
            payable(
                Upgrades.deployUUPSProxy(
                    "Spoke.sol",
                    abi.encodeCall(
                        Spoke.initialize,
                        (
                            address(gatewaySpokeEth),
                            address(gatewayHub),
                            address(hub),
                            payable(address(slimRelayer)),
                            hubChainId,
                            ethChainId
                        )
                    )
                )
            )
        );

        spokeOptimism = Spoke(
            payable(
                Upgrades.deployUUPSProxy(
                    "Spoke.sol",
                    abi.encodeCall(
                        Spoke.initialize,
                        (
                            address(gatewaySpokeOpt),
                            address(gatewayHub),
                            address(hub),
                            payable(address(slimRelayer)),
                            hubChainId,
                            optChainId
                        )
                    )
                )
            )
        );

        spokeHub = Spoke(
            payable(
                Upgrades.deployUUPSProxy(
                    "Spoke.sol",
                    abi.encodeCall(
                        Spoke.initialize,
                        (
                            address(gatewayHub),
                            address(gatewayHub),
                            address(hub), // address(endpoint), // LZ
                            payable(address(slimRelayer)),
                            hubChainId,
                            hubChainId // chainId
                        )
                    )
                )
            )
        );

        /// @dev Wiring up the infrastructure
        hub.setInterestRateModel(address(interestRateModel));
        hub.setPikeOracle(address(pikeOracle));
        hub.setRiskEngine(address(riskEngine));
        hub.changeContractAuthorizedStatus(address(whChannelSpokeEth), true);
        hub.changeContractAuthorizedStatus(address(whChannelSpokeOpt), true);
        hub.changeContractAuthorizedStatus(address(intraChannel), true);
        hub.setAuthorizedChannel(ethChainId, address(whChannelSpokeEth));
        hub.setAuthorizedChannel(optChainId, address(whChannelSpokeOpt));
        hub.addChainPikeToken(ethChainId, TOKEN_ETH_UNIVERSAL, address(pikeTokenEth));
        hub.addChainPikeToken(optChainId, TOKEN_ETH_UNIVERSAL, address(pikeTokenOpt));
        hub.addNewMarket(
            ethChainId,
            TOKEN_ETH_UNIVERSAL,
            0,
            pikeTokenEth.name(),
            pikeTokenEth.symbol(),
            true,
            false,
            18
        );
        hub.addNewMarket(
            optChainId,
            TOKEN_ETH_UNIVERSAL,
            0,
            "ETH",
            pikeTokenOpt.symbol(),
            true,
            false,
            18
        );

        spokeEthereum.setAssetType(TOKEN_ETH_UNIVERSAL, DataTypes.Asset.EVM);
        spokeOptimism.setAssetType(TOKEN_OP, DataTypes.Asset.ERC);
        spokeEthereum.setNativeAssetAddress(TOKEN_ETH_UNIVERSAL);
        spokeOptimism.setNativeAssetAddress(TOKEN_ETH_UNIVERSAL);
        spokeHub.setAssetType(TOKEN_ETH_UNIVERSAL, DataTypes.Asset.EVM);
        spokeHub.setAssetType(TOKEN_ARB, DataTypes.Asset.ERC);
        spokeHub.setAssetType(TOKEN_OP, DataTypes.Asset.ERC);
        spokeHub.setAssetType(TOKEN_BASE, DataTypes.Asset.USDC);

        uint16[] memory chainIds = new uint16[](2);
        address[] memory oracles = new address[](2);
        IPikeOracleGetter[] memory getters = new IPikeOracleGetter[](2);
        chainIds[0] = optChainId; // Optimism
        oracles[0] = address(pythOracle);
        getters[0] = IPikeOracleGetter(pythGetter);
        chainIds[1] = ethChainId; // Ethereum
        oracles[1] = address(pythOracle);
        getters[1] = IPikeOracleGetter(pythGetter);
        pikeOracle.setOracleFeeds(chainIds, oracles, getters);
        hub.addNewChains(chainIds);

        gatewaySpokeEth.setLocalSpoke(address(spokeEthereum));
        gatewaySpokeEth.changeChannelAuthorizedStatus(address(spokeEthereum), true);
        gatewaySpokeEth.changeChannelAuthorizedStatus(address(whChannelSpokeEth), true);
        gatewaySpokeEth.addChannel(DataTypes.Transport.WORMHOLE, whChannelSpokeEth);

        gatewaySpokeOpt.setLocalSpoke(address(spokeOptimism));
        gatewaySpokeOpt.changeChannelAuthorizedStatus(address(spokeOptimism), true);
        gatewaySpokeOpt.changeChannelAuthorizedStatus(address(whChannelSpokeOpt), true);
        gatewaySpokeOpt.addChannel(DataTypes.Transport.WORMHOLE, whChannelSpokeOpt);

        gatewayHub.setLocalSpoke(address(spokeHub)); // for testing forwarding
        IntraChainChannel(address(intraChannel)).setGatewayAddress(address(gatewayHub));
        gatewayHub.changeChannelAuthorizedStatus(address(hub), true);
        gatewayHub.changeChannelAuthorizedStatus(address(spokeHub), true);
        gatewayHub.changeChannelAuthorizedStatus(address(whChannelHub), true);
        gatewayHub.addChannel(DataTypes.Transport.WORMHOLE, whChannelHub);
        gatewayHub.addChannel(DataTypes.Transport.INTRACHAIN, intraChannel);
        hub.changeLocalGateway(gatewayHub);

        pikeTokenEth.setHubAddress(address(hub));
        pikeTokenOpt.setHubAddress(address(hub));

        uint256[][] memory ltvs = new uint256[][](2);
        address[][] memory chainTokens = new address[][](2);
        uint256[][] memory liqThresholds = new uint256[][](2);
        uint256[][] memory liqPenalties = new uint256[][](2);
        uint256[][] memory liqDiscounts = new uint256[][](2);
        uint256[][] memory reserveFactors = new uint256[][](2);
        uint256[][] memory shares = new uint256[][](2);
        uint256[][] memory closeFactors = new uint256[][](2);
        ltvs[0] = new uint256[](1);
        ltvs[0][0] = 75e16;
        ltvs[1] = new uint256[](1);
        ltvs[1][0] = 75e16;
        chainTokens[0] = new address[](1);
        chainTokens[0][0] = address(TOKEN_ETH_UNIVERSAL);
        chainTokens[1] = new address[](1);
        chainTokens[1][0] = address(TOKEN_ETH_UNIVERSAL);
        liqThresholds[0] = new uint256[](1);
        liqThresholds[0][0] = 80e16;
        liqThresholds[1] = new uint256[](1);
        liqThresholds[1][0] = 80e16;
        liqDiscounts[0] = new uint256[](1);
        liqDiscounts[0][0] = 10e16;
        liqDiscounts[1] = new uint256[](1);
        liqDiscounts[1][0] = 10e16;
        liqPenalties[0] = new uint256[](1);
        liqPenalties[0][0] = 5e16;
        liqPenalties[1] = new uint256[](1);
        liqPenalties[1][0] = 5e16;
        reserveFactors[0] = new uint256[](1);
        reserveFactors[0][0] = 20e16;
        reserveFactors[1] = new uint256[](1);
        reserveFactors[1][0] = 20e16;
        shares[0] = new uint256[](1);
        shares[0][0] = 5e16;
        shares[1] = new uint256[](1);
        shares[1][0] = 5e16;
        closeFactors[0] = new uint256[](1);
        closeFactors[0][0] = 70e16;
        closeFactors[1] = new uint256[](1);
        closeFactors[1][0] = 70e16;
        riskEngine.setChainLtvRatios(chainIds, chainTokens, ltvs);
        riskEngine.setLiquidationThresholds(chainIds, chainTokens, liqThresholds);
        riskEngine.setLiquidationDiscounts(chainIds, chainTokens, liqDiscounts);
        riskEngine.setLiquidationPenalties(chainIds, chainTokens, liqPenalties);
        riskEngine.setReserveFactors(chainIds, chainTokens, reserveFactors);
        riskEngine.setSeizeShares(chainIds, chainTokens, shares);
        riskEngine.setCloseFactors(chainIds, chainTokens, closeFactors);
        hub.addNewTokens(chainTokens);
    }
}
