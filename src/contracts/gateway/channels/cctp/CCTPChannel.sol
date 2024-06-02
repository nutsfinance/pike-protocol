// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IChannel} from "../interfaces/IChannel.sol";
import {CCTPModifiers} from "./CCTPModifiers.sol";
import {ITokenMessenger} from "./interfaces/ITokenMessenger.sol";
import {IMessageTransmitter} from "./interfaces/IMessageTransmitter.sol";
import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";

import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

contract CCTPChannel is IChannel, CCTPModifiers, Initializable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint16 localChainId,
        address messenger,
        address transmitter,
        address usdcAddress
    )
        public
        initializer
    {
        __UUPSUpgradeable_init();
        chainId = localChainId;
        tokenMessenger = ITokenMessenger(messenger);
        messageTransmitter = IMessageTransmitter(transmitter);
        USDC = IERC20(usdcAddress);

        circleDestinationChains[2] = 0; // 10_121 Ethereum
        circleDestinationChains[23] = 3; // 10_143 Arbitrum
        circleDestinationChains[24] = 2; // 10_132 Optimism
        circleDestinationChains[30] = 6; // 10_160 Base

        usdc[2] = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        usdc[23] = address(0xfd064A18f3BF249cf1f87FC203E90D8f650f2d63);
        usdc[24] = address(0xe05606174bac4A6364B31bd0eCA4bf4dD368f8C6);
        usdc[30] = address(0xF175520C52418dfE19C8098071a252da48Cd1C19);
        admin = msg.sender;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pike_send(
        uint16 cctpTargetChainId,
        bytes memory data,
        uint256 // forwardCost
    )
        external
        payable
        onlyAuthorized
    {
        DataTypes.Action selector = DataTypes.Action(uint8(data[31]));
        uint256 amount;
        address recipient;

        if (selector == DataTypes.Action.SPOKE_BORROW_USDC_FORWARD) {
            amount = abi.decode(data, (DataTypes.SpokeBorrowForward)).borrowAmount;
            recipient = abi.decode(data, (DataTypes.SpokeBorrowForward)).user;
        } else if (selector == DataTypes.Action.SPOKE_WITHDRAWAL_USDC_FORWARD) {
            amount = abi.decode(data, (DataTypes.SpokeWithdrawalForward)).withdrawAmount;
            recipient = abi.decode(data, (DataTypes.SpokeWithdrawalForward)).user;
        } else {
            revert Errors.InvalidArguments();
        }

        USDC.approve(address(tokenMessenger), amount);
        if (USDC.balanceOf(address(this)) < amount) revert Errors.AssetTransferFailed();

        tokenMessenger.depositForBurnWithCaller(
            amount,
            circleDestinationChains[cctpTargetChainId],
            pikeCctpInstances[cctpTargetChainId],
            usdc[chainId],
            pikeCctpInstances[cctpTargetChainId]
        );

        // Handle event
        emit OutcomingPikeMessage(
            cctpTargetChainId,
            circleDestinationChains[cctpTargetChainId],
            recipient,
            amount
        );
    }

    function receiveCctpMessage(
        address recipient,
        uint256 amount,
        bytes memory attestation,
        bytes memory message
    )
        public
    {
        messageTransmitter.receiveMessage(message, attestation);

        if (USDC.balanceOf(address(this)) < amount) revert Errors.NotEnoughCollateral();
        if (!USDC.transfer(recipient, amount)) revert Errors.AssetTransferFailed();
    }

    function setPikeCCTP(uint16 chain, address cctp) public onlyOwner {
        if (cctp == address(0)) revert Errors.ZeroAddressNotValid();
        pikeCctpInstances[chain] = bytes32(uint256(uint160(cctp)));
    }

    function setLocalSpoke(address spoke) public onlyOwner {
        if (spoke == address(0)) revert Errors.ZeroAddressNotValid();
        localSpoke = spoke;
    }

    function safeTransfer(
        address to,
        uint256 amount
    )
        external
        onlyAuthorized
        returns (bool)
    {
        if (USDC.balanceOf(address(this)) < amount) {
            revert Errors.ReserveNotEnough();
        }

        return USDC.transfer(to, amount);
    }

    receive() external payable {}
}
