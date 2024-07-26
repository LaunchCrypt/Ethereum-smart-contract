// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = (10 ** 9) * (10 ** DECIMALS);
    uint256 public constant FUNDING_GOAL = 30 * (10 ** DECIMALS);
    uint256 public constant INITIAL_VIRTUAL_ETH = 3 * (10 ** DECIMALS);
    uint256 public constant MINIUM_TOKEN_LIQUIDITY = MAX_SUPPLY * 20 / 100;
    uint256 public constant FEE = 3; // 0.3%

    uint256 private DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address private DEFAULT_ANVIL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private OWNER = 0xd2826132FBD5962338e2A37DdC5345A6fE3e6640;

    struct NetworkConfig {
        uint256 deployerKey;
        address owner;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // Specify the network configuration based on the chain id
        if (block.chainid == 1) {
            activeNetworkConfig = getEthereumConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaETHConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaETHConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY"), owner: OWNER});
    }

    function getEthereumConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY"), owner: OWNER});
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: DEFAULT_ANVIL_KEY, owner: DEFAULT_ANVIL_OWNER});
    }
}
