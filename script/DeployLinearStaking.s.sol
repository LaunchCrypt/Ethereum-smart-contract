// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {LinearStaking} from "../src/LinearStaking.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployLinearStaking is Script {
    HelperConfig helperConfig = new HelperConfig();

    function run() public returns (address) {
        address proxy = deployLinearStaking();
        return proxy;
    }

    function deployLinearStaking() public returns (address) {
        vm.startBroadcast();
        LinearStaking linearStaking = new LinearStaking();
        bytes memory initData = abi.encodeWithSelector(LinearStaking.initialize.selector, "");
        ERC1967Proxy proxy = new ERC1967Proxy(address(linearStaking), initData);
        vm.startBroadcast();
        return address(proxy);
    }
}
