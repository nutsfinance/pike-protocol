// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {Hub} from "@hub/Hub.sol";
import {RiskEngine} from "@hub/collateral/RiskEngine.sol";
import {PikePriceOracle} from "@hub/oracle/PikePriceOracle.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {MockPikeToken} from "../mocks/MockPikeToken.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract PikeTokenUpgradesUnitTest is DSTestFull {
    Hub hub;
    RiskEngine riskEngine;
    PikePriceOracle pikeOracle;
    PikeToken pikeToken;
    uint16 immutable ethChainId = 30;
    address immutable alice = address(444_555_666);

    function setUp() public {
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
        pikeToken = PikeToken(pikeTokenEthProxy);
    }

    function test_Upgrades() public {
        assertEq(pikeToken.name(), "Pike Ethereum");
        assertEq(pikeToken.totalSupply(), 0);
        address pikeTokenImplementation = address(new MockPikeToken());
        // pikeToken.upgradeTo(pikeTokenImplementation);
        pikeToken.mint(alice, 10 ether);
        assertEq(pikeToken.balanceOf(alice), 10 ether);
        assertEq(pikeToken.totalSupply(), 10 ether);
    }

    function test_Upgrades_NotAuthorized() public {
        assertEq(pikeToken.name(), "Pike Ethereum");
        assertEq(pikeToken.totalSupply(), 0);
        address pikeTokenImplementation = address(new MockPikeToken());
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        // pikeToken.upgradeTo(pikeTokenImplementation);
    }
}
