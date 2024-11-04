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

    string public constant LOGGING_FILE = "deployed.txt";

    uint256 private DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address private DEFAULT_ANVIL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private OWNER = 0xd2826132FBD5962338e2A37DdC5345A6fE3e6640;

    struct NetworkConfig {
        uint256 deployerKey;
        address owner;
        string network;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // Specify the network configuration based on the chain id
        if (block.chainid == 1) {
            activeNetworkConfig = getEthereumConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaETHConfig();
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getFujiConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                               GET_CONFIG
    //////////////////////////////////////////////////////////////*/

    function getSepoliaETHConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY"), owner: OWNER, network: "Sepolia"});
    }

    function getEthereumConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY"), owner: OWNER, network: "Ethereum"});
    }

    function getFujiConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: vm.envUint("PRIVATE_KEY"), owner: OWNER, network: "Fuji"});
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({deployerKey: DEFAULT_ANVIL_KEY, owner: DEFAULT_ANVIL_OWNER, network: "Anvil"});
    }

    /*//////////////////////////////////////////////////////////////
                               WRITE_FILE
    //////////////////////////////////////////////////////////////*/

    function writeDeployInfo(string memory contractName, address contractAddress) public {
        string memory network = activeNetworkConfig.network;
        string memory path = "deployed.txt";
        
        // Read existing content or initialize empty string
        string memory content;
        try vm.readFile(path) returns (string memory fileContent) {
            content = fileContent;
        } catch {
            content = "";
        }

        // Prepare the new entry
        string memory deployInfo = string.concat(
            contractName,
            ": ",
            vm.toString(contractAddress)
        );

        // Format network header
        string memory networkHeader = string.concat(
            "--------------",
            network,
            "--------------"
        );

        // Check if network section exists and create new content
        if (bytes(content).length == 0) {
            // First entry in the file
            content = string.concat(
                networkHeader,
                "\n",
                deployInfo,
                "\n"
            );
        } else {
            if (!_containsString(content, networkHeader)) {
                // Add new network section
                content = string.concat(
                    content,
                    "\n",
                    networkHeader,
                    "\n",
                    deployInfo,
                    "\n"
                );
            } else {
                // Update existing network section
                content = _updateNetworkSection(
                    content,
                    networkHeader,
                    contractName,
                    deployInfo
                );
            }
        }

        // Write back to file
        vm.writeFile(path, content);
    }

     function _containsString(string memory source, string memory search) internal pure returns (bool) {
        bytes memory sourceBytes = bytes(source);
        bytes memory searchBytes = bytes(search);
        
        if (searchBytes.length > sourceBytes.length) {
            return false;
        }

        for (uint i = 0; i < sourceBytes.length - searchBytes.length + 1; i++) {
            bool found = true;
            for (uint j = 0; j < searchBytes.length; j++) {
                if (sourceBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        return false;
    }

    function _updateNetworkSection(
        string memory content,
        string memory networkHeader,
        string memory contractName,
        string memory newDeployInfo
    ) internal pure returns (string memory) {
        bytes memory contentBytes = bytes(content);
        string memory updatedContent = "";
        bool foundNetwork = false;
        bool updatedContract = false;
        
        // Find network section and update
        string memory line = "";
        for (uint i = 0; i < contentBytes.length; i++) {
            if (contentBytes[i] == bytes1("\n") || i == contentBytes.length - 1) {
                // Process line
                if (_containsString(line, networkHeader)) {
                    foundNetwork = true;
                    updatedContent = string.concat(updatedContent, line, "\n");
                } else if (foundNetwork && _containsString(line, string.concat(contractName, ": "))) {
                    if (!updatedContract) {
                        updatedContent = string.concat(updatedContent, newDeployInfo, "\n");
                        updatedContract = true;
                    }
                } else {
                    if (bytes(line).length > 0) {
                        updatedContent = string.concat(updatedContent, line, "\n");
                    }
                }
                line = "";
            } else {
                line = string.concat(line, _charAt(contentBytes[i]));
            }
        }

        // Add contract info if not updated
        if (foundNetwork && !updatedContract) {
            updatedContent = string.concat(updatedContent, newDeployInfo, "\n");
        }

        return updatedContent;
    }

    function _charAt(bytes1 b) internal pure returns (string memory) {
        bytes memory result = new bytes(1);
        result[0] = b;
        return string(result);
    }
}
