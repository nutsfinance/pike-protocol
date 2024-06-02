// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IPikeOracle} from "../oracle/interfaces/IPikeOracle.sol";
import {IPikeOracleGetter} from "../oracle/interfaces/IPikeOracleGetter.sol";
import {Errors} from "@utils/Errors.sol";

contract PikePriceOracle is IPikeOracle, Initializable, UUPSUpgradeable {
    /// TODO evaluate if we need fallback feeds if the main fails
    /// @dev chainId => oracle => feed
    mapping(uint16 => mapping(address => IPikeOracleGetter)) private oracleGetters;
    mapping(uint16 => address) private pythOracles;

    address public admin;

    // Larger storage gap for future upgrades and inherited contracts
    uint256[50] private __gap;

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

    function initialize(
        uint16 chainId,
        address pythGetter,
        address pythOracle
    )
        public
        initializer
    {
        __UUPSUpgradeable_init();
        admin = msg.sender;
        oracleGetters[chainId][pythOracle] = IPikeOracleGetter(pythGetter);
        pythOracles[chainId] = pythOracle;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getAssetPrice(
        uint16 chainId,
        address tokenAddress
    )
        external
        view
        returns (uint256 price, uint256 decimals)
    {
        IPikeOracleGetter priceFeed = oracleGetters[chainId][pythOracles[chainId]];
        if (address(priceFeed) == address(0)) {
            revert Errors.NoPriceFeed();
        }

        (price, decimals) = priceFeed.getAssetPrice(chainId, tokenAddress);
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
            oracleGetters[chainIds[i]][oracles[i]] = IPikeOracleGetter(getters[i]);
            pythOracles[chainIds[i]] = oracles[i];
            emit PrimaryFeedUpdated(
                chainIds[i], oracles[i], address(oracleGetters[chainIds[i]][oracles[i]])
            );
            unchecked {
                ++i;
            }
        }
    }
}
