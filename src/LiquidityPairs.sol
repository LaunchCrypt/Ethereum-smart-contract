// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidityPairs {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;
    uint256 public constant FUNDING_GOAL = 30 * (10 ** DECIMALS);
    uint256 public constant INITIAL_VIRTUAL_ETH = 3 * (10 ** DECIMALS);
    uint256 public constant FEE = 3; // 0.3%

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenA;
    uint256 public tokenReserve;
    uint256 public collateral;
    bool public fundingGoalReached;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error LiquidityPairs__InsufficientFunds();
    error LiquidityPairs__MustBeGreaterThanZero();
    error LiquidityPairs__PairAlreadyLock();
    error LiquidityPairs__InsufficientLiquidity();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event buyToken(address indexed user, uint256 amountIn, uint256 amountOut);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _tokenA, uint256 maxSupply) {
        tokenA = _tokenA;
        collateral = INITIAL_VIRTUAL_ETH;
        tokenReserve = maxSupply;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     @dev user buy tokenA with ETH
     */
    function buy() external payable{
        // check condition
        if (fundingGoalReached){
            revert LiquidityPairs__PairAlreadyLock();
        }

        if (msg.value <= 0){ 
            revert LiquidityPairs__InsufficientFunds();
        }
        uint256 amountOut = calculateAmountOut(msg.value, collateral, tokenReserve);
        if (amountOut <= 0){
            revert LiquidityPairs__MustBeGreaterThanZero();
        }


        // update state
        IERC20(tokenA).transfer(msg.sender, amountOut);
        collateral += (msg.value * (1000 - FEE)) / 1000;
        tokenReserve -= amountOut;
        if (collateral > FUNDING_GOAL){
            fundingGoalReached = true;
        }
        emit buyToken(msg.sender, msg.value , amountOut);
    }

    function sell(uint256 _amountIn) external {
        // check condition
        if(fundingGoalReached){
            revert LiquidityPairs__PairAlreadyLock();
        }
        if (_amountIn <= 0) {
            revert LiquidityPairs__MustBeGreaterThanZero();
        }
        uint256 amountOut = calculateAmountOut(_amountIn, tokenReserve, collateral);
        if (amountOut <= 0){
            revert LiquidityPairs__InsufficientFunds();
        }
        // approve process required in frontend
        // update state
        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountIn);
        payable(msg.sender).transfer(amountOut);
        collateral -= amountOut;
        tokenReserve += (_amountIn * (1000 - FEE)) / 1000;
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
        uint256 amountInWithFee = (_amountIn * (1000 - FEE)) / 1000; // 0.3% fee;

        // dy = ydx / (x + dx)
        uint256 amountOut = (_reserveOut * amountInWithFee) / (_reserveIn + amountInWithFee);
        return amountOut;
    }
}


