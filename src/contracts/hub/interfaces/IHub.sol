// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from "@types/DataTypes.sol";
import "@utils/Errors.sol";

interface IHub {
    function getTotalBorrows(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256);

    function getTotalLiquidity(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256);

    function getTotalReserves(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256);

    function getPikeTokenTotalSupply(uint16 chainId)
        external
        view
        returns (uint16, address, uint256);

    function getCurrentExchangeRate(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256);

    function addNewChains(uint16[] memory chainIds) external;

    function addNewMarket(
        uint16 chainId,
        address pikeToken,
        uint256 totalSupply,
        string memory name,
        string memory symbol,
        bool isListed,
        bool isPaused,
        uint8 decimals
    )
        external;

    function addChainPikeToken(uint16 chainId, address pikeToken) external;

    function initialExchangeRate() external view returns (uint256);

    function interestRateModel() external view returns (address);

    function riskEngine() external view returns (address);

    // function checkBorrowAllowed(DataTypes.HubBorrow memory a) external;

    // function checkWithdrawalAllowed(DataTypes.HubWithdrawal memory a) external;

    function getHealthFactor(address user) external returns (uint256);

    function chains(uint256) external view returns (uint16);

    function pikeTokens(uint256, address) external view returns (address);

    function getChainTokens(uint16) external view returns (address[] memory);

    function getChainsLength() external view returns (uint16);

    function getChainTokensData(uint16)
        external
        view
        returns (uint16, address[] memory);

    function getPikeToken(uint16, address) external view returns (address);
}
