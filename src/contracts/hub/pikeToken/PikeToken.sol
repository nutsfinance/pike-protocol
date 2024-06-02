// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {PikeTokenBase} from "./PikeTokenBase.sol";
import {PikeTokenAdmin} from "./PikeTokenAdmin.sol";
import {IHub} from "@hub/interfaces/IHub.sol";
import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import {IRiskEngine} from "@hub/collateral/interfaces/IRiskEngine.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract PikeToken is Initializable, UUPSUpgradeable, PikeTokenBase, PikeTokenAdmin {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint16 _spokeChainId,
        address hubAddress,
        address riskEngineAddress,
        address pikeOracleAddress
    )
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __ERC20Pausable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        isActive = true;
        spokeChainId = _spokeChainId;
        hub = IHub(hubAddress);
        riskEngine = IRiskEngine(riskEngineAddress);
        pikeOracle = IPikeOracle(pikeOracleAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function processDeposit(DataTypes.HubDeposit memory a)
        public
        onlyActiveChain
        onlyMintAuthority
        normalizeDeposits(a)
    {
        // Accruing the compounded interests before action
        accrueInterestsBeforeAction();

        uint256 exchangeRate = exchangeRateStored();
        uint256 tokensToMint = div(a.amountDeposited, exchangeRate);

        if (totalSupply() == 0) {
            mint(PLACEHOLDER_ADDRESS, MIN_LIQUIDITY);
            tokensToMint = div(a.amountDeposited, exchangeRate) - MIN_LIQUIDITY;
        }

        /// @dev Token-wide updates
        totalLiquidity += a.amountDeposited;

        mint(a.user, tokensToMint);
    }

    function processBorrow(DataTypes.HubBorrow memory a)
        public
        onlyActiveChain
        onlyMintAuthority
    {
        // Redundant call accrueInterestsBeforeAction();

        /// @dev Checking if the target chain has enough funds for starters
        if (a.targetChainId == spokeChainId && a.borrowAmount > totalLiquidity) {
            revert Errors.ReserveNotEnough();
        }

        /// @dev User-specific updates
        userBorrows[a.user].principal += borrowBalanceStored(a.user) + a.borrowAmount;
        userBorrows[a.user].interestIndex = totalBorrowIndex;

        /// @dev No chain-specific updates
        /// @dev Protocol-wide updates
        totalBorrows += a.borrowAmount;
        totalLiquidity -= a.borrowAmount;
    }

    function processRepay(
        DataTypes.HubRepay memory a,
        uint256 convertedRepayAmount
    )
        public
        onlyActiveChain
        onlyMintAuthority
        returns (uint256 repayForThisChain)
    {
        // Accruing the compounded interests before action
        accrueInterestsBeforeAction();

        DataTypes.BorrowSnapshot memory b = userBorrows[a.user];

        if (a.fullRepayment) {
            /// @dev we add accrued interests for full repays
            uint256 fullRepay = borrowBalanceStored(a.user);
            if (fullRepay > convertedRepayAmount) revert Errors.InvalidArguments();

            repayForThisChain = fullRepay;
            userBorrows[a.user].principal = 0;
            totalBorrows -= b.principal;
            totalLiquidity += fullRepay;
        } else {
            repayForThisChain =
                convertedRepayAmount > b.principal ? b.principal : convertedRepayAmount;
            userBorrows[a.user].principal =
                borrowBalanceStored(a.user) - repayForThisChain;
            totalBorrows -= repayForThisChain;
            totalLiquidity += repayForThisChain;
        }

        /// @dev User-specific updates
        userBorrows[a.user].interestIndex = totalBorrowIndex;

        return repayForThisChain;
    }

    function processWithdrawal(
        DataTypes.HubWithdrawal memory a,
        uint256 withdrawTotal
    )
        external
        onlyActiveChain
        onlyMintAuthority
        returns (uint256)
    {
        DataTypes.WithdrawalLocalVars memory v;

        // Redundant call accrueInterestsBeforeAction();

        v.chainDeposit = mul(balanceOf(a.user), exchangeRateStored());
        v.exchangeRate = exchangeRateStored();

        if (a.fullWithdrawal) {
            v.withdrawFromThisChain = mul(balanceOf(a.user), v.exchangeRate);
            if (v.withdrawFromThisChain > withdrawTotal) {
                revert Errors.InvalidArguments();
            }

            v.tokensToBurn = balanceOf(a.user);
        } else {
            v.withdrawFromThisChain =
                withdrawTotal > v.chainDeposit ? v.chainDeposit : withdrawTotal;

            /// @dev Adjust calculations for shares to explicitly round up
            if (v.withdrawFromThisChain % v.exchangeRate != 0) {
                v.tokensToBurn =
                    div(v.withdrawFromThisChain + v.exchangeRate - 1, v.exchangeRate);
                if (v.tokensToBurn > balanceOf(a.user)) {
                    v.tokensToBurn = balanceOf(a.user);
                }
            } else {
                v.tokensToBurn = div(v.withdrawFromThisChain, v.exchangeRate);
            }
        }

        /// @dev User and token-specific updates
        totalLiquidity -= v.withdrawFromThisChain;

        burn(a.user, v.tokensToBurn);

        return v.withdrawFromThisChain;
    }

    function processLiquidation(DataTypes.HubLiquidate memory a)
        public
        onlyActiveChain
        onlyMintAuthority
        normalizeRepayments(a)
        returns (uint256, uint256)
    {
        DataTypes.LiquidationLocalVars memory v;

        // Accruing the compounded interests before action
        accrueInterestsBeforeAction();

        (
            , // uint256 maxLTV,
            , // uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            uint256 liquidationPenalty,
            , // uint256 seizeShare,
            , // uint256 reserveFactor,
            uint256 closeFactor
        ) = riskEngine.getRiskParameterSnaphot(a.sourceChainId, a.sourceToken);

        // Maximum amount that the liquidator can liquidate is 70% (closeFactor)
        // The liquidator receives 100 + 10% discount of what he repaid as an incentive
        // Liquidation 5% penalty is sent to the protocol's reserves
        /// @dev We don't add accrued interest when calculating max liquidatable amount
        /// @dev v.maxLiquidatableAmount = mul(mul(balanceOf(a.user), exchangeRateStored()), closeFactor);
        v.maxLiquidatableAmount =
            mul(mul(balanceOf(a.user), exchangeRateStored()), closeFactor);
        v.discount = div(a.repayAmount, DECIMALS - liquidationDiscount);
        v.penalty = mul(a.repayAmount, liquidationPenalty);
        v.exchangeRate = exchangeRateStored();

        // Send the decline response back if conditions are not met
        // Ensure that the total amount does not exceed the max allowed
        if (
            v.maxLiquidatableAmount < v.penalty + v.discount
                || hub.getHealthFactor(a.user) >= DECIMALS
        ) {
            revert Errors.InvalidLiquidationAmount();
        }

        /// @dev User-specific updates
        userBorrows[a.user].principal = borrowBalanceStored(a.user) - a.repayAmount;

        /// @dev No chain-specific updates
        /// @dev Token-wide updates
        totalBorrows -= a.repayAmount;
        totalLiquidity += a.repayAmount - v.penalty;
        totalReserves += v.penalty;

        /// @dev The user here always has more tokens due to closeFactor = 70%
        tokenTransfer(
            a.user, a.liquidator, div(v.discount + v.exchangeRate - 1, v.exchangeRate)
        );
        burn(a.user, div(v.penalty + v.exchangeRate - 1, v.exchangeRate));

        return (v.discount, v.penalty);
    }

    function mint(
        address depositor,
        uint256 depositAmount
    )
        public
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(depositor)
    {
        if (depositAmount == 0) revert Errors.ZeroValueNotValid();

        _mint(depositor, depositAmount);
    }

    function burn(
        address withdrawer,
        uint256 burnAmount
    )
        public
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(withdrawer)
    {
        if (burnAmount == 0) revert Errors.ZeroValueNotValid();

        _burn(withdrawer, burnAmount);
    }

    function safeTransfer(
        address payable user,
        uint256 amount
    )
        public
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(user)
    {
        if (amount == 0) revert Errors.ZeroValueNotValid();

        (bool success,) = payable(user).call{value: amount}("");

        if (!success) revert Errors.AssetTransferFailed();
    }

    function tokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        public
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(from)
        onlyValidAddress(to)
    {
        if (amount == 0) revert Errors.ZeroValueNotValid();

        _transfer(from, to, amount);
    }

    function getUserBorrows(address user)
        public
        view
        returns (DataTypes.BorrowSnapshot memory b)
    {
        return userBorrows[user];
    }

    function addTokenReserves(uint256 reserve) public onlyMintAuthority {
        if (reserve == 0) revert Errors.ZeroValueNotValid();
        totalReserves += reserve;
    }
}
