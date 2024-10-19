
# SafeSwap

SafeSwap is a decentralized automated market maker (AMM) built on the Balancer V3 protocol. It enables liquidity providers to add and remove liquidity in a pool while allowing users to swap between tokens. Additionally, SafeSwap introduces a unique discount mechanism for users holding a specific token, providing them with a 10% discount on swap fees.

## Key Features

- **Balancer V3 Integration**: Built on top of the Balancer V3 protocol with BalancerPoolToken, allowing flexible pool operations.
- **Custom Liquidity Operations**: Custom hooks for adding and removing liquidity.
- **Discount on Swap Fees**: Users holding a specific ERC-20 token are eligible for a 10% discount on the swap fee.
- **Optimized Fee Structure**: The contract enforces a swap fee between 0% and 10%, with a default fee of 10%, reduced if the user qualifies for a discount.

## Contract Structure

### SafeSwap

The `SafeSwap` contract extends the Balancer V3 pool functionality with added customization for liquidity and swaps:

- **Discount Token**: The contract allows setting a discount token, an ERC-20 token. Users holding this token in their wallets receive a reduced swap fee.
- **Swap Fee Logic**: The default swap fee is 10%, which can be reduced by 10% (i.e., down to 9%) if the user holds the discount token.
- **Custom Liquidity Hooks**: Implementations for custom liquidity operations (`onAddLiquidityCustom` and `onRemoveLiquidityCustom`).

### Key Functions

1. **`onSwap`**: Executes a token swap within the pool. If the user holds the discount token, they receive a 10% discount on the swap fee.
   - Parameters:
     - `params`: Pool swap parameters, including token balances and amounts.
   - Returns:
     - `amountCalculatedScaled18`: The calculated amount for the swap, adjusted for the discounted swap fee.

2. **`computeInvariant`**: Calculates the pool's invariant based on the current token balances.

3. **`onAddLiquidityCustom`**: Custom implementation for adding liquidity to the pool.
   - Returns:
     - `amountsInScaled18`: Amount of tokens being added to the pool.
     - `bptAmountOut`: Calculated pool token (BPT) amount the user receives.
     - `swapFeeAmountsScaled18`: The swap fee charged for each token.

4. **`onRemoveLiquidityCustom`**: Custom implementation for removing liquidity from the pool.
   - Returns:
     - `bptAmountIn`: Amount of pool tokens (BPT) burned.
     - `amountsOutScaled18`: Amount of tokens the user receives.
     - `swapFeeAmountsScaled18`: The swap fee charged for each token.

### Discount Logic

The discount logic checks whether the user holds a specific ERC-20 token (the "discount token"). If the user holds this token, they are eligible for a 10% discount on the swap fee.

### Constructor Parameters

The `SafeSwap` contract constructor takes the following parameters:

1. **`IVault vault`**: The Balancer Vault that manages the pool.
2. **`string name`**: Name of the pool token (BPT).
3. **`string symbol`**: Symbol of the pool token (BPT).
4. **`address discountToken`**: The address of the ERC-20 token that provides users with the discount on swap fees.

### Deployment

To deploy the contract, provide the following arguments to the constructor:

```solidity
constructor(
    IVault vault,
    string memory name,
    string memory symbol,
    address _discountToken
)
```

- **`vault`**: Address of the Balancer Vault.
- **`name`**: The name of the Balancer Pool Token (BPT).
- **`symbol`**: The symbol of the Balancer Pool Token (BPT).
- **`_discountToken`**: Address of the ERC-20 token that gives users a swap fee discount.

### Example

Deploying the `SafeSwap` contract:

```solidity
SafeSwap safeSwap = new SafeSwap(
    vaultAddress,
    "SafeSwap Pool Token",
    "SSPT",
    discountTokenAddress
);
```

### Swap Fee Discount Example

If a user holds the specified `discountToken`, they will receive a 10% discount on the swap fee:

- Default swap fee: 10%
- Discounted swap fee: 9% (if the user holds the discount token)

## Installation

To install and run the SafeSwap contract, follow these steps:

1. Clone the repository:

```bash
git clone https://github.com/your-repo/safeswap.git
```

2. Install dependencies:

```bash
npm install
```

3. Compile the contracts:

```bash
npx hardhat compile
```

4. Run tests:

```bash
npx hardhat test
```

## Usage

Once deployed, users can interact with the `SafeSwap` contract to:

1. **Swap tokens** using the `onSwap` function.
2. **Add liquidity** with the `onAddLiquidityCustom` function.
3. **Remove liquidity** with the `onRemoveLiquidityCustom` function.

### Interacting with the Contract

#### Swap Tokens

To execute a swap, call the `onSwap` function:

```solidity
safeSwap.onSwap(swapParams);
```

If the user holds the discount token, the swap fee will automatically be reduced.

#### Add Liquidity

To add liquidity, call the `onAddLiquidityCustom` function:

```solidity
safeSwap.onAddLiquidityCustom(router, maxAmountsInScaled18, minBptAmountOut, balancesScaled18, userData);
```

#### Remove Liquidity

To remove liquidity, call the `onRemoveLiquidityCustom` function:

```solidity
safeSwap.onRemoveLiquidityCustom(router, maxBptAmountIn, minAmountsOutScaled18, balancesScaled18, userData);
```
