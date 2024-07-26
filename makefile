-include .env

# Default chain
CHAIN ?= sepolia 

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
	
compile:
	forge compile
