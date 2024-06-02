// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IHub} from "@hub/interfaces/IHub.sol";
import {PikeTokenInternals} from "./PikeTokenInternals.sol";
import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import "@gateway/interfaces/IGateway.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract PikeTokenAdmin is PikeTokenInternals {
    function setHubAddress(address hubAddress) external onlyOwner {
        if (hubAddress == address(0)) revert Errors.ZeroAddressNotValid();
        hub = IHub(hubAddress);
    }

    function setGateway(address gatewayAddress) external onlyOwner {
        if (gatewayAddress == address(0)) revert Errors.ZeroAddressNotValid();
        gateway = IGateway(gatewayAddress);
    }

    function initializeToken(
        uint16 chainId_,
        address token_,
        uint256 borrowIndex_
    )
        external
        onlyMintAuthority
    {
        chainId = chainId_;
        token = token_;
        totalBorrowIndex = borrowIndex_;
    }

    function mintToAddress(address to, uint256 amount) public onlyOwner {
        if (amount == 0) revert Errors.ZeroValueNotValid();

        _mint(to, amount);
    }

    function setPikeOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        pikeOracle = IPikeOracle(oracle);
    }
}
