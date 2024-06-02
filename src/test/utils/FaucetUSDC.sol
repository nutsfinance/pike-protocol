// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-pike/access/Ownable.sol";
import {IERC20} from "@openzeppelin-pike/token/ERC20/IERC20.sol";
import {Spoke} from "@spoke/Spoke.sol";

contract FaucetUSDC is Ownable {
    uint256 public transferErcAmount = 100e6;
    IERC20 public USDC;
    Spoke public spoke;

    uint256 public withdrawalInterval = 1 hours;
    mapping(address => uint256) public lastWithdrawal;

    constructor(address tokenContract, Spoke localSpoke) Ownable(_msgSender()) {
        USDC = IERC20(tokenContract);
        spoke = localSpoke;
    }

    function requestTokens() external {
        require(
            block.timestamp >= lastWithdrawal[_msgSender()] + withdrawalInterval,
            "Wait for 1 hour before requesting additional USDC"
        );

        require(USDC.balanceOf(address(this)) >= transferErcAmount, "Faucet Empty!");
        require(USDC.transfer(_msgSender(), transferErcAmount), "Transfer failed");

        lastWithdrawal[_msgSender()] = block.timestamp;
    }

    function withdraw(address to, uint256 value) public onlyOwner {
        USDC.transfer(to, value);
    }

    function setTransferErcAmount(uint256 amount) public onlyOwner {
        transferErcAmount = amount;
    }

    function getBalance() public view returns (uint256) {
        return USDC.balanceOf(address(this));
    }
}
