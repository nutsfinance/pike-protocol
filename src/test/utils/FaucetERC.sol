// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-pike/access/Ownable.sol";
import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";
import {Spoke} from "@spoke/Spoke.sol";

contract FaucetERC is Ownable {
    uint256 public transferErcAmount = 10e18;
    IERC20 public token;
    Spoke public spoke;

    constructor(address tokenContract, Spoke localSpoke) Ownable(_msgSender()) {
        token = IERC20(tokenContract);
        spoke = localSpoke;
    }

    function requestTokens() external {
        require(token.balanceOf(address(this)) >= transferErcAmount, "Faucet Empty!");
        require(token.transfer(_msgSender(), transferErcAmount), "Transfer failed");
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        token.transfer(to, value);
    }

    function setTransferErcAmount(uint256 amount) public onlyOwner {
        transferErcAmount = amount;
    }
}
