-include .env

# Default chain
CHAIN ?= sepolia 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Conditional assignment based on the CHAIN variable
ifeq ($(CHAIN),sepolia)
RPC_URL = $(SEPOLIA_RPC_URL)
else ifeq ($(CHAIN),ethereum)
RPC_URL = $(MAINNET_RPC_URL)
else ifeq ($(CHAIN),fuji)
RPC_URL = $(FUJI_RPC_URL)

endif


deployTokenFactory:
	forge script script/DeployTokenFactory.s.sol:DeployTokenFactory --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) 

deployStaking:
	forge script script/DeployStaking.s.sol:DeployStaking --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

upgradeStaking:
	forge script script/UpgradeStaking.s.sol:UpgradeStaking --rpc-url $(RPC_URL) \
	 --account defaultKey --sender 0xd2826132FBD5962338e2A37DdC5345A6fE3e6640 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

anvil:
	forge script script/DeployTokenFactory.s.sol:DeployTokenFactory --rpc-url http://127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

compile:
	forge compile

verify-contract:
	forge verify-contract 0x9688197c974B703F61B3B98eC1dDAeB07beC4379 Staking --rpc-url $(RPC_URL)

verify-tokenFactory:
	forge verify-contract 0x303078b83c52Ee1cCa682C54cC6c075267c2256e TokenFactory --rpc-url $(RPC_URL)

