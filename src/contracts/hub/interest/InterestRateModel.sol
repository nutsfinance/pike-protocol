// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IHub} from "@hub/interfaces/IHub.sol";
import {InterestRateModelStorage} from "./InterestRateModelStorage.sol";
import {InterestRateModelEvents} from "./InterestRateModelEvents.sol";
import {IInterestRateModel} from "./interfaces/IInterestRateModel.sol";
import {Errors} from "@utils/Errors.sol";

contract InterestRateModel is
    IInterestRateModel,
    InterestRateModelStorage,
    InterestRateModelEvents,
    Initializable,
    UUPSUpgradeable
{
    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address hubAddress) public initializer {
        __UUPSUpgradeable_init();
        hub = IHub(hubAddress);
        admin = msg.sender;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Returns the utilization rate for a specific chain
     * @param chainId ID of the chain to get the utilization rate for
     * @return The utilization rate, calculated as total borrows / total liquidity
     */
    function getUtilizationRate(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        (,, uint256 borrows) = hub.getTotalBorrows(chainId, token);
        (,, uint256 cash) = hub.getTotalLiquidity(chainId, token);
        (,, uint256 reserves) = hub.getTotalReserves(chainId, token);

        if (borrows == 0) return 0;
        return borrows * DECIMALS / (cash + borrows - reserves);
    }

    /**
     * @notice Calculate the supply rate given utilization rate and borrow rate
     * @param chainId ID of the chain to get the utilization rate for
     * @return The supply rate for the asset
     */
    function getSupplyRate(uint16 chainId, address token) public view returns (uint256) {
        uint256 ur = getUtilizationRate(chainId, token);
        uint256 borrowRate = calculateVariableBorrowRate(ur);
        uint256 factor = borrowRate * (ONE - RESERVE_FACTOR) / DECIMALS;
        return ur * factor / DECIMALS;
    }

    /**
     * @notice Calculates the variable borrow rate based on current utilization
     * @param currentUtilizationRate The current utilization rate of the market
     * @return The calculated variable borrow rate
     * If utilization is below optimal, rate is BASE + UTILIZATION * SLOPE1
     * If utilization is above optimal, rate is BASE + OPTIMAL * SLOPE1
     * + (UTILIZATION - OPTIMAL) * SLOPE2
     */
    function calculateVariableBorrowRate(uint256 currentUtilizationRate)
        public
        pure
        returns (uint256)
    {
        if (currentUtilizationRate <= OPTIMAL_UTILIZATION) {
            return BASE_VARIABLE + currentUtilizationRate * VARIABLE_SLOPE1 / DECIMALS;
        } else {
            return BASE_VARIABLE + OPTIMAL_UTILIZATION * VARIABLE_SLOPE1 / DECIMALS
                + (currentUtilizationRate - OPTIMAL_UTILIZATION) * VARIABLE_SLOPE2 / DECIMALS;
        }
    }

    /**
     * @notice Calculates the stable borrow rate based on the current utilization rate
     * @param currentUtilizationRate The current utilization rate of the market
     * @return variableRate The calculated stable borrow rate
     */
    function calculateStableBorrowRate(uint256 currentUtilizationRate)
        public
        pure
        returns (uint256 variableRate)
    {
        variableRate = calculateVariableBorrowRate(currentUtilizationRate);
        variableRate += BASE_STABLE;
    }

    function getSupplyRates(
        uint16[] calldata chains,
        address[][] calldata chainTokens
    )
        external
        view
        returns (TokenSupplyRate[][] memory)
    {
        uint16 numChains = uint16(chainTokens.length);
        if (numChains == 0) {
            revert Errors.InvalidArguments();
        }

        TokenSupplyRate[][] memory supplyRatesByChain = new TokenSupplyRate[][](numChains);

        for (uint16 i; i < numChains;) {
            address[] memory tokens = chainTokens[i];
            uint16 numTokens = uint16(tokens.length);
            TokenSupplyRate[] memory chainSupplyRates = new TokenSupplyRate[](numTokens);

            for (uint16 j; j < numTokens;) {
                uint256 ur = getUtilizationRate(chains[i], tokens[j]);
                uint256 borrowRate = calculateVariableBorrowRate(ur);
                uint256 factor = borrowRate * (ONE - RESERVE_FACTOR) / DECIMALS;

                TokenSupplyRate memory data;
                data.chainId = chains[i];
                data.tokenAddress = tokens[j];
                data.supplyRate = ur * factor / DECIMALS;
                chainSupplyRates[j] = data;

                unchecked {
                    ++j;
                }
            }
            supplyRatesByChain[i] = chainSupplyRates;

            unchecked {
                ++i;
            }
        }
        return supplyRatesByChain;
    }

    function getBorrowRates(
        uint16[] calldata chains,
        address[][] calldata chainTokens
    )
        external
        view
        returns (TokenBorrowRate[][] memory)
    {
        uint16 numChains = uint16(chainTokens.length);
        if (numChains == 0) {
            revert Errors.InvalidArguments();
        }

        TokenBorrowRate[][] memory borrowRatesByChain = new TokenBorrowRate[][](numChains);

        for (uint16 i; i < numChains;) {
            address[] memory tokens = chainTokens[i];
            uint16 numTokens = uint16(tokens.length);
            TokenBorrowRate[] memory chainBorrowRates = new TokenBorrowRate[](numTokens);

            for (uint16 j; j < numTokens;) {
                uint256 ur = getUtilizationRate(chains[i], tokens[j]);

                TokenBorrowRate memory data;
                data.chainId = chains[i];
                data.tokenAddress = tokens[j];
                data.borrowRate = calculateVariableBorrowRate(ur);
                chainBorrowRates[j] = data;

                unchecked {
                    ++j;
                }
            }
            borrowRatesByChain[i] = chainBorrowRates;

            unchecked {
                ++i;
            }
        }
        return borrowRatesByChain;
    }
}
