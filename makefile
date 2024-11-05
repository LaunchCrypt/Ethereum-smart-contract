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


deploy:
	forge script script/DeployTokenFactory.s.sol:DeployTokenFactory --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) 

anvil:
	forge script script/DeployTokenFactory.s.sol:DeployTokenFactory --rpc-url http://127.0.0.1:8545/ --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
	
compile:
	forge compile

verify-contract:
	forge verify-contract 0x40812cDE6F279A97A43b82824bf3CfD022465b2d LiquidityPairs --rpc-url $(RPC_URL) --show-standard-json-input


