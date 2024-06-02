// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {GatewayAdmin} from "./GatewayAdmin.sol";
import {GatewayInternals} from "./GatewayInternals.sol";
import {IHubMessageHandler} from "@hub/interfaces/IHubMessageHandler.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract Gateway is GatewayInternals, GatewayAdmin, Initializable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint16 newChainId, address _hub) public initializer {
        __UUPSUpgradeable_init();
        admin = msg.sender;
        chainId = newChainId;
        hub = IHubMessageHandler(_hub);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Sends a cross-chain message via the specified transport channel
     * @param channel Transport channel to use for sending the message
     * @param targetChainId Wormhole ID of the target chain where the message will be sent
     * @param payload Bytes payload of the message to be sent
     */
    function pike_send(
        DataTypes.Transport channel,
        uint16 targetChainId,
        bytes memory payload,
        uint256 forwardCost
    )
        external
        payable
        onlyAuthorizedChannels
    {
        channels[channel].pike_send{value: msg.value}(targetChainId, payload, forwardCost);
    }

    /**
     * @notice Handles incoming messages from Wormhole and dispatches them
     *         to the appropriate function based on the action type
     * @param data The payload of the message, which includes the action type
     *        and the parameters for the action
     * @param sourceChainId The ID of the source chain where the message originated
     */
    function pike_receive(
        bytes memory data,
        uint16 sourceChainId,
        bytes32 sourceAddress
    )
        external
        payable
        onlyAuthorizedChannels
    {
        if (data.length == 0) {
            revert Errors.ZeroWormholePayload();
        }
        uint8 selector = uint8(data[31]);

        if (selector > 0 && selector <= 3) {
            /// @dev processing deposit-related actions
            processDepositActions(selector, data, sourceAddress);
        } else if (selector > 3 && selector <= 7) {
            /// @dev borrows
            processBorrowActions(selector, data, sourceAddress);
        } else if (selector > 7 && selector <= 10) {
            /// @dev repays
            processRepayActions(selector, data, sourceAddress);
        } else if (selector > 10 && selector <= 14) {
            /// @dev withdrawals
            processWithdrawActions(selector, data, sourceAddress);
        } else if (selector > 14 && selector <= 17) {
            /// @dev liquidations
            processLiquidations(selector, data, sourceAddress);
        } else if (selector == 18) {
            /// @dev declines hub -> spoke
            // processDeclines(selector, data);
        } else {
            // Revert the transaction if the selector is not found or invalid
            revert Errors.InvalidArguments();
        }

        emit MessageReceived(sourceChainId, data, selector);
    }
}
