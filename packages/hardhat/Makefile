-include .env

# Optional flags variable, initially empty
FLAGS :=

# Register a custom pool with the balancer vault. Before running, configure args in the RegisterPool.s.sol script
registerPool:
	forge script scripts/RegisterPool.s.sol --rpc-url sepolia --private-key $(DEPLOYER_PRIVATE_KEY) --slow $(FLAGS) 

# Initialize a custom pool with the balancer vault. Before running, configure args in the InitializePool.s.sol script
initializePool:
	@forge script scripts/InitializePool.s.sol --rpc-url sepolia --private-key $(DEPLOYER_PRIVATE_KEY) --slow $(FLAGS) 