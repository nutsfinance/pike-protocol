// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IHub} from "@hub/interfaces/IHub.sol";
import {PikePriceOracle} from "@hub/oracle/PikePriceOracle.sol";
import {RiskEngineExternals} from "./RiskEngineExternals.sol";
import {RiskEngineEvents} from "./RiskEngineEvents.sol";
import {Errors} from "@utils/Errors.sol";

contract RiskEngine is
    RiskEngineExternals,
    RiskEngineEvents,
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

    function initialize(address hubAddress, address oracleAddress) public initializer {
        __UUPSUpgradeable_init();
        admin = msg.sender;
        hub = IHub(hubAddress);
        ltvRatioDecimals = 1e18;
        pikeOracle = PikePriceOracle(oracleAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     *
     */
    function getRiskParameterSnaphot(
        uint16 chainId,
        address token
    )
        public
        view
        returns (
            uint256 maxLTV,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            uint256 liquidationPenalty,
            uint256 seizeShare,
            uint256 reserveFactor,
            uint256 closeFactor
        )
    {
        maxLTV = maxLTVs[chainId][token];
        liquidationThreshold = liquidationThresholds[chainId][token];
        liquidationDiscount = liquidationDiscounts[chainId][token];
        liquidationPenalty = liquidationPenalties[chainId][token];
        seizeShare = protocolSeizeShares[chainId][token];
        reserveFactor = reserveFactors[chainId][token];
        closeFactor = closeFactors[chainId][token];
    }

    /**
     * @dev Individual public getters for risk parameters
     * maxLTV
     * liquidationThreshold
     * liquidationPenaltie
     * liquidationDiscount
     * reserveFactor
     * protocolSeizeShare
     */
    function getMaxLTV(uint16 chainId, address token) public view returns (uint256 ltv) {
        ltv = maxLTVs[chainId][token];
    }

    function getLiquidationThreshold(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 threshold = liquidationThresholds[chainId][token];
        return threshold;
    }

    function getLiquidationPenalty(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 penalty = liquidationPenalties[chainId][token];
        return penalty;
    }

    function getLiquidationDiscount(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 discount = liquidationDiscounts[chainId][token];
        return discount;
    }

    function getReserveFactor(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 factor = reserveFactors[chainId][token];
        return factor;
    }

    function getSeizeShare(uint16 chainId, address token) public view returns (uint256) {
        uint256 share = protocolSeizeShares[chainId][token];
        return share;
    }

    function getCloseFactor(
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 factor = closeFactors[chainId][token];
        return factor;
    }

    function getTotalSeizeShare(
        uint256 total,
        uint16 chainId,
        address token
    )
        public
        view
        returns (uint256)
    {
        uint256 seize = protocolSeizeShares[chainId][token];
        uint256 share = total * (1e18 - seize) / 1e18;
        if (share == 0) {
            revert Errors.ZeroValueNotValid();
        }
        return share;
    }

    /**
     * @dev Admin only setters for risk parameters
     * maxLTVs
     * liquidationThresholds
     * liquidationPenalties
     * liquidationDiscounts
     * reserveFactors
     * protocolSeizeShares
     */
    function setChainLtvRatios(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                maxLTVs[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setChainLtvRatio(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        maxLTVs[chainId][token] = value;
        emit ChainLtvRatioUpdated(chainId, value);
    }

    function setLiquidationThresholds(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                liquidationThresholds[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setLiquidationThreshold(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        liquidationThresholds[chainId][token] = value;
        emit ChainLiquidationThresholdUpdated(chainId, value);
    }

    function setLiquidationPenalties(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                liquidationPenalties[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setLiquidationPenalty(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        liquidationPenalties[chainId][token] = value;
        emit ChainLiquidationPenaltyUpdated(chainId, value);
    }

    function setLiquidationDiscounts(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                liquidationDiscounts[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setLiquidationDiscount(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        liquidationDiscounts[chainId][token] = value;
        emit ChainLiquidationDiscountUpdated(chainId, value);
    }

    function setReserveFactors(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                reserveFactors[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setReserveFactor(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        reserveFactors[chainId][token] = value;
        emit ChainReserveFactorUpdated(chainId, value);
    }

    function setSeizeShares(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                protocolSeizeShares[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setSeizeShare(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        protocolSeizeShares[chainId][token] = value;
        emit ChainSeizeShareUpdated(chainId, value);
    }

    function setCloseFactors(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        public
        onlyOwner
    {
        if (chainTokens.length != values.length) {
            revert Errors.InconsistentParamsLength();
        }

        for (uint16 i; i < chainIds.length;) {
            uint16 valuesLength = uint16(values[i].length);
            address[] memory arrayTokens = chainTokens[i];
            uint256[] memory arrayValues = values[i];

            for (uint16 j; j < valuesLength;) {
                closeFactors[chainIds[i]][arrayTokens[j]] = arrayValues[j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setCloseFactor(
        uint16 chainId,
        address token,
        uint256 value
    )
        public
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        closeFactors[chainId][token] = value;
        emit ChainCloseFactorUpdated(chainId, value);
    }

    function setPikeOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        pikeOracle = PikePriceOracle(oracle);
    }
}
