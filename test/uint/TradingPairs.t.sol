// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TradingPairs} from "../../src/TradingPairs.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
contract TradingPairsTest is Test {
    TradingPairs tradingPairs;
    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TA", 10000000000000000000000000);
        tokenB = new MockERC20("Token B", "TB", 10000000000000000000000000);
        tradingPairs = new TradingPairs();
        IERC20(address(tokenA)).approve(address(tradingPairs), 10000000000000000000000000);
        IERC20(address(tokenB)).approve(address(tradingPairs), 10000000000000000000000000);
        tradingPairs.initialize(address(tokenA), address(tokenB));
    }

    function test_addLiquidity() public {
        uint256 amountA = 1000000000000000000000000;
        uint256 amountB = 1000000000000000000000000;
        tradingPairs.addLiquidity(amountA, amountB);

        // The second addLiquidity call fails because after the first call,
        // the price ratio is established in the pool. When we try to add
        // the same amounts again, the price check in addLiquidity will fail.
        // The function checks if (amountB * DECIMALS) / amountA matches the current price.
        // Since we're adding equal amounts again, but the pool might have a slightly different ratio,
        // it will try to adjust one of the amounts and may revert if there are insufficient funds.
        
        // We need to approve more tokens before the second call
        IERC20(address(tokenA)).approve(address(tradingPairs), amountA);
        IERC20(address(tokenB)).approve(address(tradingPairs), amountB);
        
        // This will now work because we've approved the tokens
        tradingPairs.addLiquidity(amountA, amountB);
    }

    
}