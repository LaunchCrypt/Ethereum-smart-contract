// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LiquidityPairs {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = (10 ** 9) * (10 ** DECIMALS);
    uint256 public constant FUNDING_GOAL = 30 * (10 ** DECIMALS);
    uint256 public constant INITIAL_VIRTUAL_ETH = 3 * (10 ** DECIMALS);
    uint256 public constant MINIUM_TOKEN_LIQUIDITY = MAX_SUPPLY * 20 / 100;
    uint256 public constant FEE = 3; // 0.3%

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    address public tokenA;
    uint256 public tokenReserve;
    uint256 public collateral;
    mapping(address user => uint256 balance) public balances;
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
    constructor(address _tokenA) {
        tokenA = _tokenA;
        collateral = INITIAL_VIRTUAL_ETH;
        tokenReserve = MAX_SUPPLY;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     @dev user buy tokenA with ETH
     */
    function buy() external payable {
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
        balances[msg.sender] += amountOut;
        collateral += msg.value;
        tokenReserve -= amountOut;
        if (collateral > FUNDING_GOAL){
            fundingGoalReached = true;
        }
        emit buyToken(msg.sender, msg.value, amountOut);
    }

    function sell(uint256 _amountIn) external payable {
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
        
        // update state
        balances[msg.sender] -= _amountIn;
        collateral -= amountOut;
        tokenReserve += _amountIn;
        payable(msg.sender).transfer(amountOut);
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
