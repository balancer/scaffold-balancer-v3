

# 🎯 **GovernedLotteryHook Solidity Smart Contract**

## 📝 Overview

The **GovernedLotteryHook** contract is a governance-enabled smart contract integrated with **Balancer’s V3 Vault**, offering a dynamic swap fee structure and a built-in **lottery system**. This contract allows the community to propose and vote on changes to the swap fee percentage and the lucky number for the lottery.

## 🔑 Key Features
- **🗳️ Governance**: Owners can create proposals for modifying swap fees and the lottery’s lucky number, allowing users to vote on them.
- **🎰 Lottery Mechanism**: Users can win the accrued fees during swaps by drawing a matching lucky number.
- **💸 Dynamic Swap Fees**: Swap fees can be adjusted through governance proposals or set manually by the owner.
- **🔒 Secure & Efficient**: Uses OpenZeppelin and Balancer libraries for safe and efficient token operations.

---

## 📦 Contracts and Libraries Used
- **IERC20**: Interface for interacting with ERC20 tokens.
- **Ownable**: Allows only the owner to execute certain functions.
- **SafeERC20**: Ensures safe ERC20 token transfers.
- **IVault & IHooks**: Balancer V3 interfaces for interacting with the vault.
- **FixedPoint**: Provides precise mathematical operations.
- **EnumerableMap**: A mapping structure that allows iteration over key-value pairs.
- **VaultGuard**: Secures interactions with the Balancer Vault.
- **BaseHooks**: A base contract for building custom Balancer hooks.

---

## ⚙️ How It Works

### 1. **🗳️ Governance**
Owners can propose changes to the contract's parameters such as the **swap fee** and **lucky number** using the `createProposal` function. Proposals last for 7 days, allowing users to cast votes. Once the voting period ends, proposals with more votes in favor can be implemented by the owner.

### 2. **🎰 Lottery Mechanism**
For every swap, a random number is drawn. If the random number matches the pre-set **lucky number**, the user wins the accumulated fees. The lucky number can be changed through governance proposals.

### 3. **💸 Swap Fees**
Swap fees are dynamically adjusted by governance or set manually. If no lottery win occurs, a portion of the swap (the fee) is collected and stored until the next lottery.

### 4. **🔢 Random Number Generation**
A pseudo-random number is generated using the `block.prevrandao` and a counter to decide the lottery outcome.

---

## 🔑 Key Functions

### `createProposal(string memory description, uint64 newSwapFeePercentage, uint8 newLuckyNumber)`
Creates a new governance proposal that proposes a change to the swap fee percentage or the lucky number.

### `voteOnProposal(uint256 proposalId, bool support)`
Allows users to cast votes on an active proposal, either supporting or opposing the change.

### `implementProposal(uint256 proposalId)`
Implements the proposal if it has more votes in favor after the voting period ends.

### `onAfterSwap(AfterSwapParams calldata params)`
Handles the lottery logic and adjusts swap fees after every successful swap based on the parameters provided.

### `setHookSwapFeePercentage(uint64 swapFeePercentage)`
Allows the owner to manually adjust the swap fee percentage without a proposal.

### `getHookFlags()`
Returns the configuration flags of the hook for the Balancer Vault.

---

## 🛠️ Events

- **`ProposalCreated(uint256 proposalId, string description)`**: Emitted when a new governance proposal is created.
- **`VoteCast(uint256 proposalId, address voter, bool support)`**: Emitted when a user casts their vote on a proposal.
- **`ProposalImplemented(uint256 proposalId, uint64 newSwapFeePercentage, uint8 newLuckyNumber)`**: Emitted when a proposal is successfully implemented.
- **`LotteryWinningsPaid(address indexed hooksContract, address indexed winner, IERC20 indexed token, uint256 amountWon)`**: Emitted when a user wins the lottery and receives the accumulated fees.

---

## 🚀 Deployment and Setup

1. **🔧 Deploy the contract**: Pass the **Balancer Vault** address and **trusted router** address to the constructor.
2. **🗳️ Governance setup**: The owner (governance) can create proposals to adjust the swap fee or lottery number.
3. **🎰 Users**: Users participating in swaps interact with the lottery system and can vote on governance proposals.

---

## 🔐 Security Considerations

- **Pseudo-randomness**: The contract uses `block.prevrandao` for random number generation, which is not fully secure. Consider this in high-stakes environments.
- **Governance Risks**: Only the contract owner can create proposals and implement changes. Ensure the owner is trusted or implement decentralized governance.

