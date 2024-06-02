// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";
import {Hub} from "@hub/Hub.sol";

contract MockGateway {
    DataTypes.Transport public channel;
    uint16 public targetChainId;
    bytes public payload;
    uint256 public forwardCost;

    function pike_send(
        DataTypes.Transport _channel,
        uint16 _targetChainId,
        bytes memory _payload,
        uint256 _forwardCost
    )
        external
        payable
    {
        channel = _channel;
        targetChainId = _targetChainId;
        payload = _payload;
        forwardCost = _forwardCost;
    }
}
