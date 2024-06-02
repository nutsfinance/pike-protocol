// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin-pike/access/Ownable.sol";

contract FaucetEVM is Ownable {
    mapping(address => uint256) internal requests;
    uint256 public transferEthAmount;

    constructor() Ownable(_msgSender()) {
        transferEthAmount = 1e18;
    }

    receive() external payable {}

    function requestTokens() public {
        address user = _msgSender();
        require(
            address(this).balance >= transferEthAmount,
            "The contract balance is insufficient"
        );
        require(block.timestamp - requests[user] >= 3600, "Wait for 1 hour");
        (bool success,) = user.call{value: transferEthAmount}("");
        require(success, "Transfer failed");
        requests[user] = block.timestamp;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTransferEthAmount(uint256 _amount) public onlyOwner {
        transferEthAmount = _amount;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
