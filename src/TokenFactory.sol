// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Token} from "./Token.sol";
import {LiquidityPairs} from "./LiquidityPairs.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenCreated(address indexed tokenAddress, string indexed name, string indexed ticker);

    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenAddress;

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
    function createToken(string memory name, string memory ticker, uint256 maxSupply)
        external
        returns (address, address)
    {
        Token newToken = new Token(name, ticker, maxSupply);
        tokenAddress = address(newToken);
        address liquidityPairsAddress = createLiquidityPair(tokenAddress, maxSupply);
        emit TokenCreated(address(newToken), name, ticker);
        return (tokenAddress, liquidityPairsAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    function createLiquidityPair(address newToken, uint256 maxSupply) internal returns (address) {
        LiquidityPairs liquidityPairs = new LiquidityPairs(newToken, maxSupply);
        IERC20(tokenAddress).transfer(address(liquidityPairs), maxSupply);
        return address(liquidityPairs);
    }
}
