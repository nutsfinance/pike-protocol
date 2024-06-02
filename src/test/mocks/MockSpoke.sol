// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

contract MockSpoke {
    DataTypes.SpokeDecline internal storedSupplyDeclined;
    DataTypes.SpokeDecline internal storedBorrowDeclined;
    DataTypes.SpokeDecline internal storedRepayDeclined;
    DataTypes.SpokeDecline internal storedWithdrawlDeclined;
    DataTypes.SpokeDecline internal storedLiquidateDeclined;
    DataTypes.SpokeBorrowForward internal storedBorrowForward;
    DataTypes.SpokeWithdrawalForward internal storedWithdrawlForward;
    DataTypes.SpokeLiquidateForward internal storedLiquidateForward;

    function supplyDeclined(DataTypes.SpokeDecline memory a) public {
        storedSupplyDeclined = a;
    }

    function borrowDeclined(DataTypes.SpokeDecline memory a) public {
        storedBorrowDeclined = a;
    }

    function repayDeclined(DataTypes.SpokeDecline memory a) public {
        storedRepayDeclined = a;
    }

    function withdrawalDeclined(DataTypes.SpokeDecline memory a) public {
        storedWithdrawlDeclined = a;
    }

    function liquidationDeclined(DataTypes.SpokeDecline memory a) public {
        storedLiquidateDeclined = a;
    }

    function borrowApproved(DataTypes.SpokeBorrowForward memory a) public {
        storedBorrowForward = a;
    }

    function withdrawalApproved(DataTypes.SpokeWithdrawalForward memory a) public {
        storedWithdrawlForward = a;
    }

    function liquidationApproved(DataTypes.SpokeLiquidateForward memory a) public {
        storedLiquidateForward = a;
    }

    function getStoredSupplyDeclined()
        public
        view
        returns (DataTypes.SpokeDecline memory)
    {
        return storedSupplyDeclined;
    }

    function getStoredBorrowDeclined()
        public
        view
        returns (DataTypes.SpokeDecline memory)
    {
        return storedBorrowDeclined;
    }

    function getStoredRepayDeclined()
        public
        view
        returns (DataTypes.SpokeDecline memory)
    {
        return storedRepayDeclined;
    }

    function getStoredWithdrawlDeclined()
        public
        view
        returns (DataTypes.SpokeDecline memory)
    {
        return storedWithdrawlDeclined;
    }

    function getStoredLiquidateDeclined()
        public
        view
        returns (DataTypes.SpokeDecline memory)
    {
        return storedLiquidateDeclined;
    }

    function getStoredBorrowForward()
        public
        view
        returns (DataTypes.SpokeBorrowForward memory)
    {
        return storedBorrowForward;
    }

    function getStoredWithdrawlForward()
        public
        view
        returns (DataTypes.SpokeWithdrawalForward memory)
    {
        return storedWithdrawlForward;
    }

    function getStoredLiquidateForward()
        public
        view
        returns (DataTypes.SpokeLiquidateForward memory)
    {
        return storedLiquidateForward;
    }
}
