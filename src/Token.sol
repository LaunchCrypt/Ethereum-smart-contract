// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name, string memory ticker, uint256 maxSupply) ERC20(name, ticker) {
        // sender is token factory
        _mint(msg.sender, maxSupply);
    }
}
