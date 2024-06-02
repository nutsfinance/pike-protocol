// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@types/DataTypes.sol";

interface IGateway {
    event MessageSent(
        uint16 targetChainId, bytes payload, uint16 refundChainId, address refundAddress
    );

    event MessageReceived(uint16 sourceChainId, bytes payload, uint8 selector);

    event DepositReceivedOnHub(
        DataTypes.HubDeposit params, bytes32 sourceAddress, uint16 sourceChainId
    );

    event BorrowRequested(
        DataTypes.HubBorrow params, bytes32 sourceAddress, uint16 sourceChainId
    );

    event BorrowForwarded(
        DataTypes.SpokeBorrowForward params, bytes32 sourceAddress, uint16 sourceChainId
    );

    function pike_send(
        DataTypes.Transport channel,
        uint16 targetChainId,
        bytes memory payload,
        uint256 forwardCost
    )
        external
        payable;

    function pike_receive(
        bytes memory payload,
        uint16 sourceChain,
        bytes32 sourceAddress
    )
        external
        payable;
}
