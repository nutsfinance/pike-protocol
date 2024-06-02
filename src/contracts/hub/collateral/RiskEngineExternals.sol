// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRiskEngine} from "./interfaces/IRiskEngine.sol";
import {RiskEngineStorage} from "./RiskEngineStorage.sol";
import {RiskEngineMath} from "./RiskEngineMath.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract RiskEngineExternals is
    IRiskEngine,
    RiskEngineStorage,
    RiskEngineMath
{
    function checkBorrowAllowed(DataTypes.HubBorrow memory a) public {
        DataTypes.BorrowLocalVars memory v;

        // Accumulating the total user's collateral in USD according to oracle
        v.numChains = hub.getChainsLength();
        for (uint16 i; i < v.numChains;) {
            uint16 chain = hub.chains(i);
            (uint16 chainLength, address[] memory arrayTokens) =
                hub.getChainTokensData(chain);

            for (uint16 j; j < chainLength;) {
                (uint256 price, uint256 decimals) =
                    pikeOracle.getAssetPrice(chain, arrayTokens[j]);
                if (price <= 0) revert Errors.NegativePriceFound();

                PikeToken pToken = PikeToken(hub.getPikeToken(chain, arrayTokens[j]));
                pToken.accrueInterestsForToken();

                if (pToken.balanceOf(a.user) > 0) {
                    uint256 er = pToken.exchangeRateStored();
                    uint256 collateral = mul(er, pToken.balanceOf(a.user));
                    uint256 unscaled = collateral * price * maxLTVs[chain][arrayTokens[j]];

                    v.maxBorrowAmountInUsd += unscaled / (DECIMALS * 10 ** decimals);
                }

                DataTypes.BorrowSnapshot memory b = pToken.getUserBorrows(a.user);
                if (b.principal > 0) {
                    uint256 accruedBorrow = pToken.borrowBalanceStored(a.user);
                    v.borrowAmountInUsd += (accruedBorrow * price) / 10 ** decimals;
                }

                /// @dev ensuring user borrows + new borrowAmount is less than max allowed
                if (chain == a.targetChainId && arrayTokens[j] == a.assetToken) {
                    /// @dev revert if mint is requested for non-USDC assets
                    if (a.assetType != DataTypes.Asset.USDC && a.usdcMintRequired) {
                        revert Errors.InvalidArguments();
                    }
                    /// @dev revert if mint is requested and enough funds
                    /// @dev revert if mint is not requested and not enough funds
                    if (
                        a.assetType == DataTypes.Asset.USDC
                            && (
                                (
                                    pToken.totalLiquidity() >= a.borrowAmount
                                        && a.usdcMintRequired
                                )
                                    || (
                                        pToken.totalLiquidity() < a.borrowAmount
                                            && !a.usdcMintRequired
                                    )
                            )
                    ) {
                        revert Errors.InvalidArguments();
                    }
                    v.borrowAmountInUsd += (a.borrowAmount * price) / 10 ** decimals;
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Decline request if not enough collateral
        if (v.maxBorrowAmountInUsd < v.borrowAmountInUsd) {
            revert Errors.NotEnoughCollateral();
        }
    }

    function checkWithdrawalAllowed(DataTypes.HubWithdrawal memory a) public {
        DataTypes.WithdrawalLocalVars memory v;

        PikeToken pikeToken = PikeToken(hub.getPikeToken(a.targetChainId, a.assetToken));

        /// @dev Checking if the target chain has enough funds for starters
        /// @notice We skip USDC since we enable CCTP for spokes without reserves
        if (
            a.assetType != DataTypes.Asset.USDC
                && (
                    a.withdrawAmount > pikeToken.balanceOf(a.user)
                        || a.withdrawAmount > pikeToken.totalLiquidity()
                )
        ) {
            revert Errors.ReserveNotEnough();
        } else if (
            a.assetType == DataTypes.Asset.USDC
                && a.withdrawAmount > pikeToken.totalLiquidity()
        ) {
            revert Errors.ReserveNotEnough();
        }

        /// @dev Calculate the user's total collateral AFTER the withdrawal
        v.numChains = hub.getChainsLength();
        for (uint16 i; i < v.numChains;) {
            uint16 chain = hub.chains(i);
            (uint16 chainLength, address[] memory arrayTokens) =
                hub.getChainTokensData(chain);

            for (uint16 j; j < chainLength;) {
                (uint256 price, uint256 decimals) =
                    pikeOracle.getAssetPrice(chain, arrayTokens[j]);
                if (price <= 0) revert Errors.NegativePriceFound();

                PikeToken pToken = PikeToken(hub.getPikeToken(chain, arrayTokens[j]));
                pToken.accrueInterestsForToken();

                // Skipping chains where user hasn't supplied any collateral
                if (pToken.balanceOf(a.user) > 0) {
                    v.exchangeRate = pToken.exchangeRateStored();
                    uint256 collateral = mul(v.exchangeRate, pToken.balanceOf(a.user));
                    v.totalCollateralUsd += collateral * price / 10 ** decimals;
                }

                // Skipping chains where user hasn't borrowed any assets
                DataTypes.BorrowSnapshot memory b = pToken.getUserBorrows(a.user);
                if (b.principal > 0) {
                    uint256 accruedBorrow = pToken.borrowBalanceStored(a.user);
                    v.totalBorrowsUsd += accruedBorrow * price / 10 ** decimals;
                }

                if (chain == a.targetChainId && arrayTokens[j] == a.assetToken) {
                    /// @dev revert if mint is requested for non-USDC assets
                    if (a.assetType != DataTypes.Asset.USDC && a.usdcMintRequired) {
                        revert Errors.InvalidArguments();
                    }
                    /// @dev revert if mint is requested and enough funds
                    /// @dev revert if mint is not requested and not enough funds
                    if (
                        a.assetType == DataTypes.Asset.USDC
                            && (
                                (
                                    pToken.totalLiquidity() >= a.withdrawAmount
                                        && a.usdcMintRequired
                                )
                                    || (
                                        pToken.totalLiquidity() < a.withdrawAmount
                                            && !a.usdcMintRequired
                                    )
                            )
                    ) {
                        revert Errors.InvalidArguments();
                    }
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        if (v.totalCollateralUsd == 0) revert Errors.ZeroValueNotValid();

        /// @dev Finally, we subtract the withdrawal amount
        (uint256 chainPrice, uint256 chainDecimals) =
            pikeOracle.getAssetPrice(a.targetChainId, a.assetToken);

        if (v.totalCollateralUsd < a.withdrawAmount * chainPrice / 10 ** chainDecimals) {
            revert Errors.NotEnoughCollateral();
        }
        v.totalCollateralUsd -= a.withdrawAmount * chainPrice / 10 ** chainDecimals;

        // Decline request if LTV exceeds allowed in Risk Engine
        if (
            v.totalBorrowsUsd > 0
                && (
                    v.totalCollateralUsd == 0
                        || v.totalBorrowsUsd * DECIMALS / v.totalCollateralUsd
                            > maxLTVs[a.targetChainId][a.assetToken]
                )
        ) {
            revert Errors.LtvExceedsMaxAllowed();
        }
    }
}
