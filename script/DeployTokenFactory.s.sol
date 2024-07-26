// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

contract DeployTokenFactory is Script{
    function run() public returns (TokenFactory) {
        vm.startBroadcast();
        TokenFactory tokenFactory = new TokenFactory();
        vm.stopBroadcast();
        return tokenFactory;
    }
}