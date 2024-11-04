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
    uint256 public constant MAX_SUPPLY = (10 ** 9) * (10 ** DECIMALS);

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
     */
    function createToken(string memory name, string memory ticker) external returns (address, address) {
        Token newToken = new Token(name, ticker);
        tokenAddress = address(newToken);
        address liquidityPairsAddress = createLiquidityPair(tokenAddress);
        emit TokenCreated(address(newToken), name, ticker);
        return (tokenAddress, liquidityPairsAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    function createLiquidityPair(address newToken) internal returns (address) {
        LiquidityPairs liquidityPairs = new LiquidityPairs(newToken);
        IERC20(tokenAddress).transfer(address(liquidityPairs), MAX_SUPPLY);
        return address(liquidityPairs);
    }
}
