// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {HubAdmin} from "./HubAdmin.sol";
import {HubMath} from "./HubMath.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract HubInternals is
    HubMath,
    HubAdmin,
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    function getHealthFactor(address user) public returns (uint256 healthFactor) {
        if (user == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }

        uint256 totalCollateralUsd;
        uint256 totalBorrowUsd;

        /// @notice Iterate over the chains
        uint16 chainsLength = uint16(chains.length);
        for (uint16 i; i < chainsLength;) {
            uint16 chainLength = uint16(chainTokens[chains[i]].length);
            address[] memory arrayTokens = chainTokens[chains[i]];

            for (uint16 j; j < chainLength;) {
                PikeToken pikeToken = PikeToken(pikeTokens[chains[i]][arrayTokens[j]]);
                uint256 tokensBalance = pikeToken.balanceOf(user);
                uint256 borrowBalance = pikeToken.borrowBalanceStored(user);
                uint256 er = pikeToken.exchangeRateStored();
                (uint256 price, uint256 decimals) =
                    pikeOracle.getAssetPrice(chains[i], arrayTokens[j]);

                uint256 risk =
                    mul(er, riskEngine.getLiquidationThreshold(chains[i], arrayTokens[j]));
                uint256 tokenUnitPrice = price * risk / 10 ** decimals;

                totalCollateralUsd += mul(tokensBalance, tokenUnitPrice);
                totalBorrowUsd += borrowBalance * price / 10 ** decimals;

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        if (totalBorrowUsd > 0) {
            healthFactor = div(totalCollateralUsd, totalBorrowUsd);
        } else {
            healthFactor = ~uint256(0);
        }
    }

    function getChainsLength() public view returns (uint16) {
        return uint16(chains.length);
    }

    function getChainTokensData(uint16 chain)
        public
        view
        returns (uint16 length, address[] memory tokenArray)
    {
        length = uint16(chainTokens[chain].length);
        tokenArray = chainTokens[chain];
    }

    function getPikeToken(
        uint16 chain,
        address token
    )
        public
        view
        returns (address pikeToken)
    {
        pikeToken = pikeTokens[chain][token];
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
        if (sourceAmount == 0) revert Errors.InvalidArguments();

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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
