#!/bin/bash

npx hardhat clean
PRIVATE_KEY_GATEWAY_DEPLOYER=$(grep PRIVATE_KEY_GATEWAY_DEPLOYER .env | cut -d '"' -f 2)
npx hardhat task:computeACLAddress --network hardhat
npx hardhat task:computeTFHEExecutorAddress --network hardhat
npx hardhat task:computeKMSVerifierAddress --network hardhat
npx hardhat task:computePredeployAddress --private-key "$PRIVATE_KEY_GATEWAY_DEPLOYER" --network hardhat

# Paths to input files
ENV_EXEC="node_modules/fhevm/lib/.env.exec"
ENV_GATEWAY="node_modules/fhevm/gateway/.env.gateway"
ENV_FILE=".env"

# Path to output file
ENV_DOCKER=".env.docker"

# Check if input files exist
for file in "$ENV_EXEC" "$ENV_GATEWAY" "$ENV_FILE"; do
    if [ ! -f "$file" ]; then
        echo "Error: $file does not exist."
        exit 1
    fi
done

# Extract values
TFHE_EXECUTOR_CONTRACT_ADDRESS=$(grep "^TFHE_EXECUTOR_CONTRACT_ADDRESS=" "$ENV_EXEC" | cut -d'=' -f2)
GATEWAY_CONTRACT_PREDEPLOY_ADDRESS=$(grep "^GATEWAY_CONTRACT_PREDEPLOY_ADDRESS=" "$ENV_GATEWAY" | cut -d'=' -f2)
GATEWAY_CONTRACT_PREDEPLOY_ADDRESS_NO0X=${GATEWAY_CONTRACT_PREDEPLOY_ADDRESS#0x}
PRIVATE_KEY_GATEWAY_RELAYER=$(grep PRIVATE_KEY_GATEWAY_RELAYER .env | cut -d '"' -f 2)

# Write to .env.docker
{
    echo "TFHE_EXECUTOR_CONTRACT_ADDRESS=$TFHE_EXECUTOR_CONTRACT_ADDRESS"
    echo "GATEWAY_CONTRACT_PREDEPLOY_ADDRESS=$GATEWAY_CONTRACT_PREDEPLOY_ADDRESS_NO0X"
    echo "PRIVATE_KEY_GATEWAY_RELAYER=$PRIVATE_KEY_GATEWAY_RELAYER"
} > "$ENV_DOCKER"
echo "Successfully created $ENV_DOCKER with the aggregated environment variables."