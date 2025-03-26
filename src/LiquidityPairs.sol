// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidityPairs {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;
    uint256 public constant FUNDING_GOAL = 1150 * (10 ** DECIMALS);
    uint256 public constant INITIAL_VIRTUAL_AVAX = 100 * (10 ** DECIMALS);

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenA;
    uint256 public tokenReserve;
    uint256 public collateral;
    bool public fundingGoalReached;
    uint256 public s_fee;
    address public owner;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error LiquidityPairs__InsufficientFunds();
    error LiquidityPairs__MustBeGreaterThanZero();
    error LiquidityPairs__PairAlreadyLock();
    error LiquidityPairs__SurpassSlippage();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event buyToken(address indexed user, uint256 amountIn, uint256 amountOut);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _tokenA, uint256 maxSupply, uint256 fee, address _owner) {
        tokenA = _tokenA;
        collateral = INITIAL_VIRTUAL_AVAX;
        tokenReserve = maxSupply;
        s_fee = fee;
        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev user buy tokenA with ETH
     */
    function buy(uint256 amountOutMin) external payable {
        // check condition
        if (fundingGoalReached) {
            revert LiquidityPairs__PairAlreadyLock();
        }

        if (msg.value <= 0) {
            revert LiquidityPairs__InsufficientFunds();
        }
        uint256 amountInAfterFee = msg.value * (1000 - s_fee) / 1000;

        // transfer fee for owner;

        payable(owner).transfer(msg.value - amountInAfterFee);

        uint256 amountOut = calculateAmountOut(amountInAfterFee, collateral, tokenReserve);
        if (amountOut < amountOutMin) {
            revert LiquidityPairs__SurpassSlippage();
        }
        if (amountOut <= 0) {
            revert LiquidityPairs__MustBeGreaterThanZero();
        }

        // update state
        IERC20(tokenA).transfer(msg.sender, amountOut);
        collateral += amountInAfterFee;
        tokenReserve -= amountOut;
        if (collateral > FUNDING_GOAL) {
            fundingGoalReached = true;
        }
        emit buyToken(msg.sender, amountInAfterFee, amountOut);
    }

    function sell(uint256 _amountIn, uint256 amountOutMin) external {
        // check condition
        if (fundingGoalReached) {
            revert LiquidityPairs__PairAlreadyLock();
        }
        if (_amountIn <= 0) {
            revert LiquidityPairs__MustBeGreaterThanZero();
        }
        uint256 amountOut = calculateAmountOut(_amountIn, tokenReserve, collateral);
        uint256 actualAmountout = amountOut * (1000 - s_fee) / 1000;

        if (actualAmountout < amountOutMin) {
            revert LiquidityPairs__SurpassSlippage();
        }
        // transfer fee for owner;
        payable(owner).transfer(amountOut - actualAmountout);

        if (amountOut <= 0) {
            revert LiquidityPairs__InsufficientFunds();
        }
        // approve process required in frontend
        // update state
        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountIn);
        payable(msg.sender).transfer(actualAmountout);
        collateral -= amountOut;
        tokenReserve += _amountIn;
        emit buyToken(msg.sender, _amountIn, amountOut);
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

    function getFee() external view returns (uint256) {
        return s_fee;
    }
}
