// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;
    // 1 billion tokens
    uint256 public constant MAX_SUPPLY = (10 ** 9) * (10 ** DECIMALS);

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error Token__MaxSupplyExceeded();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name, string memory ticker)
        ERC20(name, ticker)
    {
        // sender is token factory
        _mint(msg.sender, MAX_SUPPLY);
    }
}
