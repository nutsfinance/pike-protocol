// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {HubMessageHandler} from "./HubMessageHandler.sol";

/// @custom:oz-upgrades
contract Hub is HubMessageHandler {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint16 chainId,
        uint256 _initialExchangeRate
    )
        public
        initializer
    {
        __UUPSUpgradeable_init();
        admin = msg.sender;
        hubChainId = chainId;
        initialExchangeRate = _initialExchangeRate;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getAccountSnapshot(address user)
        external
        view
        returns (uint256[][][] memory)
    {
        uint16 numChains = uint16(chains.length);
        uint256[][][] memory tokenSnapshots = new uint256[][][](numChains);

        for (uint16 i; i < numChains;) {
            uint16 tokensLength = uint16(chainTokens[chains[i]].length);
            address[] memory arrayTokens = chainTokens[chains[i]];
            tokenSnapshots[i] = new uint256[][](tokensLength);

            for (uint16 j; j < tokensLength;) {
                uint256[] memory tempArray = new uint256[](5);

                PikeToken pikeToken = PikeToken(pikeTokens[chains[i]][arrayTokens[j]]);

                tempArray[0] = uint256(chains[i]);
                tempArray[1] =
                    mul(pikeToken.balanceOf(user), pikeToken.exchangeRateStored());
                tempArray[2] = pikeToken.balanceOf(user);
                tempArray[3] = pikeToken.borrowBalanceStored(user);
                tempArray[4] = pikeToken.exchangeRateStored();

                tokenSnapshots[i][j] = tempArray;

                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return tokenSnapshots;
    }

    function getAccountChainSnapshot(
        uint16 chainId,
        address token,
        address user
    )
        external
        view
        onlyValidChains(chainId, token)
        returns (uint256 tokensBalance, uint256 borrowBalance, uint256 exchangeRate)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        tokensBalance = pikeToken.balanceOf(user);
        borrowBalance = pikeToken.borrowBalanceStored(user);
        exchangeRate = pikeToken.exchangeRateStored();
    }

    /**
     * @notice Returns the total amount borrowed on a specific chain
     * @param chainId ID of the chain to get total borrows from
     * @return The total amount borrowed on the specified chain
     */
    function getTotalBorrows(
        uint16 chainId,
        address token
    )
        external
        view
        onlyValidChains(chainId, token)
        returns (uint16, address, uint256)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        return (chainId, token, pikeToken.totalBorrows());
    }

    /**
     * @notice Returns the total liquidity for a specific chain
     * @param chainId ID of the chain to get the liquidity for
     * @return The total liquidity for the specified chain
     */
    function getTotalLiquidity(
        uint16 chainId,
        address token
    )
        external
        view
        onlyValidChains(chainId, token)
        returns (uint16, address, uint256)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        return (chainId, token, pikeToken.totalLiquidity());
    }

    /**
     * @notice Returns the total reserves for a specific chain
     * @param chainId ID of the chain to get reserves for
     * @return The total amount of reserves for the given chain
     */
    function getTotalReserves(
        uint16 chainId,
        address token
    )
        external
        view
        onlyValidChains(chainId, token)
        returns (uint16, address, uint256)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        return (chainId, token, pikeToken.totalReserves());
    }

    /**
     * @notice Returns the total supply of the Pike token for a given chain
     * @param chainId ID of the chain for which to get the total supply
     * @return The total supply of the Pike token on the specified chain
     */
    function getPikeTokenTotalSupply(
        uint16 chainId,
        address token
    )
        external
        view
        onlyValidChains(chainId, token)
        returns (uint16, address, uint256)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        return (chainId, token, pikeToken.totalSupply());
    }

    /**
     * @notice Returns the current exchange rate for a specific chain
     * @param chainId ID of the chain for which to get the exchange rate
     * @return The current exchange rate for the specified chain
     */
    function getCurrentExchangeRate(
        uint16 chainId,
        address token
    )
        external
        view
        returns (uint16, address, uint256)
    {
        PikeToken pikeToken = PikeToken(pikeTokens[chainId][token]);
        return (chainId, token, pikeToken.exchangeRateStored());
    }
}
