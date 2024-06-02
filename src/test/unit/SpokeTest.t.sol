// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DSTestFull} from "../utils/DSTestFull.sol";

import {ERC1967Proxy} from "@openzeppelin-pike/proxy/ERC1967/ERC1967Proxy.sol";

import {Spoke} from "@spoke/Spoke.sol";
import {MockGateway} from "../mocks/MockGateway.sol";
import {MockTransferToken} from "../mocks/MockTransferToken.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract SpokeUnitTest is DSTestFull {
    Spoke ethereumSpoke;
    Spoke hubSpoke;
    MockGateway mockGateway;
    MockTransferToken mockToken;

    address immutable alice = address(444_555_666);
    uint16 immutable hubChainId = 30;
    uint16 immutable ethChainId = 31;

    function setUp() public {
        mockGateway = new MockGateway();
        mockToken = new MockTransferToken();

        address spokeImplementation = address(new Spoke());
        bytes memory spokeEthData = abi.encodeCall(
            Spoke.initialize,
            (
                address(mockGateway),
                address(mockGateway),
                address(0),
                payable(address(0)),
                hubChainId,
                ethChainId
            )
        );
        address payable spokeEthProxy =
            payable(address(new ERC1967Proxy(spokeImplementation, spokeEthData)));

        bytes memory spokeHubData = abi.encodeCall(
            Spoke.initialize,
            (
                address(mockGateway),
                address(mockGateway),
                address(0),
                payable(address(0)),
                hubChainId,
                hubChainId
            )
        );
        address payable spokeHubProxy =
            payable(address(new ERC1967Proxy(spokeImplementation, spokeHubData)));
        ethereumSpoke = Spoke(spokeEthProxy);
        hubSpoke = Spoke(spokeHubProxy);
    }

    function test_Supply() public {
        ethereumSpoke.supplyErc(DataTypes.Asset.ERC, address(mockToken), 1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.WORMHOLE);
        hubSpoke.supplyErc(DataTypes.Asset.ERC, address(mockToken), 1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_SupplyErc() public {
        ethereumSpoke.supply(1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.WORMHOLE);
        hubSpoke.supply(1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_Borrow() public {
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.borrow(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            1 ether,
            false,
            3,
            address(4),
            5,
            0
        );
        hubSpoke.borrow(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            1 ether,
            false,
            3,
            address(4),
            5,
            0
        );
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_Repay() public {
        ethereumSpoke.repay{value: 1}(1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.WORMHOLE);
        hubSpoke.repay{value: 1}(1 ether, 0);
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_RepayErc() public {
        ethereumSpoke.repayErc(
            DataTypes.Asset.ERC, address(mockToken), address(1), 3, 1 ether, 0
        );
        assertTrue(mockGateway.channel() == DataTypes.Transport.WORMHOLE);
        hubSpoke.repayErc(
            DataTypes.Asset.ERC, address(mockToken), address(1), 3, 1 ether, 0
        );
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_Withdraw() public {
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.withdraw(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            1 ether,
            false,
            3,
            address(4),
            5,
            0
        );
        hubSpoke.withdraw(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            1 ether,
            false,
            3,
            address(4),
            5,
            0
        );
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_Liquidate() public {
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.liquidate(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            3,
            address(4),
            5,
            false,
            0
        );
        hubSpoke.liquidate{value: 5}(
            DataTypes.Asset.EVM,
            DataTypes.Transport.WORMHOLE,
            address(1),
            3,
            address(4),
            5,
            false,
            0
        );
        assertTrue(mockGateway.channel() == DataTypes.Transport.INTRACHAIN);
    }

    function test_SetAllowedToken() public {
        ethereumSpoke.setAllowedToken(address(mockToken), true);
        assertEq(ethereumSpoke.allowedTokens(address(mockToken)), true);
    }

    function test_SetAllowedToken_NotAdmin() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.setAllowedToken(address(mockToken), true);
    }

    function test_SetNativeAssetAddress() public {
        ethereumSpoke.setNativeAssetAddress(address(mockToken));
        assertEq(ethereumSpoke.nativeAsset(), address(mockToken));
    }

    function test_SetNativeAssetAddress_NotAdmin() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.setNativeAssetAddress(address(mockToken));
    }

    function test_SetUsdcTokenAddress() public {
        ethereumSpoke.setUsdcTokenAddress(address(mockToken));
        assertEq(ethereumSpoke.usdcTokenAddress(), address(mockToken));
    }

    function test_SetUsdcTokenAddress_NotAdmin() public {
        vm.prank(alice);
        vm.expectRevert(Errors.CallerNotAuthorized.selector);
        ethereumSpoke.setUsdcTokenAddress(address(mockToken));
    }
}
