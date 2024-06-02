// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {HubModifiers} from "./HubModifiers.sol";
import {IGateway} from "@gateway/interfaces/IGateway.sol";
import {IPikeOracle} from "@hub/oracle/interfaces/IPikeOracle.sol";
import {IInterestRateModel} from "@hub/interest/interfaces/IInterestRateModel.sol";
import {IRiskEngine} from "@hub/collateral/interfaces/IRiskEngine.sol";
import {PikeToken} from "@hub/pikeToken/PikeToken.sol";
import {Errors} from "@utils/Errors.sol";

abstract contract HubAdmin is HubModifiers {
    function changeOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        admin = newOwner;
    }

    function changeContractAuthorizedStatus(
        address contractAddress,
        bool status
    )
        external
        onlyOwner
    {
        if (contractAddress == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        authorizedContracts[contractAddress] = status;
    }

    function setAuthorizedChannel(
        uint16 chainId,
        address channelAddress
    )
        external
        onlyOwner
    {
        if (chainId == 0 || channelAddress == address(0)) {
            revert Errors.InvalidArguments();
        }
        authorizedChannels[chainId] = channelAddress;
    }

    function changeGateway(IGateway newGateway) external onlyOwner {
        if (address(newGateway) == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        gateway = newGateway;
    }

    function changeLocalGateway(IGateway newGateway) external onlyOwner {
        if (address(newGateway) == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        intraGateway = newGateway;
    }

    function setInterestRateModel(address model) external onlyOwner {
        if (model == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        interestRateModel = IInterestRateModel(model);
    }

    function setRiskEngine(address engine) external onlyOwner {
        if (engine == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        riskEngine = IRiskEngine(engine);
    }

    function setPikeOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        pikeOracle = IPikeOracle(oracle);
    }

    function addNewChains(uint16[] memory chainIds) external onlyOwner {
        uint16 length = uint16(chainIds.length);
        for (uint16 i; i < length;) {
            chains.push(chainIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addNewTokens(address[][] memory inputs) external onlyOwner {
        uint16 length = uint16(inputs.length);
        for (uint16 i; i < length;) {
            uint16 chain = chains[i];
            address[] memory arrayTokens = inputs[i];
            chainTokens[chain] = arrayTokens;

            unchecked {
                ++i;
            }
        }
    }

    function addNewMarket(
        uint16 chainId,
        address token,
        uint256 _totalSupply,
        string memory name,
        string memory symbol,
        bool isListed,
        bool isPaused,
        uint8 decimals
    )
        external
        onlyOwner
    {
        if (markets[chainId][token].isListed) {
            revert Errors.SpokeAlreadyExists();
        }

        markets[chainId][token].totalSupply = _totalSupply;
        markets[chainId][token].name = name;
        markets[chainId][token].symbol = symbol;
        markets[chainId][token].isListed = isListed;
        markets[chainId][token].isPaused = isPaused;
        markets[chainId][token].chainId = chainId;
        markets[chainId][token].decimals = decimals;
    }

    function addChainPikeToken(
        uint16 chainId,
        address token,
        address pikeToken
    )
        external
        onlyOwner
    {
        if (chainId == 0) {
            revert Errors.ZeroValueNotValid();
        }
        if (token == address(0)) {
            revert Errors.ZeroAddressNotValid();
        }
        pikeTokens[chainId][token] = pikeToken;
        PikeToken(pikeToken).initializeToken(chainId, token, ONE);
    }
}
