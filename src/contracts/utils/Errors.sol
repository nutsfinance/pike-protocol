// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    error OnlyAuth();
    error OnlyOwner();
    error OnlyGateway();

    /// @dev Common
    error CallerNotAuthorized();
    error ZeroAddressNotValid();
    error ZeroValueNotValid();
    error ZeroValueProvided();
    error InvalidGateway();
    error InvalidParamsLength();
    error InvalidArguments();
    error InvalidAsset();
    error InconsistentParamsLength();
    error NotIntraChainCall();
    error UnknownRevert();

    /// @dev Spokes
    error SpokeNotFound();
    error SpokeNotActive();
    error SpokeAlreadyExists();

    /// @dev Reserves
    error ReserveNotFound();
    error ReserveInactive();
    error ReserveFrozen();
    error ReservePaused();
    error ReserveNotEnough();

    /// @dev Wormhole-related
    error WormholeFailed();
    error ZeroWormholePayload();
    error MessageHashDuplicate();
    error InvalidWormholeFees();

    /// @dev User-related
    error UserHasNoDeposits();
    error PriceFeedError();
    error NotEnoughTimePassed();
    error NotEnoughValueProvided();
    error NotEnoughCollateral();
    error LtvExceedsMaxAllowed();
    error RedeemTooMuch();
    error DuplicateMessageReceived();

    /// @dev Action-related
    error AssetTransferFailed();

    /// @dev Oracle
    error NoPriceFeed();
    error NegativePriceFound();

    /// @dev Risk Engine
    error InvalidRiskParameter();

    /// @dev Liquidation-related
    error InvalidLiquidationAmount();
    error LiquidationExceedsMaxAllowed();
    error NotLiquidatableAccount();

    /// @dev Delayed operations
    error OperationTooSoon();
}
