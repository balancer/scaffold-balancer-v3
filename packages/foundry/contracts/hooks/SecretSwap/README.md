## SecretSwap: Confidential Swaps 

SecretSwap allows users to perform confidential token swaps using Balancer V3 hooks and Fully Homomorphic Encryption (FHE) provided by Zama's Co-Processor Model. Users can choose to either:
- **Deposit tokens** into the contract (operation `1`)
- **Withdraw tokens** (operation `2`)
- **Perform a standard swap** without any operation specified.

### Secret Swap Demo 
https://www.loom.com/share/f5449f193f3441999f08af62047f4fa2?sid=8b221c9b-51a3-484f-aed1-bee617843ed3

### How FHE co-processor works
https://github.com/zama-ai/fhevm-L1-demo/blob/main/EthCC24-tkms.pdf


### How It Works

1. **Deposit:**
   - When a user performs a deposit (operation `1`), their tokens are securely transferred to the contract, and they receive **encrypted credits** representing their balance.
   - The contract uses FHE to keep the user's balance confidential, and credits are stored securely.
   
   
2. **Withdraw:**
   - When a user withdraws (operation `2`), their **encrypted credits** are decrypted using Zama's Co-Processor Model, and the corresponding token amounts are transferred back to the user.
   - Users can withdraw their full balance in both `tokenA` and `tokenB` based on their current credit value.

3. **Standard Swap:**
   - If no operation is specified (or an invalid operation is provided), the tokens proceed with a standard Balancer V3 swap.

### Key Features
- **Confidentiality:** All operations are handled in a privacy-preserving manner using FHE, ensuring that no sensitive information is leaked on-chain.
- **Flexible Swaps:** Users can seamlessly perform standard token swaps alongside confidential deposits and withdrawals.
- **Encrypted Credits:** Token balances are encrypted and managed using FHE, enabling secure, private transactions.
- **Decryption via Callback:** Upon withdrawal, encrypted credit balances are decrypted using the FHE gateway, and tokens are securely transferred to the user.

### Operations
- **Operation 1 (Deposit):** Deposit tokens into the SecretSwap contract. Users receive encrypted credits.
- **Operation 2 (Withdraw):** Withdraw tokens based on the encrypted credits.
- **No Operation:** Perform a normal swap using Balancer V3 without any encrypted actions.

---

### Setup and Run Instructions

### Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://docs.docker.com/engine/install/)
- [pnpm](https://pnpm.io/installation)
- Node.js (version 20 or higher)

### 1. Clone the Repository

```bash
git clone https://github.com/zama-ai/fhevm-hardhat-template
cd fhevm-hardhat-template
```

### 2. Install Dependencies

```bash
pnpm install
```

### 3. Set Up `.env` File

```bash
cp .env.example .env
```

Generate a mnemonic using [this tool](https://iancoleman.io/bip39/) and paste it into the `.env` file.

### 4. Start fheVM

To start the local FHEVM environment using Docker:

```bash
pnpm fhevm:start
```

Wait until the blockchain logs are printed, indicating that the setup is complete.

### 5. Run Tests

In another terminal, run the tests to verify the contracts:

```bash
pnpm test
```

### 6. Stop fheVM

When you are finished, stop the local node:

```bash
pnpm fhevm:stop
```

### Contract Compilation

To compile the contracts:

```bash
pnpm compile
```

### Further Testing

To run tests in mocked mode (faster), use:

```bash
pnpm test:mock
```

To analyze test coverage:

```bash
pnpm coverage:mock
```

---

## License

This project is licensed under the MIT License.

---

This README provides a clear explanation of how SecretSwap works, instructions for setup, and testing guidance for running the contracts on the `fhevm` using Balancer V3 hooks.