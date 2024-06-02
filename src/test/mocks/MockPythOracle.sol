// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MockPyth} from "@pyth-network/MockPyth.sol";
import {PythStructs} from "@pyth-network/PythStructs.sol";

contract MockPythOracle is MockPyth {
    constructor(
        uint256 _validTimePeriod,
        uint256 _singleUpdateFeeInWei
    )
        MockPyth(_validTimePeriod, _singleUpdateFeeInWei)
    {}
}
