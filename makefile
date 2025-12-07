include .env

FORGE_TEST_SEPOLIA: 
	forge test --fork-url $(SEPOLIA_RPC_URL) -vvvv

FORGE_TEST_MAINNET: 
	forge test --fork-url $(ETH_MAINNET_RPC_URL) -vvvv

Deploy-ANVIL:
		forge script script/DeploySalvaV1.s.sol:DeploySalvaV1 --fork-url $(ANVIL_FORK_URL) --account myAnvilWallet 

DEPLOY-SEPOLIA:
		forge script script/DeploySalvaV1.s.sol:DeploySalvaV1 --fork-url $(SEPOLIA_RPC_URL) --account mainKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

		