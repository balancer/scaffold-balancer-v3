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
 <img width="1460" alt="Excalidraw" src="https://github.com/user-attachments/assets/4fa5aeaf-7e38-4a9e-a9b6-6c294030e2ce">

2. **Encrypted Transfers:**
   - User can transfer his credits in confidential way (hidden amount to different users)  
   <img width="1549" alt="Excalidraw" src="https://github.com/user-attachments/assets/34d21710-c3fd-45cc-b38a-c0a34f7c017d">

3. **Withdraw:**
   - When a user withdraws (operation `2`), their **encrypted credits** are decrypted using Zama's Co-Processor Model, and the corresponding token amounts are transferred back to the user.
   - Users can withdraw their full balance in both `tokenA` and `tokenB` based on their current credit value.
  <img width="1514" alt="Cursor_and_Excalidraw" src="https://github.com/user-attachments/assets/8c0d83d0-061b-4dfd-9f1a-000a63e95393">
   
4. **Standard Swap:**
   - If no operation is specified (or an invalid operation is provided), the tokens proceed with a standard Balancer V3 swap.

### Key Features
- **Confidentiality:** All operations are handled in a privacy-preserving manner using FHE, ensuring that no sensitive information is leaked on-chain.
- **Flexible Swaps:** Users can seamlessly perform standard token swaps alongside confidential deposits and withdrawals.
- **Encrypted Credits:** Token balances are encrypted and managed using FHE, enabling secure, private transactions.
- **Decryption via Callback:** Upon withdrawal, encrypted credit balances are decrypted using the FHE gateway, and tokens are securely transferred to the user.

### Overview of FHE Code in the Contract

This contract implements a confidential token swapping system using Fully Homomorphic Encryption (FHE) provided by the TFHE library. Users can deposit tokens and receive encrypted credits, transfer these encrypted credits between users, and withdraw tokens by decrypting their credits. Below is a breakdown of the three key operations: deposit, transfer, and withdraw.

### How Fully Homomorphic Encryption (FHE) is Used

**TFHE (Transciphering Fully Homomorphic Encryption)** allows computations to be done on encrypted data without decrypting it. In this contract, user balances are stored and manipulated in an encrypted form using `euint64` (encrypted 64-bit unsigned integers). This ensures that the sensitive balance information remains confidential throughout deposits, transfers, and withdrawals.

The contract leverages TFHE to:
1. **Encrypt** balances and perform operations such as addition and subtraction while the data is encrypted.
2. **Decrypt** balances only when a withdrawal request is made, ensuring privacy throughout the token lifecycle.

---

### Operations

#### 1. **Deposit Operation**

**What it does:**  
When a user deposits tokens into the contract, an equivalent amount of encrypted credits is assigned to their account. This allows the user to keep their token holdings confidential.

**Code Snippet:**
```solidity
function _depositToken(address router, IERC20 token, uint256 amount) private returns (uint256) {
    address user = IRouterCommon(router).getSender();
    if (amount > 0) {
        _vault.sendTo(token, address(this), amount);
        userAddressToCreditValue[user][token] = TFHE.add(
            userAddressToCreditValue[user][token],
            TFHE.asEuint64(amount / DIVISION_FACTOR)
        );
        emit TokenDeposited(address(this), token, amount);
    }
    return amount;
}
```

**Explanation:**  
- The user deposits tokens.
- The tokens are transferred to the vault.
- The corresponding encrypted credits (`euint64`) are added to the user’s encrypted balance.

---

#### 2. **Encrypted Credits Transfer Operation**

**What it does:**  
Users can transfer their encrypted credits to another user without revealing the actual amount. This allows private transfers of balances.

**Code Snippet:**
```solidity
function transferCredits(address to, IERC20 token, einput encryptedAmount, bytes calldata inputProof) public {
    euint64 amount = TFHE.asEuint64(encryptedAmount, inputProof);
    ebool canTransfer = TFHE.le(amount, userAddressToCreditValue[msg.sender][token]);
    _transfer(msg.sender, to, amount, canTransfer, token);
}
```

**Explanation:**  
- The sender transfers encrypted credits to another user.
- The transfer is validated to ensure the sender has enough credits.
- The encrypted amount is transferred between users without revealing the actual value.

---

#### 3. **Withdraw Operation**

**What it does:**  
When a user wants to withdraw tokens, the contract decrypts the encrypted credits and transfers the corresponding tokens back to the user.

**Code Snippet:**
```solidity
function _withdrawToken(address router, IERC20 token1, IERC20 token2) private returns (uint256) {
    address user = IRouterCommon(router).getSender();
    euint64 token1Amount = TFHE.isInitialized(userAddressToCreditValue[user][token1])
        ? userAddressToCreditValue[user][token1]
        : TFHE.asEuint64(0);
    
    euint64 token2Amount = TFHE.isInitialized(userAddressToCreditValue[user][token2])
        ? userAddressToCreditValue[user][token2]
        : TFHE.asEuint64(0);

    // Request decryption and transfer tokens
    uint256 requestId = Gateway.requestDecryption(
        cts,
        this.callBackResolver.selector,
        0,
        block.timestamp + 100,
        false
    );

    requestIdToCallBackStruct[requestId] = CallBackStruct(user, token1, token2);
    return 0;
}
```

**Explanation:**  
- The user's encrypted balance is decrypted through a callback.
- After decryption, the corresponding tokens are transferred back to the user.

---

### Summary of the Operations

- **Deposit:** Users deposit tokens and receive encrypted credits in return, ensuring their balances remain confidential.
- **Transfer:** Users can transfer encrypted credits to others, allowing private balance transfers without revealing the token amount.
- **Withdraw:** Users can withdraw tokens by decrypting their encrypted credits, and the corresponding token value is transferred back.
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
