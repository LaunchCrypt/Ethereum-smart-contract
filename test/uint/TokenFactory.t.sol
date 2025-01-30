// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../../src/TokenFactory.sol";
import {DeployTokenFactory} from "../../script/DeployTokenFactory.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////
                                 SET UP
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_SUPPLY = 1000000000 * 10 ** 18;
    uint256 public initialMint;
    TokenFactory public tokenFactory;
    DeployTokenFactory public deployer;
    HelperConfig public helperConfig;

    address user = makeAddr("USER");

    function setUp() public {
        deployer = new DeployTokenFactory();
        tokenFactory = deployer.run();
        helperConfig = new HelperConfig();
        initialMint = helperConfig.MAX_SUPPLY();
    }

    /*//////////////////////////////////////////////////////////////
                           TEST CREATE TOKEN
    //////////////////////////////////////////////////////////////*/
    function testCreateToken() public {
        vm.startPrank(user);
        (address tokenAddress,) = tokenFactory.createToken("Test Token", "TT", MAX_SUPPLY, 3);
        vm.stopPrank();

        uint256 expectedTotalSupply = initialMint;
        uint256 actualTotalSupply = IERC20(tokenAddress).totalSupply();

        uint256 expectedBalanceOfFactory = 0;
        uint256 actualBalanceOfFactory = IERC20(tokenAddress).balanceOf(address(tokenFactory));

        assertEq(expectedBalanceOfFactory, actualBalanceOfFactory);
        assertEq(expectedTotalSupply, actualTotalSupply);
    }
}
