// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract RiskEngineEvents {
    event RiskModelUpdated(uint256 chainId, address riskModel);
    event ChainLtvRatioUpdated(uint256 chainId, uint256 ltvRatio);
    event ChainLiquidationThresholdUpdated(uint256 chainId, uint256 threshold);
    event ChainLiquidationPenaltyUpdated(uint256 chainId, uint256 penalty);
    event ChainLiquidationDiscountUpdated(uint256 chainId, uint256 discount);
    event ChainReserveFactorUpdated(uint256 chainId, uint256 factor);
    event ChainSeizeShareUpdated(uint256 chainId, uint256 share);
    event ChainCloseFactorUpdated(uint256 chainId, uint256 factor);
}
