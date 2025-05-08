// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {TradingPairFactory} from "../src/TradingPairFactory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract UpgradeTradingPairFactory is Script {
    function run() public returns (address) {
        vm.startBroadcast();
        TradingPairFactory tradingPairFactory = new TradingPairFactory();
        vm.stopBroadcast();
        address proxy =
            upgradeTradingPairFactory(0xbDBb01588BA0817aB9D2050DE32B8911348d4307, address(tradingPairFactory));
        return proxy;
    }

    function upgradeTradingPairFactory(address proxyAddress, address newContract) public returns (address) {
        vm.startBroadcast();
        TradingPairFactory proxy = TradingPairFactory(proxyAddress);
        proxy.upgradeToAndCall(newContract, "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
