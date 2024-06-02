// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract InterestRateModelEvents {
    event NewInterestRatesCalculated(
        uint256 utilizationRate, uint256 borrowRate, uint256 supplyRate
    );
}
