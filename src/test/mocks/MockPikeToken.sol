// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {PikeTokenBase} from "@hub/pikeToken/PikeTokenBase.sol";
import {PikeTokenAdmin} from "@hub/pikeToken/PikeTokenAdmin.sol";
import {Errors} from "@utils/Errors.sol";

contract MockPikeToken is
    Initializable,
    PikeTokenBase,
    UUPSUpgradeable,
    PikeTokenAdmin
{
    function initialize(
        string memory _name,
        string memory _symbol,
        uint16 _spokeChainId
    )
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        admin = msg.sender;
        isActive = true;
        spokeChainId = _spokeChainId;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function mint(address depositor, uint256 depositAmount) external {
        if (depositAmount == 0) {
            revert Errors.ZeroValueProvided();
        }

        _mint(depositor, depositAmount);
    }

    function burn(
        address withdrawer,
        uint256 burnAmount
    )
        external
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(withdrawer)
    {
        if (!isActive) {
            revert Errors.SpokeNotActive();
        }
        if (burnAmount == 0) {
            revert Errors.ZeroValueNotValid();
        }

        _burn(withdrawer, burnAmount);
    }

    function safeTransfer(
        address payable user,
        uint256 amount
    )
        external
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(user)
    {
        if (amount == 0) {
            revert Errors.ZeroValueProvided();
        }

        (bool success,) = payable(user).call{value: amount}("");
        if (!success) {
            revert Errors.AssetTransferFailed();
        }
    }

    function tokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        external
        onlyActiveChain
        onlyMintAuthority
        onlyValidAddress(from)
        onlyValidAddress(to)
    {
        if (amount == 0) {
            revert Errors.ZeroValueProvided();
        }
        _approve(from, to, amount);
        _transfer(from, to, amount);
    }
}
