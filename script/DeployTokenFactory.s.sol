// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployTokenFactory is Script {
    HelperConfig helperConfig = new HelperConfig();

    function run() public returns (TokenFactory) {
        address proxy = deployTokenFactory();
        return TokenFactory(proxy);
    }

    function deployTokenFactory() public returns(address) {
        vm.startBroadcast();
        TokenFactory tokenFactory = new TokenFactory();
        bytes memory initData = abi.encodeWithSelector(TokenFactory.initialize.selector, "");
        ERC1967Proxy proxy = new ERC1967Proxy(address(tokenFactory), initData);
        vm.stopBroadcast();

        return address(proxy);
    }
}
