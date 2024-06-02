// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPikeOracle} from "./IPikeOracle.sol";
import {IPikeOracleGetter} from "./IMockPythGetter.sol";
import {Errors} from "@utils/Errors.sol";
import {ERC20} from "@openzeppelin-pike/token/ERC20/ERC20.sol";
import {PythStructs} from "@pyth-network/PythStructs.sol";

contract PikeOracle is IPikeOracle {
    /// TODO evaluate if we need fallback feeds if the main fails
    /// @dev chainId => asset => oracle
    mapping(uint16 => mapping(address => IPikeOracleGetter)) private feeds;
    mapping(uint16 => address) chainlinkOracles;
    mapping(uint16 => address) pythOracles;

    address public admin;

    modifier onlyOwner() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    constructor(uint16 chainId, address pythGetter, address pythOracle) {
        admin = msg.sender;
        feeds[chainId][pythGetter] = IPikeOracleGetter(pythGetter);
        pythOracles[chainId] = pythOracle;
    }

    function getAssetPrice(
        uint16 chainId,
        address // tokenAddress
    )
        external
        view
        returns (uint256 price, uint256 decimals)
    {
        IPikeOracleGetter priceFeed = feeds[chainId][pythOracles[chainId]];
        if (address(priceFeed) == address(0)) {
            revert Errors.NoPriceFeed();
        }

        (int64 oraclePrice, int32 oracleDecimals) =
            priceFeed.getAssetPrice(pythOracles[chainId]);
        if (oraclePrice < 0) {
            revert Errors.NegativePriceFound();
        }

        price = uint256(uint64(oraclePrice));
        decimals = uint256(uint32(oracleDecimals));
    }

    function setOracleFeeds(
        uint16[] calldata chainIds,
        address[] calldata oracles,
        IPikeOracleGetter[] calldata getters
    )
        public
        onlyOwner
    {
        _setOracleFeeds(chainIds, oracles, getters);
    }

    function _setOracleFeeds(
        uint16[] memory chainIds,
        address[] memory oracles,
        IPikeOracleGetter[] memory getters
    )
        internal
    {
        if (chainIds.length != oracles.length || oracles.length != getters.length) {
            revert Errors.InconsistentParamsLength();
        }

        uint16 assetsLength = uint16(oracles.length);
        for (uint16 i; i < assetsLength;) {
            feeds[chainIds[i]][oracles[i]] = IPikeOracleGetter(getters[i]);
            pythOracles[chainIds[i]] = oracles[i];
            emit PrimaryFeedUpdated(
                chainIds[i], oracles[i], address(feeds[chainIds[i]][oracles[i]])
            );
            unchecked {
                ++i;
            }
        }
    }
}
