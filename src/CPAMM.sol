// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";

contract CPAMM {
    /*//////////////////////////////////////////////////////////////
                        IMMUTABLES & CONSTANT
    //////////////////////////////////////////////////////////////*/
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint256 public constant FEE = 3; // 0.3%

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error CPAMM__NotValidToken();
    error CPAMM__MustBeGreaterThanZero();
    error CPAMM__ManipulatePrice();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTION
    //////////////////////////////////////////////////////////////*/
    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        if (_tokenIn != address(token0) && _tokenIn != address(token1)) {
            revert CPAMM__NotValidToken();
        }
        if (_amountIn <= 0) {
            revert CPAMM__MustBeGreaterThanZero();
        }

        // pull in token in
        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 _reserveIn, uint256 _reserveOut) =
            isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // calculate token out (include fee)
        amountOut = calculateAmountOut(_amountIn, _reserveIn, _reserveOut);

        // transfer token out to sender
        tokenOut.transfer(msg.sender, amountOut);
        // update reserve
        updateReserve(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1) external returns (uint256 shares) {
        // pull in token0 and token1
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        // dy / dx = y / x
        if (reserve0 > 0 || reserve1 > 0) {
            if (_amount0 * reserve1 != _amount1 * reserve0) {
                revert CPAMM__ManipulatePrice();
            }
        }

        // mint shares
        /*
        f(x, y) = value of liquidity
        We will define f(x, y) = sqrt(xy)
        s = dx / x * T = dy / y * T
        */

        if (totalSupply == 0) {
            shares = sqrt(_amount0 * _amount1);
        } else {
            shares = min(_amount0 * totalSupply / reserve0, _amount1 * totalSupply / reserve1);
        }
        if (shares <= 0) {
            revert CPAMM__MustBeGreaterThanZero();
        }
        _mint(msg.sender, shares);

        // update reserve
        updateReserve(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external returns(uint256 amount0, uint256 amount1 ){
        // calculate amount0 and amount1 to withdraw
        /*
        dx = s / T * x
        dy = s / T * y
        */
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));
        amount0 = (_shares* bal0) / totalSupply;
        amount1 = (_shares* bal1) / totalSupply;
        if (amount0 <= 0 || amount1 <= 0) {
            revert CPAMM__MustBeGreaterThanZero();
        }
        // burn share
        _burn(msg.sender, _shares);
        // update reserve
        updateReserve(bal0 - amount0, bal1 - amount1);
        // transfer token tone to sender
        token0.transfer(msg.sender, amount0); 
        token1.transfer(msg.sender, amount1);
    }

    /*//////////////////////////////////////////////////////////////
                       PRIVATE && INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    function _mint(address _to, uint256 _amount) private {
        totalSupply = totalSupply + _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        totalSupply = totalSupply - _amount;
        balanceOf[_from] = balanceOf[_from] - _amount;
    }

    function updateReserve(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
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

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}
