// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Token} from "./Token.sol";
import {LiquidityPairs} from "./LiquidityPairs.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenCreated(address indexed tokenAddress, string indexed name, string indexed ticker);
    event LiquidityPairsCreated(address indexed liquidityPairsAddress);

    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenAddress;


    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

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


    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev create a new token and liquidity pair
     *  @return return the address of the new token and new liquidity pair
     *  @param name the name of the token
     *  @param ticker the ticker of the token
     *  @param maxSupply the max supply of the token (not include decimals)
     */
    function createToken(string memory name, string memory ticker, uint256 maxSupply, uint256 fee)
        external
        returns (address, address)
    {
        Token newToken = new Token(name, ticker, maxSupply);
        tokenAddress = address(newToken);
        address liquidityPairsAddress = createLiquidityPair(tokenAddress, maxSupply, fee, msg.sender);
        emit TokenCreated(address(newToken), name, ticker);
        emit LiquidityPairsCreated(liquidityPairsAddress);
        return (tokenAddress, liquidityPairsAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    function createLiquidityPair(address newToken, uint256 maxSupply, uint256 fee, address owner)
        internal
        returns (address)
    {
        LiquidityPairs liquidityPairs = new LiquidityPairs(newToken, maxSupply, fee, owner);
        IERC20(tokenAddress).transfer(address(liquidityPairs), maxSupply);
        return address(liquidityPairs);
    }

    // The following functions are overrides required by Solidity.
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

}
