#!/usr/bin/env bash

# Read MNEMONIC from .env file, remove 'export' and quotes
MNEMONIC=$(grep MNEMONIC .env | cut -d '"' -f 2)
PRIVATE_KEY_GATEWAY_DEPLOYER=$(grep PRIVATE_KEY_GATEWAY_DEPLOYER .env | cut -d '"' -f 2)
PRIVATE_KEY_GATEWAY_OWNER=$(grep PRIVATE_KEY_GATEWAY_OWNER .env | cut -d '"' -f 2)
PRIVATE_KEY_GATEWAY_RELAYER=$(grep PRIVATE_KEY_GATEWAY_RELAYER .env | cut -d '"' -f 2)

# Verify that global envs are set
if [ -z "$MNEMONIC" ]; then
    echo "Error: MNEMONIC is not set."
    exit 1
fi
if [ -z "$PRIVATE_KEY_GATEWAY_DEPLOYER" ]; then
    echo "Error: PRIVATE_KEY_GATEWAY_DEPLOYER is not set."
    exit 1
fi
if [ -z "$PRIVATE_KEY_GATEWAY_OWNER" ]; then
    echo "Error: PRIVATE_KEY_GATEWAY_OWNER is not set."
    exit 1
fi
if [ -z "$PRIVATE_KEY_GATEWAY_RELAYER" ]; then
    echo "Error: PRIVATE_KEY_GATEWAY_RELAYER is not set."
    exit 1
fi

# Compute addresses using ethers.js v6 - signers[0] to signers[4] are Alice, Bob, Carol, David and Eve. signers[9] is the fhevm deployer.
addresses=$(node -e "
const { ethers } = require('ethers');
const derivationPath = \"m/44'/60'/0'/0\";
const mnemonicInstance = ethers.Mnemonic.fromPhrase('$MNEMONIC');
const hdNode = ethers.HDNodeWallet.fromMnemonic(mnemonicInstance, derivationPath);
const indices = [0, 1, 2, 3, 4, 9];
for (const i of indices) {
    const childNode = hdNode.derivePath(\`\${i}\`);
    console.log(childNode.address);
}
const deployerAddress = new ethers.Wallet('$PRIVATE_KEY_GATEWAY_DEPLOYER').address;
console.log(deployerAddress);
const ownerAddress = new ethers.Wallet('$PRIVATE_KEY_GATEWAY_OWNER').address;
console.log(ownerAddress);
const relayerAddress = new ethers.Wallet('$PRIVATE_KEY_GATEWAY_RELAYER').address;
console.log(relayerAddress);
" 2>/dev/null)

# Check if addresses were generated successfully
if [ -z "$addresses" ]; then
    echo "Error: Failed to generate addresses."
    exit 1
fi

# Convert the addresses string into an array
IFS=$'\n' read -rd '' -a addressArray <<<"$addresses"

# Loop through each address, strip '0x', and run the Docker command
for addr in "${addressArray[@]}"; do
    addr_no0x=${addr#0x}
    docker exec -i zama-dev-fhevm-validator-1 faucet "$addr_no0x"
    sleep 8
done
