// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import {IPikeOracleGetter} from "./IMockPythGetter.sol";
import {IPyth} from "@pyth-network/IPyth.sol";

import {MockPyth} from "@pyth-network/MockPyth.sol";
import {PythStructs} from "@pyth-network/PythStructs.sol";
import {Errors} from "@utils/Errors.sol";

contract PythFeedGetter is IPikeOracleGetter {
    address public admin;
    MockPyth public pyth;
    mapping(address => PythStructs.PriceFeed) priceParams;
    mapping(address => bytes32) priceIds;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Errors.CallerNotAuthorized();
        }
        _;
    }

    constructor(address pythAddress, bytes32 priceId, int64 price) {
        admin = msg.sender;
        pyth = MockPyth(pythAddress);
        priceIds[pythAddress] = priceId;
        PythStructs.Price memory priceStruct = PythStructs.Price({
            price: price,
            conf: 1,
            expo: 6,
            publishTime: uint64(block.timestamp)
        });
        priceParams[pythAddress] = PythStructs.PriceFeed({
            id: priceId,
            price: priceStruct,
            // Latest exponentially-weighted moving average price
            emaPrice: priceStruct
        });
    }

    function getAssetPrice(
        /// @param pythAddress Pyth oracle instance address
        address pythAddress
    )
        external
        view
        returns (int64, int32)
    {
        PythStructs.Price memory result = pyth.getPrice(priceIds[pythAddress]);
        return (result.price, result.expo);
    }

    function getPythFee(bytes[] memory data) public view returns (uint256 fee) {
        fee = pyth.getUpdateFee(data);
    }

    function addPriceFeed() public {
        bytes[] memory data = new bytes[](1);
        bytes memory feed = pyth.createPriceFeedUpdateData(
            bytes32("OP/USD price feed"),
            int64(14e5), // 1.4 USD
            uint64(1),
            int32(6),
            int64(1),
            uint64(1),
            uint64(1)
        );
        data[0] = feed;
        pyth.updatePriceFeeds(data);
    }

    function mockCreatePriceFeedUpdate(
        bytes32 priceId,
        PythStructs.PriceFeed memory priceData
    )
        internal
        view
        returns (bytes[] memory priceUpdateDataArray)
    {
        priceUpdateDataArray = new bytes[](1);

        // A price with uncertainty, represented as a price +- a confidence interval
        bytes memory priceUpdate = pyth.createPriceFeedUpdateData(
            priceId,
            priceData.price.price,
            priceData.price.conf,
            priceData.price.expo,
            priceData.emaPrice.price,
            priceData.emaPrice.conf,
            uint64(priceData.price.publishTime)
        );

        priceUpdateDataArray[0] = priceUpdate;
    }

    function updatePriceParams(
        address getter,
        int64 price,
        uint64 conf,
        int32 expo,
        uint256 publishTime
    )
        external
        onlyAdmin
    {
        bytes32 priceId = priceIds[getter];
        PythStructs.Price memory priceStruct = PythStructs.Price({
            price: price,
            conf: conf,
            expo: expo,
            publishTime: publishTime
        });
        priceParams[getter] = PythStructs.PriceFeed({
            id: priceId,
            price: priceStruct,
            // Latest exponentially-weighted moving average price
            emaPrice: priceStruct
        });
    }
}
