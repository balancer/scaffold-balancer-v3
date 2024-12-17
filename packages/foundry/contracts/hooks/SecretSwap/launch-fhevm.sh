#!/bin/bash

# Assumes the following:
# 1. Predeploys addresses have been precomputed via the precomputeAddresses.sh script.
# 2. A local and **fresh** fhEVM node is already running.
# 3. All test addresses are funded (e.g. via the fund_test_addresses.sh script).

npx hardhat compile:specific --contract contracts

mkdir -p fhevmTemp
cp -L -r node_modules/fhevm fhevmTemp/
npx hardhat compile:specific --contract fhevmTemp/fhevm/lib
npx hardhat compile:specific --contract fhevmTemp/fhevm/gateway
mkdir -p abi
cp artifacts/fhevmTemp/fhevm/lib/TFHEExecutor.sol/TFHEExecutor.json abi/TFHEExecutor.json

npx hardhat task:deployACL
npx hardhat task:deployTFHEExecutor
npx hardhat task:deployKMSVerifier

npx hardhat task:launchFhevm --skip-get-coin true

rm -rf fhevmTemp