// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin-pike/token/ERC20/ERC20.sol";
import "@openzeppelin-pike/access/Ownable.sol";

contract PikeERC is ERC20, Ownable {
    constructor(
        string memory tokenName,
        string memory tokenSymbol
    )
        ERC20(tokenName, tokenSymbol)
        Ownable(_msgSender())
    {
        _mint(address(this), 1e9 * 10 ** decimals());
        _mint(_msgSender(), 1e4 * 10 ** decimals());
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function mintToAddress(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
