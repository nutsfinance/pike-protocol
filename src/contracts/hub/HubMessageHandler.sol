// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuardUpgradeable} from
    "@oz-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Operations} from "../libraries/Operations.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {HubEvents} from "./HubEvents.sol";
import {PikeToken} from "./pikeToken/PikeToken.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {HubModifiers} from "./HubModifiers.sol";
import {HubInternals} from "./HubInternals.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract HubMessageHandler is
    HubModifiers,
    HubEvents,
    HubInternals,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Processes a deposit from a user on a specific chain
     * @dev This function is only callable by an authorized gateway and channels
     * Updates the total deposits, total liquidity, and the user's collateral balance
     * Updates the interest rates based on the new total liquidity
     * @param a Arguments containing the details of the deposit, including the source
     * chain ID, the user's address, the previous amount of the user's collateral, the
     * amount deposited, and the token used for the deposit
     * @ param sourceAddress The address of the authorized channel, encoded as a bytes32
     */
    function processDeposit(
        DataTypes.HubDeposit memory a,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedGateway
        onlyAuthorizedChannels(sourceAddress)
        nonReentrant
        whenNotPaused
    {
        if (markets[a.sourceChainId][a.assetToken].isPaused) {
            revert Errors.SpokeNotActive();
        }

        PikeToken(pikeTokens[a.sourceChainId][a.assetToken]).processDeposit(a);

        emit PikeDepositActionProcessed(
            a.sourceChainId,
            a.assetType,
            a.user,
            a.nonce,
            block.timestamp,
            a.assetToken,
            a.amountDeposited
        );
    }

    /**
     * @notice Processes a borrow request from a user
     * @dev Checks if the user has enough collateral, updates borrows and total borrows,
     *      updates interest rates, emits a PikeBorrowActionProcessed event, and forwards
     *      the borrow request to the target chain via the wormhole relayer
     * @param a Arguments containing the details of the borrow request
     */
    function processBorrow(
        DataTypes.HubBorrow memory a,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedGateway
        onlyAuthorizedChannels(sourceAddress)
        nonReentrant
        whenNotPaused
    {
        /// @dev precision normalization needed for USDC only
        /// @notice in checkBorrowAllowed we compare a.borrowAmount with
        /// v.maxBorrowAmountInUsdc which is inherently 10^18
        a.borrowAmount = Operations.normalize(a.assetType, a.borrowAmount);

        riskEngine.checkBorrowAllowed(a);

        PikeToken(pikeTokens[a.targetChainId][a.assetToken]).processBorrow(a);

        a.borrowAmount = Operations.denormalize(a.assetType, a.borrowAmount);

        uint256 _nonce = nonce++;
        emit PikeBorrowActionProcessed(
            a.targetChainId,
            a.assetType,
            a.user,
            _nonce,
            block.timestamp,
            a.assetToken,
            a.usdcMintRequired,
            a.borrowAmount
        );

        intraGateway.pike_send{value: msg.value}(
            Operations.getTransport(hubChainId, a.targetChainId),
            a.targetChainId,
            abi.encode(
                DataTypes.SpokeBorrowForward({
                    action: a.usdcMintRequired
                        ? DataTypes.Action.SPOKE_BORROW_USDC_FORWARD
                        : DataTypes.Action.SPOKE_BORROW_FORWARD,
                    nonce: _nonce,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.user,
                    assetToken: a.assetToken,
                    borrowAmount: a.borrowAmount,
                    usdcMintRequired: a.usdcMintRequired,
                    targetAddress: a.targetAddress,
                    sourceChainId: a.sourceChainId,
                    targetChainId: a.targetChainId,
                    cctpTargetChainId: a.cctpTargetChainId
                })
            ),
            a.forwardCost
        );
    }

    /**
     * @notice Processes a user's repay request, updating balances and interest rates
     * @param a Arguments for the repay request, including target chain and user
     */
    function processRepay(
        DataTypes.HubRepay memory a,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedGateway
        onlyAuthorizedChannels(sourceAddress)
        nonReentrant
        whenNotPaused
    {
        DataTypes.RepayLocalVars memory v;

        if (
            a.assetType == DataTypes.Asset.USDC
                || (a.sourceChainId == a.targetChainId && a.sourceToken == a.targetToken)
        ) {
            v.convertedRepayAmount = a.repaidAmount;
        } else {
            v.convertedRepayAmount = performIndirectQuoting(
                a.repaidAmount,
                a.sourceChainId,
                a.sourceToken,
                a.targetChainId,
                a.targetToken
            );
        }

        if (a.assetType == DataTypes.Asset.USDC) {
            /// @dev precision normalization needed for USDC only
            v.convertedRepayAmount =
                Operations.normalize(a.assetType, v.convertedRepayAmount);

            v.numChains = uint16(chains.length);
            for (uint16 i; i < v.numChains; i++) {
                if (chains[i] == a.targetChainId) {
                    v.targetChainIndex = i;
                    break;
                }
            }

            for (
                /// @dev Iterate over chains starting from target chain
                uint16 j = v.targetChainIndex;
                j < v.targetChainIndex + v.numChains && v.convertedRepayAmount > 0;
                j++
            ) {
                /// @dev Modulo to wrap around
                uint16 i = j % v.numChains;
                /// @dev get the second token in config
                if (chainTokens[chains[i]].length < 2) {
                    revert Errors.InvalidParamsLength();
                }
                /// @dev Tokens order is guaranteed, USDC is 2nd element in array
                address usdc = chainTokens[chains[i]][1];

                PikeToken pToken = PikeToken(pikeTokens[chains[i]][usdc]);

                /// @dev skip chains where a user has no borrows
                (uint256 principal,) = pToken.userBorrows(a.user);
                if (principal == 0) continue;

                v.repayForThisChain = pToken.processRepay(a, v.convertedRepayAmount);

                v.convertedRepayAmount -= v.repayForThisChain;

                /// @dev Denormalizing back to 6 decimals for event emitting
                v.repayForThisChain =
                    Operations.denormalize(a.assetType, v.repayForThisChain);

                emit PikeRepayActionProcessed(
                    chains[i],
                    a.assetType,
                    a.user,
                    a.sourceChainId,
                    a.nonce,
                    block.timestamp,
                    a.sourceToken,
                    usdc,
                    v.repayForThisChain
                );
            }

            if (v.convertedRepayAmount > 0) {
                PikeToken(pikeTokens[a.sourceChainId][a.sourceToken]).addTokenReserves(
                    v.convertedRepayAmount
                );
            }
        } else {
            PikeToken pToken = PikeToken(pikeTokens[a.targetChainId][a.targetToken]);

            // Revert if user has no open borrows to repay
            (uint256 principal,) = pToken.userBorrows(a.user);
            if (principal == 0) revert Errors.InvalidArguments();

            v.repayForThisChain = pToken.processRepay(a, v.convertedRepayAmount);

            emit PikeRepayActionProcessed(
                a.targetChainId,
                a.assetType,
                a.user,
                a.sourceChainId,
                a.nonce,
                block.timestamp,
                a.sourceToken,
                a.targetToken,
                v.repayForThisChain
            );
        }
    }

    /**
     * @notice Processes a user's withdrawal request, ensuring they have enough collateral
     * @dev This function checks if the user has enough collateral left after the
     * withdrawal to cover their current borrows. It then updates the user's collateral
     * balance, total deposits, total liquidity, and interest rates
     * Then forwards the withdrawal confirmation to the target chain via the Wormhole
     * @param a Arguments including the user, withdrawal amount
     */
    function processWithdrawal(
        DataTypes.HubWithdrawal memory a,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedGateway
        onlyAuthorizedChannels(sourceAddress)
        nonReentrant
        whenNotPaused
    {
        DataTypes.WithdrawalLocalVars memory v;
        /// @dev precision normalization needed for USDC only
        /// @notice in checkWithdrawalAllowed we also compare inputs with
        /// 10^18 values contained in PikeTokens
        a.withdrawAmount = Operations.normalize(a.assetType, a.withdrawAmount);

        riskEngine.checkWithdrawalAllowed(a);

        v.nonce = nonce++;
        v.withdrawTotal = a.withdrawAmount;
        if (a.assetType == DataTypes.Asset.USDC) {
            v.numChains = uint16(chains.length);
            for (uint16 i; i < v.numChains; i++) {
                if (chains[i] == a.targetChainId) {
                    v.targetChainIndex = i;
                    break;
                }
            }

            for (
                /// @dev Iterate over chains starting from target chain
                uint16 j = v.targetChainIndex;
                j < v.targetChainIndex + v.numChains && v.withdrawTotal > 0;
                j++
            ) {
                /// @dev Modulo to wrap around
                uint16 i = j % v.numChains;
                /// @dev get the second token in config
                if (chainTokens[chains[i]].length < 2) {
                    revert Errors.InvalidParamsLength();
                }
                /// @dev Tokens order is guaranteed, USDC is 2nd element in array
                address usdc = chainTokens[chains[i]][1];

                PikeToken pToken = PikeToken(pikeTokens[chains[i]][usdc]);

                /// @dev skip chains where a user has no deposits
                if (pToken.balanceOf(a.user) == 0) continue;

                v.withdrawFromThisChain = pToken.processWithdrawal(a, v.withdrawTotal);

                /// @dev Denormalizing back to 6 decimals for event emitting
                emit PikeWithdrawalActionProcessed(
                    a.targetChainId,
                    a.assetType,
                    a.user,
                    v.nonce,
                    block.timestamp,
                    a.assetToken,
                    Operations.denormalize(a.assetType, v.withdrawFromThisChain),
                    a.usdcMintRequired
                );

                v.withdrawTotal -= v.withdrawFromThisChain;
            }
        } else {
            PikeToken pToken = PikeToken(pikeTokens[a.targetChainId][a.assetToken]);

            v.withdrawFromThisChain = pToken.processWithdrawal(a, a.withdrawAmount);

            emit PikeWithdrawalActionProcessed(
                a.targetChainId,
                a.assetType,
                a.user,
                v.nonce,
                block.timestamp,
                a.assetToken,
                v.withdrawFromThisChain,
                a.usdcMintRequired
            );
        }

        intraGateway.pike_send{value: msg.value}(
            Operations.getTransport(hubChainId, a.targetChainId),
            a.targetChainId,
            abi.encode(
                DataTypes.SpokeWithdrawalForward({
                    action: a.usdcMintRequired
                        ? DataTypes.Action.SPOKE_WITHDRAWAL_USDC_FORWARD
                        : DataTypes.Action.SPOKE_WITHDRAWAL_FORWARD,
                    nonce: v.nonce,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.user,
                    assetToken: a.assetToken,
                    withdrawAmount: Operations.denormalize(a.assetType, a.withdrawAmount),
                    usdcMintRequired: a.usdcMintRequired,
                    sourceChainId: a.sourceChainId,
                    targetChainId: a.targetChainId,
                    cctpTargetChainId: a.cctpTargetChainId
                })
            ),
            a.forwardCost
        );
    }

    /**
     * @notice Initiates a liquidation process for a user's position
     * @dev This function is only callable by an authorized gateway
     * @param a Arguments containing details about the liquidation
     * Calculates the maximum liquidatable amount, applies discounts and penalties,
     * updates the user's borrow balance, total borrows, and protocol reserves,
     * then sends a message to the spoke contract to transfer the sold collateral
     */
    function processLiquidation(
        DataTypes.HubLiquidate memory a,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedGateway
        onlyAuthorizedChannels(sourceAddress)
        nonReentrant
        whenNotPaused
    {
        if (a.user == a.liquidator || a.repayAmount == 0) {
            revert Errors.InvalidArguments();
        }

        (uint256 discount, uint256 penalty) =
            PikeToken(pikeTokens[a.sourceChainId][a.sourceToken]).processLiquidation(a);

        uint256 _nonce = nonce++;
        emit PikeLiquidationActionProcessed(
            a.targetChainId,
            a.assetType,
            a.user,
            _nonce,
            block.timestamp,
            a.sourceToken,
            a.targetToken,
            a.liquidator,
            a.repayAmount,
            a.usdcMintRequired,
            discount,
            penalty
        );

        intraGateway.pike_send{value: msg.value}(
            Operations.getTransport(hubChainId, a.sourceChainId),
            a.sourceChainId,
            abi.encode(
                DataTypes.SpokeLiquidateForward({
                    action: DataTypes.Action.SPOKE_LIQUIDATE_FORWARD,
                    nonce: _nonce,
                    assetType: a.assetType,
                    transport: a.transport,
                    user: a.user,
                    sourceToken: a.sourceToken,
                    targetToken: a.targetToken,
                    liquidator: a.liquidator,
                    totalDiscounted: discount,
                    seizedShare: penalty,
                    sourceChainId: a.sourceChainId,
                    targetChainId: a.targetChainId
                })
            ),
            a.forwardCost
        );
    }
}
