// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployStaking is Script {
    HelperConfig helperConfig = new HelperConfig();

    function run() public returns (address) {
        address proxy = deployStaking();
        return proxy;
    }

    function deployStaking() public returns (address) {
        vm.startBroadcast();
        Staking staking = new Staking();
        bytes memory initData = abi.encodeWithSelector(Staking.initialize.selector, "");
        ERC1967Proxy proxy = new ERC1967Proxy(address(staking), initData);
        vm.stopBroadcast();
        return address(proxy);
    }
}
