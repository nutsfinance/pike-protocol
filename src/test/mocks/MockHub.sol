// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

contract MockHub {
    DataTypes.HubDeposit internal storedDeposit;
    DataTypes.HubBorrow internal storedBorrow;
    DataTypes.HubRepay internal storedRepay;
    DataTypes.HubWithdrawal internal storedWithdrawl;
    DataTypes.HubLiquidate internal storedLiquidate;

    function processDeposit(DataTypes.HubDeposit memory a) public {
        storedDeposit = a;
    }

    function processBorrow(DataTypes.HubBorrow memory a) public {
        storedBorrow = a;
    }

    function processRepay(DataTypes.HubRepay memory a) public {
        storedRepay = a;
    }

    function processWithdrawal(DataTypes.HubWithdrawal memory a) public {
        storedWithdrawl = a;
    }

    function processLiquidation(DataTypes.HubLiquidate memory a) public {
        storedLiquidate = a;
    }

    function getTotalBorrows(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256)
    {
        if (chainId == 31) {
            return (0, address(0), 0);
        }
        return (0, address(0), 1e16);
    }

    function getTotalLiquidity(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256)
    {
        return (0, address(0), 10e16);
    }

    function getTotalReserves(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256)
    {
        return (0, address(0), 4e16);
    }

    function getStoredDeposit() public view returns (DataTypes.HubDeposit memory) {
        return storedDeposit;
    }

    function getStoredBorrow() public view returns (DataTypes.HubBorrow memory) {
        return storedBorrow;
    }

    function getStoredRepay() public view returns (DataTypes.HubRepay memory) {
        return storedRepay;
    }

    function getStoredWithdrawl() public view returns (DataTypes.HubWithdrawal memory) {
        return storedWithdrawl;
    }

    function getStoredLiquidate() public view returns (DataTypes.HubLiquidate memory) {
        return storedLiquidate;
    }
}
