// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {LiquidityPairs} from "../../src/LiquidityPairs.sol";
import {DeployTokenFactory} from "../../script/DeployTokenFactory.s.sol";
import {TokenFactory} from "../../src/TokenFactory.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LiquidityPairsTest is Test {
    /*//////////////////////////////////////////////////////////////
                                 SET UP
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_SUPPLY = 1000000000 * 10 ** 18;

    uint256 public decimal;
    uint256 public maxSupply;
    uint256 public virtualETH;
    uint256 public constant AMOUNT_IN = 1 ether;

    TokenFactory public tokenFactory;
    DeployTokenFactory public deployer;
    LiquidityPairs public liquidityPairs;
    HelperConfig public helperConfig;

    address user = makeAddr("USER");

    function setUp() public {
        vm.deal(user, 100 ether);

        deployer = new DeployTokenFactory();
        tokenFactory = deployer.run();

        (, address liquidityPairsAddress) = tokenFactory.createToken("MyToken", "MTK", MAX_SUPPLY);
        liquidityPairs = LiquidityPairs(liquidityPairsAddress);

        helperConfig = new HelperConfig();

        decimal = helperConfig.DECIMALS();
        maxSupply = helperConfig.MAX_SUPPLY();
        virtualETH = helperConfig.INITIAL_VIRTUAL_ETH();
    }

    /*//////////////////////////////////////////////////////////////
                                TEST BUY
    //////////////////////////////////////////////////////////////*/
    function testBuy() public {
        vm.startPrank(user);
        liquidityPairs.buy{value: AMOUNT_IN}();
        vm.stopPrank();

        uint256 userBalanceAfter = address(user).balance;
        uint256 userBalanceAfterExpected = 99 ether;
        uint256 actualBalance = liquidityPairs.balances(user);
        uint256 expectedBalance = 249437077808356267200400300;
        uint256 actualTokenReserve = liquidityPairs.tokenReserve();
        uint256 expectedTokenReserve = maxSupply - expectedBalance;
        uint256 actualCollateral = liquidityPairs.collateral();
        uint256 expectedCollateral = virtualETH + AMOUNT_IN;

        assertEq(expectedBalance, actualBalance);
        assertEq(userBalanceAfter, userBalanceAfterExpected);
        assertEq(expectedTokenReserve, actualTokenReserve);
        assertEq(expectedCollateral, actualCollateral);
    }

    function testBuyAfterGraduate() public {
        // buy token first
        vm.startPrank(user);
        liquidityPairs.buy{value: 30 ether}();
        vm.expectRevert(LiquidityPairs.LiquidityPairs__PairAlreadyLock.selector);
        liquidityPairs.buy{value: 1 ether}();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               TEST SELL
    //////////////////////////////////////////////////////////////*/
    function testSell() public {
        // buy token first
        vm.startPrank(user);
        liquidityPairs.buy{value: AMOUNT_IN}();
        vm.stopPrank();
        uint256 userBalanceInPool = liquidityPairs.balances(user);
        // sell token
        vm.startPrank(user);
        liquidityPairs.sell(userBalanceInPool);
        vm.stopPrank();

        uint256 userBalanceAfter = liquidityPairs.balances(user);
        uint256 userBalanceAfterExpected = 0;

        uint256 actualTokenReserveAfter = liquidityPairs.tokenReserve();
        uint256 expectedTokenReserveAfter = maxSupply;

        uint256 actualCollateralAfter = liquidityPairs.collateral();
        // collateralBefore (VIRTUAL ETH ) + AMOUNT_IN - AmountOutWhenSell
        uint256 expectedCollateralAfter = virtualETH + AMOUNT_IN
            - liquidityPairs.calculateAmountOut(userBalanceInPool, maxSupply - userBalanceInPool, virtualETH + AMOUNT_IN);

        assertEq(userBalanceAfter, userBalanceAfterExpected);
        assertEq(expectedTokenReserveAfter, actualTokenReserveAfter);
        assertEq(expectedCollateralAfter, actualCollateralAfter);

        // sell token again (expected error)
        vm.startPrank(user);
        vm.expectRevert();
        liquidityPairs.sell(userBalanceInPool);
        vm.stopPrank();
    }

    function testSellAfterGraduate() public {
        // buy token first
        vm.startPrank(user);
        liquidityPairs.buy{value: 30 ether}();
        vm.stopPrank();
        // sell token
        vm.startPrank(user);
        vm.expectRevert(LiquidityPairs.LiquidityPairs__PairAlreadyLock.selector);
        liquidityPairs.sell(1);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                       TEST CALCULATE AMOUNT OUT
    //////////////////////////////////////////////////////////////*/
    function testGetAmountOut() public {
        vm.startPrank(user);
        uint256 actualAmountOut = liquidityPairs.calculateAmountOut(AMOUNT_IN, virtualETH, maxSupply);
        vm.stopPrank();
        uint256 expectedAmountOut = 249437077808356267200400300;
        assertEq(expectedAmountOut, actualAmountOut);
    }
}
