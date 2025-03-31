// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TradingPairFactory} from "../src/TradingPairFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployTradingPairFactory is Script {
    function run() public returns (TradingPairFactory) {
        address proxy = deployTradingPairFactory();
        return TradingPairFactory(proxy);
    }

    function deployTradingPairFactory() public returns (address) {
        vm.startBroadcast();
        TradingPairFactory tradingPairFactory = new TradingPairFactory();
        bytes memory initData = abi.encodeWithSelector(TradingPairFactory.initialize.selector, "");
        ERC1967Proxy proxy = new ERC1967Proxy(address(tradingPairFactory), initData);
        vm.stopBroadcast();
        return address(proxy);
    }
}
