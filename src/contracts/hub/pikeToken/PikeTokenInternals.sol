// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PikeTokenBase} from "./PikeTokenBase.sol";
import {PikeTokenModifiers} from "./PikeTokenModifiers.sol";
import {PikeTokenMath} from "./PikeTokenMath.sol";
import {IInterestRateModel} from "@hub/interest/interfaces/IInterestRateModel.sol";
import {IRiskEngine} from "@hub/collateral/interfaces/IRiskEngine.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract PikeTokenInternals is
    PikeTokenBase,
    PikeTokenMath,
    PikeTokenModifiers
{
    /**
     * @notice Accrues interest before an action for a specific chain
     */
    function accrueInterestsBeforeAction() internal {
        uint256 timeElapsed = block.timestamp - lastUpdatedTimestamp;
        if (timeElapsed == 0) return;

        address irm = hub.interestRateModel();
        address re = hub.riskEngine();
        uint256 ur = IInterestRateModel(irm).getUtilizationRate(chainId, token);
        uint256 borrowRate = IInterestRateModel(irm).calculateVariableBorrowRate(ur);
        uint256 reserveFactor = IRiskEngine(re).getReserveFactor(chainId, token);

        uint256 factor = mul(borrowRate, timeElapsed);
        uint256 accrued = mul(factor, totalBorrows);
        uint256 totalBorrowsNew = accrued + totalBorrows;
        uint256 totalReservesNew = mul_add(accrued, reserveFactor, totalReserves);
        uint256 borrowIndexNew = mul_add(totalBorrowIndex, factor, totalBorrowIndex);

        // Writing values into storage
        totalBorrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;
        lastUpdatedTimestamp = block.timestamp;
    }

    function accrueInterestsForToken() public onlyRiskEngine {
        accrueInterestsBeforeAction();
    }

    function exchangeRateStored() public view returns (uint256 exchangeRate) {
        if (totalSupply() == 0) return hub.initialExchangeRate();

        uint256 totalCash = totalLiquidity;
        uint256 factor = totalCash + totalBorrows - totalReserves;
        exchangeRate = div(factor, totalSupply());
    }

    function borrowBalanceStored(address user)
        public
        view
        returns (uint256 borrowBalance)
    {
        DataTypes.BorrowSnapshot memory borrow = userBorrows[user];
        if (borrow.principal == 0) return 0;

        uint256 accrued = mul(borrow.principal, totalBorrowIndex);
        borrowBalance = div(accrued, borrow.interestIndex);
    }

    function performIndirectQuoting(
        uint256 sourceAmount,
        uint16 sourceChainId,
        address sourceToken,
        uint16 targetChainId,
        address targetToken
    )
        public
        returns (uint256 targetAmount)
    {
        if (sourceAmount == 0) {
            revert Errors.InvalidArguments();
        }
        (uint256 sourcePriceInUsd, uint256 sourceDecimals) =
            pikeOracle.getAssetPrice(sourceChainId, sourceToken);
        (uint256 targetPriceInUsd, uint256 targetDecimals) =
            pikeOracle.getAssetPrice(targetChainId, targetToken);
        if (sourcePriceInUsd <= 0 || targetPriceInUsd <= 0) {
            revert Errors.NegativePriceFound();
        }

        uint256 amountInUsd = sourceAmount * sourcePriceInUsd / 10 ** sourceDecimals;
        targetAmount = amountInUsd * 10 ** targetDecimals / targetPriceInUsd;
    }
}
