// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TradingPairs {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenA;
    address public tokenB;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error TradingPairs__InsufficientFunds();
    error TradingPairs__MustBeGreaterThanZero();
    error TradingPairs__InsufficientLiquidity();
    error TradingPairs__SurpassSlippage();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event swapToken(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) external {
        // check condition
        if (IERC20(tokenA).balanceOf(address(this)) == 0 || IERC20(tokenB).balanceOf(address(this)) == 0) {
            revert TradingPairs__InsufficientLiquidity();
        }
        uint256 amountOut;
        if (tokenIn == tokenA) {
            amountOut = calculateAmountOut(
                amountIn, IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this))
            );
        } else {
            amountOut = calculateAmountOut(
                amountIn, IERC20(tokenB).balanceOf(address(this)), IERC20(tokenA).balanceOf(address(this))
            );
        }
        if (amountOut < amountOutMin) {
            revert TradingPairs__SurpassSlippage();
        }

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit swapToken(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {

    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function calculateAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut)
        public
        pure
        returns (uint256)
    {
        // dy = ydx / (x + dx)
        uint256 amountOut = (_reserveOut * _amountIn) / (_reserveIn + _amountIn);
        return amountOut;
    }

    function getPrice() public view returns (uint256) {
        return IERC20(tokenB).balanceOf(address(this)) / IERC20(tokenA).balanceOf(address(this));
    }
}
