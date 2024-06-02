// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IPyth} from "@pyth-network/IPyth.sol";
import {IPikeOracleGetter} from "@hub/oracle/interfaces/IPikeOracleGetter.sol";
import {PythStructs} from "@pyth-network/PythStructs.sol";
import {Errors} from "@utils/Errors.sol";

contract PythGetter is IPikeOracleGetter, Initializable, UUPSUpgradeable {
    address public admin;
    IPyth public pyth;
    uint8 constant DECIMALS = 18;
    uint256 internal priceAgeLimit;
    mapping(uint16 => mapping(address => bytes32)) priceFeeds;

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

    function initialize(address pythAddress) public initializer {
        __UUPSUpgradeable_init();
        admin = msg.sender;
        pyth = IPyth(pythAddress);
        priceAgeLimit = 60;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getAssetPrice(
        uint16 chainId,
        address tokenAddress
    )
        external
        view
        returns (uint256, uint8)
    {
        if (chainId == 0) {
            revert Errors.InvalidArguments();
        }
        bytes32 feed = priceFeeds[chainId][tokenAddress];
        PythStructs.Price memory result = pyth.getPriceNoOlderThan(feed, priceAgeLimit);

        uint256 price = convertToUint(result, DECIMALS);
        if (price < 0) {
            revert Errors.NegativePriceFound();
        }

        return (price, DECIMALS);
    }

    function addPriceFeed(
        uint16 chainId,
        address tokenAddress,
        bytes32 feed
    )
        external
        onlyOwner
    {
        if (chainId == 0 || feed.length == 0) {
            revert Errors.InvalidArguments();
        }
        priceFeeds[chainId][tokenAddress] = feed;
    }

    function setPriceAgeLimit(uint256 newLimit) external onlyOwner {
        if (newLimit == 0) revert Errors.ZeroValueNotValid();
        priceAgeLimit = newLimit;
    }

    function convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    )
        private
        pure
        returns (uint256)
    {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert Errors.InvalidArguments();
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (targetDecimals >= priceDecimals) {
            return uint256(uint64(price.price))
                * 10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return uint256(uint64(price.price))
                / 10 ** uint32(priceDecimals - targetDecimals);
        }
    }
}
