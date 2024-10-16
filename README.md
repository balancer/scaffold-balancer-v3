
# 🎲 GovernedLotteryHook Contract (with Governance)

The `GovernedLotteryHook` contract is an advanced smart contract that integrates a lottery mechanism with governance features. It serves as a hook for token swaps within the Balancer V3 protocol, adding a fun and community-driven layer to the swap process through a lottery system, while also allowing the community or contract owner to govern key parameters such as the swap fee and lucky number.

## 🔑 Key Features

- **Swap Fee Hook**: The contract allows a percentage-based swap fee to be applied to every token swap, which can be adjusted via governance.
- **Lottery System**: Users participate in a lottery on each swap. If a lucky number is drawn, the user wins the accrued fees.
- **Governance Proposals**: The contract includes a governance mechanism where proposals for key parameter changes (e.g., fee percentage, lucky number) can be voted on by users.
- **Trusted Router**: Only swaps executed through a specified trusted router can participate in the lottery.
- **Accrued Fees**: The fees are collected and stored in the contract until a lottery winner is drawn.

## 📝 Contract Summary

The contract is designed to serve as both a lottery mechanism for swaps and a governed system where proposals can be created, voted on, and implemented by the community or owner. 

### ⚙️ Constructor

```solidity
constructor(IVault vault, address router) VaultGuard(vault) Ownable(msg.sender)
```

- **Vault**: The contract is deployed with a reference to the Balancer vault.
- **Router**: The `router` is the trusted source of swaps that are eligible for the lottery.

### 🗳️ Governance

The contract supports the creation, voting, and implementation of governance proposals. The governance proposals allow adjustments to important parameters, such as:

- **Swap Fee Percentage** (`hookSwapFeePercentage`)
- **Lucky Number** (`LUCKY_NUMBER`)

#### `createProposal`

```solidity
function createProposal(
    string memory description, 
    uint64 newSwapFeePercentage, 
    uint8 newLuckyNumber
) external onlyOwner
```

- **Description**: A text description of the proposal.
- **New Swap Fee Percentage**: The proposed new swap fee percentage.
- **New Lucky Number**: The proposed new lucky number for the lottery.
- **Owner Only**: Only the contract owner can create proposals.

#### `voteOnProposal`

```solidity
function voteOnProposal(uint256 proposalId, bool support) external
```

- Users can vote either **for** or **against** a proposal.
- Each address can only vote once per proposal.

#### `implementProposal`

```solidity
function implementProposal(uint256 proposalId) external onlyOwner
```

- After the voting period ends, if the votes **for** the proposal exceed the votes **against**, the proposal is implemented.
- The contract updates its parameters (`hookSwapFeePercentage` and `LUCKY_NUMBER`) based on the proposal’s contents.

### 🎰 Lottery Mechanism

#### `onAfterSwap`

```solidity
function onAfterSwap(
    AfterSwapParams calldata params
) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw)
```

- This is the core function of the lottery. It is triggered after every swap.
- The contract draws a random number for each swap.
- If the random number matches the **lucky number**, the user wins the accrued fees.

#### `_chargeFeeOrPayWinner`

```solidity
function _chargeFeeOrPayWinner(
    address router, 
    uint8 drawnNumber, 
    IERC20 token, 
    uint256 hookFee
) private returns (uint256)
```

- If the random number equals the **lucky number**, the user wins the accrued fees for all eligible tokens.
- If the drawn number does not match, the fees are collected and stored in `_tokensWithAccruedFees` for future lottery payouts.

### 🔄 Adjustable Parameters

- **Lucky Number**: The lucky number is initially set to `10` and can be changed via governance proposals.
- **Swap Fee Percentage**: The swap fee percentage can be set by the owner and changed via governance proposals. This determines the fee charged on each swap.

### 🔒 Security & Access Control

- **Ownable**: The contract uses the OpenZeppelin `Ownable` pattern, allowing the owner to perform critical actions like creating proposals and implementing them.
- **VaultGuard**: The contract ensures that only the Balancer Vault can trigger certain functions.
- **Governance Voting**: Users can participate in governance by voting on proposals to adjust the lottery parameters.

## 🔍 Functions Overview

| Function                   | Description                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------- |
| `onRegister`               | Registers the hook with a Balancer pool.                                               |
| `getHookFlags`             | Returns flags to enable the hook's adjusted amounts and trigger the call after a swap. |
| `onAfterSwap`              | Executes after each swap, applying fees and triggering the lottery mechanism.          |
| `createProposal`           | Creates a new governance proposal for changing the swap fee or lucky number.           |
| `voteOnProposal`           | Allows users to vote on a proposal.                                                    |
| `implementProposal`        | Implements a governance proposal if it has enough support.                             |
| `_chargeFeeOrPayWinner`    | Internal function that either collects the swap fee or pays out a lottery winner.      |
| `setHookSwapFeePercentage` | Allows the owner to manually set the swap fee percentage.                              |

## 📦 Deployment

1. **Prerequisites**:
   - The contract requires the address of a Balancer Vault.
   - The address of a **trusted router** must be specified for lottery participation.

2. **Deploying the Contract**:

```solidity
IVault vault = IVault(vaultAddress);
address router = trustedRouterAddress;

GovernedLotteryHook lotteryHook = new GovernedLotteryHook(vault, router);
```

Once deployed, the contract starts managing swaps, collecting fees, and enabling users to participate in the lottery and governance system.

## ⚠️ Important Notes

- **Owner-Managed Governance**: While the contract supports proposals and voting, the owner retains the ability to implement proposals and set swap fees.
- **Random Number Generation**: The random number for the lottery is generated using `block.prevrandao` and an internal counter. This provides basic randomness but may not be secure in highly adversarial environments.
- **Accrued Fees**: The contract accumulates fees over time until a user wins the lottery, so it must maintain a balance to support future payouts.

## 📜 Events

- **ProposalCreated**: Emitted when a new governance proposal is created.
- **VoteCast**: Emitted when a user casts a vote on a proposal.
- **ProposalImplemented**: Emitted when a proposal is successfully implemented.
- **LotteryWinningsPaid**: Emitted when a user wins the lottery, with details of the token and amount won.

