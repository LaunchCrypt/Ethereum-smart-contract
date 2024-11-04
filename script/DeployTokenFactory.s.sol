// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployTokenFactory is Script {
    function run() public returns (TokenFactory) {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        TokenFactory tokenFactory = new TokenFactory();
        vm.stopBroadcast();

        // Write the contract address to a file
        address contractAddress = address(tokenFactory);
        helperConfig.writeDeployInfo("TokenFactory", contractAddress);
        
        return tokenFactory;
    }
}
