// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library DataTypes {
    struct HubDeposit {
        Action action;
        Asset assetType;
        Transport transport;
        uint256 nonce;
        address user;
        address assetToken;
        uint256 amountDeposited;
        uint256 forwardCost;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeDepositForward {
        Action action;
        Asset assetType;
        Transport transport;
        address user;
        address assetToken;
        uint256 amountDeposited;
        uint256 tokensToMint;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeDepositDeclined {
        Action action;
        Transport transport;
        address user;
        string declineReason;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct HubBorrow {
        Action action;
        Asset assetType;
        Transport transport;
        address user;
        address assetToken;
        uint256 borrowAmount;
        bool usdcMintRequired;
        address targetAddress;
        uint256 forwardCost;
        uint16 sourceChainId;
        uint16 targetChainId;
        uint16 cctpTargetChainId;
    }

    struct SpokeBorrowForward {
        Action action;
        Asset assetType;
        Transport transport;
        uint256 nonce;
        address user;
        address assetToken;
        uint256 borrowAmount;
        bool usdcMintRequired;
        address targetAddress;
        uint16 sourceChainId;
        uint16 targetChainId;
        uint16 cctpTargetChainId;
    }

    struct SpokeBorrowDecline {
        Action action;
        Transport transport;
        address user;
        string declineReason;
        uint256 borrowAmount;
        bool usdcMintRequired;
        address targetAddress;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct HubRepay {
        Action action;
        Asset assetType;
        Transport transport;
        uint256 nonce;
        address user;
        address sourceToken;
        address targetToken;
        uint256 repaidAmount;
        uint256 forwardCost;
        bool fullRepayment;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeRepayForward {
        Action action;
        Asset assetType;
        Transport transport;
        address user;
        address sourceToken;
        address targetToken;
        uint256 repaidAmount;
        uint256 convertedAmount;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeRepayDecline {
        Action action;
        Transport transport;
        address user;
        string declineReason;
        uint256 repaidAmount;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct HubWithdrawal {
        Action action;
        Asset assetType;
        Transport transport;
        address user;
        address assetToken;
        uint256 withdrawAmount;
        bool usdcMintRequired;
        address targetAddress;
        uint256 forwardCost;
        bool fullWithdrawal;
        uint16 sourceChainId;
        uint16 targetChainId;
        uint16 cctpTargetChainId;
    }

    struct SpokeWithdrawalForward {
        Action action;
        Asset assetType;
        Transport transport;
        uint256 nonce;
        address user;
        address assetToken;
        uint256 withdrawAmount;
        bool usdcMintRequired;
        uint16 sourceChainId;
        uint16 targetChainId;
        uint16 cctpTargetChainId;
    }

    struct SpokeWithdrawalDecline {
        Action action;
        address user;
        string declineReason;
        uint256 withdrawAmount;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct HubLiquidate {
        Action action;
        Asset assetType;
        Transport transport;
        address user; // borrower
        address sourceToken;
        address targetToken;
        address liquidator;
        uint256 repayAmount;
        bool usdcMintRequired;
        uint256 forwardCost;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeLiquidateForward {
        Action action;
        Asset assetType;
        Transport transport;
        uint256 nonce;
        address user; // borrower
        address sourceToken;
        address targetToken;
        address liquidator;
        uint256 totalDiscounted;
        uint256 seizedShare;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeLiquidateDecline {
        Action action;
        address user; // borrower
        string declineReason;
        address liquidator;
        uint256 repaid;
        uint256 totalDiscounted;
        uint256 seizedShare;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct SpokeDecline {
        Action action;
        address user;
        uint256 amount;
        uint16 sourceChainId;
        uint16 targetChainId;
    }

    struct ActionStatus {
        Action status;
        address user;
        uint256 amount;
        string declineReason;
    }

    enum Action {
        NULL, // 0
        HUB_DEPOSIT, // 1
        SPOKE_DEPOSIT_FORWARD, // 2
        SPOKE_DEPOSIT_DECLINE, // 3
        HUB_BORROW, // 4
        SPOKE_BORROW_FORWARD, // 5
        SPOKE_BORROW_USDC_FORWARD, // 6
        SPOKE_BORROW_DECLINE, // 7
        HUB_REPAY, // 8
        SPOKE_REPAY_FORWARD, // 9
        SPOKE_REPAY_DECLINE, // 10
        HUB_WITHDRAWAL, // 11
        SPOKE_WITHDRAWAL_FORWARD, // 12
        SPOKE_WITHDRAWAL_USDC_FORWARD, // 13
        SPOKE_WITHDRAWAL_DECLINE, // 14
        HUB_LIQUIDATE, // 15
        SPOKE_LIQUIDATE_FORWARD, // 16
        SPOKE_LIQUIDATE_DECLINE, // 17
        SPOKE_DECLINE
    }

    enum Transport {
        NULL,
        INTRACHAIN,
        WORMHOLE,
        LAYERZERO,
        CCTP,
        AXELAR,
        CCIP
    }

    enum Asset {
        NULL,
        EVM,
        ERC,
        USDC
    }

    enum MessageStatus {
        NULL,
        SENT,
        RECEIVED,
        FORWARDED
    }

    struct Message {
        MessageStatus status;
        uint256 sent;
        uint256 received;
        uint256 elapsed;
        bytes payload;
    }

    struct Market {
        uint256 totalSupply;
        string name;
        string symbol;
        bool isListed;
        bool isPaused;
        uint16 chainId;
        uint8 decimals;
        mapping(address => bool) accountMembership;
    }

    struct BorrowSnapshot {
        uint256 principal; // total balance incl. accrued interests
        uint256 interestIndex; // last stored global borrowIndex
    }

    struct BorrowLocalVars {
        uint256 borrowAmountInUsd;
        uint256 maxBorrowAmountInUsd;
        uint16 numChains;
    }

    struct RepayLocalVars {
        uint256 convertedRepayAmount;
        uint256 repayForThisChain;
        uint16 numChains;
        uint16 targetChainIndex;
    }

    struct WithdrawalLocalVars {
        uint256 totalCollateralUsd;
        uint256 totalBorrowsUsd;
        uint256 exchangeRate;
        uint256 tokensToBurn;
        address depositToken;
        uint256 nonce;
        uint256 withdrawTotal;
        uint256 withdrawFromThisChain;
        uint256 chainDeposit;
        uint16 numChains;
        uint16 targetChainIndex;
        uint16 depositChainId;
        bytes forwardWithdrawalPayload;
    }

    struct LiquidationLocalVars {
        uint256 convertedRepayAmount;
        uint256 maxLiquidatableAmount;
        uint256 discount;
        uint256 penalty;
        uint256 exchangeRate;
        bytes forwardLiquidatePayload;
    }

    struct SupplyErcInputVars {
        DataTypes.Asset assetType;
        address assetToken;
        uint256 depositAmount;
        uint256 forwardCost;
    }

    struct BorrowInputVars {
        Asset assetType;
        Transport transport;
        address assetToken;
        address borrower;
        uint256 borrowAmount;
        bool usdcMintRequired;
        address targetAddress;
        uint256 forwardCost;
        uint16 targetChainId;
        uint16 cctpTargetChainId;
    }

    struct RepayErcInputVars {
        Asset assetType;
        address repayer;
        address assetToken;
        address targetToken;
        uint16 targetChainId;
        uint256 repayAmount;
        uint256 forwardCost;
    }

    struct WithdrawalInputVars {
        Asset assetType;
        Transport transport;
        address assetToken;
        address withdrawer;
        uint256 withdrawAmount;
        bool usdcMintRequired;
        uint16 targetChainId;
        address targetAddress;
        uint16 cctpTargetChainId;
        uint256 forwardCost;
    }

    struct LiquidationInputVars {
        Asset assetType;
        Transport transport;
        address assetToken;
        address targetToken;
        address borrower;
        uint256 repayAmount;
        bool usdcMintRequired;
        uint16 targetChainId;
        uint256 forwardCost;
    }

    struct sendData {
        uint16 targetChainId;
        bytes sourceAddress;
        address targetAddress;
        uint64 nonce;
        uint256 extraGas;
        bytes payload;
    }

    uint256 public constant ZERO_COST = 0;
}
