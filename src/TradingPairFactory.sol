// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TradingPairs} from "./TradingPairs.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TradingPairFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    error TradingPairFactory__TradingPairAlreadyExists();

    event TradingPairDeployed(address indexed tradingPairAddress, address indexed tokenA, address indexed tokenB);

    mapping(address tokenA => mapping(address tokenB => address pair)) getPair;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // we don't use contructor in implementation contract,
    // because it only change the implementation contract storage slot, not the proxy contract
    constructor() {
        // make sure that no initializer is call during constructor
        _disableInitializers();
    }

    // this function treat as constructor for the proxy
    // initializer modifier will make sure that this function only call once
    function initialize() external initializer {
        __Ownable_init(msg.sender); // sets owner to: owner = msg.sender
        __UUPSUpgradeable_init();
    }

    function deployNewTradingPair(address tokenA, address tokenB) external {
        (address baseToken, address quoteToken) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // Check if the trading pair already exists
        if (getPair[baseToken][quoteToken] != address(0)) {
            revert TradingPairFactory__TradingPairAlreadyExists();
        }
        bytes memory bytecode = type(TradingPairs).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        address pair;
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        TradingPairs(pair).initialize(baseToken, quoteToken);
        getPair[baseToken][quoteToken] = pair; // Store the pair address in the mapping

        // Emit an event or perform any other actions with the deployed trading pair
        emit TradingPairDeployed(pair, baseToken, quoteToken);
    }

    // The following functions are overrides required by Solidity.
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
