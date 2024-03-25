-include .env

registerPool:
	@forge script scripts/RegisterPool.s.sol --rpc-url sepolia --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast

initializePool:
	@forge script scripts/InitializePool.s.sol --rpc-url sepolia --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast