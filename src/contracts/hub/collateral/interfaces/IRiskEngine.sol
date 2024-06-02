// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

interface IRiskEngine {
    function getRiskParameterSnaphot(
        uint16 chainId,
        address token
    )
        external
        view
        returns (
            uint256 maxLTV,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            uint256 liquidationPenalty,
            uint256 seizeShare,
            uint256 reserveFactor,
            uint256 closeFactor
        );

    function getMaxLTV(uint16 chainId, address token) external view returns (uint256);

    function getLiquidationThreshold(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getLiquidationPenalty(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getLiquidationDiscount(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getReserveFactor(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getSeizeShare(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function getTotalSeizeShare(
        uint256 total,
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint256);

    function setChainLtvRatios(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setChainLtvRatio(uint16 chainId, address token, uint256 value) external;

    function setLiquidationThresholds(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setLiquidationThreshold(
        uint16 chainId,
        address token,
        uint256 value
    )
        external;

    function setLiquidationPenalties(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setLiquidationPenalty(
        uint16 chainId,
        address token,
        uint256 value
    )
        external;

    function setLiquidationDiscounts(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setLiquidationDiscount(
        uint16 chainId,
        address token,
        uint256 value
    )
        external;

    function setReserveFactors(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setReserveFactor(uint16 chainId, address token, uint256 value) external;

    function setSeizeShares(
        uint16[] calldata chainIds,
        address[][] calldata chainTokens,
        uint256[][] calldata values
    )
        external;

    function setSeizeShare(uint16 chainId, address token, uint256 value) external;

    function checkBorrowAllowed(DataTypes.HubBorrow memory a) external;

    function checkWithdrawalAllowed(DataTypes.HubWithdrawal memory a) external;
}
