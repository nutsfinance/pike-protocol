// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {GatewayModifiers} from "./GatewayModifiers.sol";
import {IChannel} from "./channels/interfaces/IChannel.sol";
import {IGateway} from "./interfaces/IGateway.sol";
import {ISpoke} from "@spoke/interfaces/ISpoke.sol";
import {DataTypes} from "@types/DataTypes.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract GatewayAdmin is IGateway, GatewayModifiers {
    function changeAdmin(address newAdmin) external onlyOwner {
        if (newAdmin == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        admin = newAdmin;
    }

    function changeChannelAuthorizedStatus(
        address channelAddr,
        bool status
    )
        external
        onlyOwner
    {
        if (channelAddr == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        authorizedChannels[channelAddr] = status;
    }

    function addChannel(
        DataTypes.Transport transport,
        IChannel channel
    )
        external
        onlyOwner
    {
        if (address(channel) == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        channels[transport] = channel;
        authorizedChannels[address(channel)] = true;
    }

    function setLocalSpoke(address _spoke) external onlyOwner {
        spoke = ISpoke(_spoke);
    }

    function setAssetType(
        address assetToken,
        DataTypes.Asset assetType
    )
        external
        onlyOwner
    {
        assetTypes[assetToken] = assetType;
    }
}
