// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@types/DataTypes.sol";

interface IChannel {
    function pike_send(
        uint16 targetChainId,
        bytes memory payload,
        uint256 forwardCost
    )
        external
        payable;
}

interface ICctpChannel {
    function pike_send(uint16 targetChainId, uint256 amountToBurn) external;
    function receiveCctpMessage(
        address targetAddress,
        uint256 usdcAmount,
        bytes memory message,
        bytes memory attestation
    )
        external;
}
