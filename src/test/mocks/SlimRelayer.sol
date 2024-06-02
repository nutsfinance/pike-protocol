// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import "@gateway/channels/wormhole/interfaces/IWormholeRelayer.sol";
import "@gateway/channels/wormhole/interfaces/IWormholeReceiver.sol";

/**
 * @notice Taken from here
 * https://github.com/wormhole-foundation/wormhole/tree/1a50de38e5dca6f8f254998e843285f61a7d32f2/ethereum/contracts/relayer/wormholeRelayer
 */
contract SlimRelayer {
    uint16 public constant chainId = 30;

    uint64 public sequence_ = 0;

    constructor() {}

    PackedDelivery[] public pendingDeliveries;

    struct PackedDelivery {
        uint16 targetChain;
        address targetAddress;
        uint256 receiverValue;
        uint256 gasLimit;
        bytes payload;
        bytes[] additionalVaas;
        bytes32 sourceAddress;
        uint16 sourceChain;
        bytes32 deliveryHash;
    }

    function performRecordedDeliveryFiFo() public {
        PackedDelivery memory delivery = pendingDeliveries[0];
        IWormholeReceiver(delivery.targetAddress).receiveWormholeMessages(
            delivery.payload,
            delivery.additionalVaas,
            delivery.sourceAddress,
            delivery.sourceChain,
            delivery.deliveryHash
        );
        delete pendingDeliveries[0];
        for (uint256 i = 1; i < pendingDeliveries.length; i++) {
            pendingDeliveries[i - 1] = pendingDeliveries[i];
        }
        pendingDeliveries.pop();
    }

    function performRecordedDeliveries() public {
        for (uint256 i = 0; i < pendingDeliveries.length; i++) {
            PackedDelivery memory delivery = pendingDeliveries[i];
            IWormholeReceiver(delivery.targetAddress).receiveWormholeMessages{
                value: delivery.receiverValue
            }(
                delivery.payload,
                delivery.additionalVaas,
                delivery.sourceAddress,
                delivery.sourceChain,
                delivery.deliveryHash
            );
        }
        delete pendingDeliveries;
    }

    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    )
        public
        payable
        returns (uint64 sequence)
    {
        pendingDeliveries.push(
            PackedDelivery({
                targetChain: targetChain,
                targetAddress: targetAddress,
                receiverValue: receiverValue,
                gasLimit: gasLimit,
                payload: payload,
                additionalVaas: new bytes[](0),
                sourceAddress: toWormholeFormat(msg.sender),
                sourceChain: chainId,
                deliveryHash: bytes32(0)
            })
        );
        // not the real calculation, but good enough for testing
        pendingDeliveries[pendingDeliveries.length - 1].deliveryHash =
            keccak256(abi.encode(pendingDeliveries[pendingDeliveries.length - 1]));
        return sequence_++;
    }

    function quoteEVMDeliveryPrice(
        uint16, // targetChain,
        uint256 receiverValue,
        uint256 gasLimit
    )
        public
        pure
        returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused)
    {
        return (1e16 + receiverValue + gasLimit * 5e10, 5e10);
    }

    function forwardPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    )
        public
        payable
    {
        sendPayloadToEvm(targetChain, targetAddress, payload, receiverValue, gasLimit);
    }

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256, // paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16, // refundChain,
        address, // refundAddress,
        address, // deliveryProviderAddress,
        VaaKey[] memory, // vaaKeys,
        uint8 // consistencyLevel
    )
        external
        payable
        returns (uint64 sequence)
    {
        return
            sendPayloadToEvm(targetChain, targetAddress, payload, receiverValue, gasLimit);
    }

    function toWormholeFormat(address addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function getDefaultDeliveryProvider()
        external
        pure
        returns (address deliveryProvider)
    {
        return address(0);
    }

    receive() external payable {}
}
