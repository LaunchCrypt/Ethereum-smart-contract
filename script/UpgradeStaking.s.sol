// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract UpgradeStaking is Script {
    function run() public returns (address) {
        vm.startBroadcast();
        Staking staking = new Staking();
        vm.stopBroadcast();
        address proxy = upgradeStake(0x3932fEe4B649bDEc1ffD0c002C73E908F5b90C90, address(staking));
        return proxy;
    }

    function upgradeStake(address proxyAddress, address newContract) public returns (address) {
        vm.startBroadcast();
        Staking proxy = Staking(payable(proxyAddress));
        proxy.upgradeToAndCall(newContract, "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
