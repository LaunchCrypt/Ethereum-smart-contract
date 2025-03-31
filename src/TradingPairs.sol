// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TradingPairs is ERC20 {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 34; // 0.1 x 0.1
    uint256 public constant FEE = 3; // 0.3%
    uint256 public constant BASE_LP = 10 ether;
    address public tokenA;
    address public tokenB;
    address public factory;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error TradingPairs__InsufficientFunds();
    error TradingPairs__MustBeGreaterThanZero();
    error TradingPairs__InsufficientLiquidity();
    error TradingPairs__SurpassSlippage();
    error TradingPairs__OnlyFactory();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event swapToken(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    event addLiquidityToken(address indexed user, address tokenA, address tokenB, uint256 amountA, uint256 amountB);

    event removeLiquidityPool(address indexed user, address tokenA, address tokenB, uint256 amountA, uint256 amountB);
    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert TradingPairs__OnlyFactory();
        }
        _;
    }
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("TradingPairs", "TP") {
        factory = msg.sender;
    }

    function initialize(address _tokenA, address _tokenB) external onlyFactory {
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
        uint256 amountInAfterFee = amountIn * (1000 - FEE) / 1000;
        if (tokenIn == tokenA) {
            amountOut = calculateAmountOut(
                amountInAfterFee, IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this))
            );
        } else {
            amountOut = calculateAmountOut(
                amountInAfterFee, IERC20(tokenB).balanceOf(address(this)), IERC20(tokenA).balanceOf(address(this))
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
        uint256 reserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = IERC20(tokenB).balanceOf(address(this));
        uint256 totalLiquidity = reserveA * reserveB;

        if (amountA * amountB < MINIMUM_LIQUIDITY) {
            revert TradingPairs__InsufficientLiquidity();
        }

        if (reserveA == 0 && reserveB == 0) {
            uint256 provideLiquidity = amountA * amountB;
            uint256 lpAmount = provideLiquidity / MINIMUM_LIQUIDITY * BASE_LP; 
            _mint(msg.sender, lpAmount);
            emit addLiquidityToken(msg.sender, tokenA, tokenB, amountA, amountB);
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        } else {
            uint256 currentPrice = (reserveB * DECIMALS) / reserveA;
            if ((amountB * DECIMALS) / amountA > currentPrice) {
                uint256 amountBDesired = (amountA * reserveB) / reserveA;
                uint256 liquidityProvide = amountBDesired * amountA;
                uint256 totalLPReceive = liquidityProvide * totalSupply() / totalLiquidity; 
                _mint(msg.sender, totalLPReceive);
                IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
                IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
                emit addLiquidityToken(msg.sender, tokenA, tokenB, amountA, amountBDesired);
            } else if ((amountB * DECIMALS) / amountA < currentPrice) {
                uint256 amountADesired = (amountB * reserveA) / reserveB;
                uint256 liquidityProvide = amountADesired * amountB;
                uint256 totalLPReceive = liquidityProvide * totalSupply() / totalLiquidity; 
                _mint(msg.sender, totalLPReceive);
                IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
                IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
                emit addLiquidityToken(msg.sender, tokenA, tokenB, amountADesired, amountB);
            }
        }
    }

    function removeLiquidity(uint256 amountLP) external {
        uint256 reserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = IERC20(tokenB).balanceOf(address(this));

        if (amountLP > balanceOf(msg.sender)) {
            revert TradingPairs__InsufficientFunds();
        }

        uint256 amountA = amountLP * reserveA / (totalSupply() + BASE_LP);
        uint256 amountB = amountLP * reserveB / (totalSupply() + BASE_LP);

        _burn(msg.sender, amountLP);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit removeLiquidityPool(msg.sender, tokenA, tokenB, amountA, amountB);
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
