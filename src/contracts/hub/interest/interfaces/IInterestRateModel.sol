// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IInterestRateModel {
    struct TokenSupplyRate {
        uint16 chainId;
        address tokenAddress;
        uint256 supplyRate;
    }

    struct TokenBorrowRate {
        uint16 chainId;
        address tokenAddress;
        uint256 borrowRate;
    }

    function getUtilizationRate(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getSupplyRate(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function calculateVariableBorrowRate(uint256 currentUtilizationRate)
        external
        pure
        returns (uint256);

    function calculateStableBorrowRate(uint256 currentUtilizationRate)
        external
        pure
        returns (uint256 variableRate);
}
