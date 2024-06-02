// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.20;

import {ERC20PausableUpgradeable} from
    "@oz-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract pause mechanism of the contract unreachable, and thus unusable.
 */
abstract contract PikeTokenBase is ERC20PausableUpgradeable, OwnableUpgradeable {
    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override(ERC20PausableUpgradeable)
        whenNotPaused
    {
        super._update(from, to, value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
