// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "@types/DataTypes.sol";

interface IPikeToken {
    event HubChainIdSet(uint256 chainId);
    event SpokeChainIdSet(uint256 spokeChainId);
    event HubAddressSet(address hubAddress);
    event GatewayBeenSet(address gateway);
    event MarketPaused(bool isPaused);
    event MintActionPerformed(address indexed depositor, uint256 amount);
    event BurnActionPerformed(address indexed withdrawer, uint256 amount);

    /**
     * Allows minting
     * @param depositor The address of the user
     * @param depositAmount The amount deposited and to be minted
     */
    function mint(address depositor, uint256 depositAmount) external;

    /**
     * Allows burning and sending tokens
     * @param withdrawer The address of the user
     * @param withdrawAmount The amount deposited and to be minted
     */
    function burn(address withdrawer, uint256 withdrawAmount) external;

    // function balanceOf(address account) external view returns (uint256);

    // function totalSupply() external view returns (uint256);

    /**
     * Allows safe transferring via call()
     * @param user The address of the user
     * @param amount The amount deposited and to be minted
     */
    function safeTransfer(address payable user, uint256 amount) external;

    function processDeposit(DataTypes.HubDeposit memory a) external;

    function processBorrow(DataTypes.HubBorrow memory a) external;

    function processRepay(
        DataTypes.HubRepay memory a,
        uint256 convertedRepayAmount
    )
        external
        returns (uint256 repayForThisChain);

    function processWithdrawal(
        DataTypes.HubWithdrawal memory a,
        uint256 withdrawAmount
    )
        external
        returns (uint256 withdrawnAmount);

    function processLiquidate(
        DataTypes.HubLiquidate memory a,
        uint256 withdrawAmount
    )
        external
        returns (uint256 discount, uint256 penalty);

    function accrueInterestsForToken() external;
}
