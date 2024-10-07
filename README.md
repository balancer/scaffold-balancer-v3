
# SafeSwap Contract

The **SafeSwap** contract is an implementation based on the **Balancer V3 protocol**, designed to manage token swaps, liquidity additions, and liquidity removals in a decentralized way. This contract introduces custom hooks for liquidity operations and operates within the Balancer V3 framework, leveraging mathematical invariants and swap fees.

## Overview

The contract extends the core components of Balancer V3:
- **BalancerPoolToken**: This provides the functionality of an ERC-20 compliant pool token, which represents the user's share in the liquidity pool.
- **IPoolLiquidity**: This is an interface that manages the core pool liquidity operations.
- **FixedPoint**: A math library that allows for accurate fixed-point arithmetic.

### Key Constants

- `_MIN_SWAP_FEE_PERCENTAGE`: Minimum swap fee percentage, set to `0`.
- `_MAX_SWAP_FEE_PERCENTAGE`: Maximum swap fee percentage, capped at `10%` (0.1e18).

## Constructor

The constructor initializes the `BalancerPoolToken` with the provided vault, pool name, and symbol.

### Parameters:
- **vault**: The Balancer vault where the pool is registered.
- **name**: Name of the pool token.
- **symbol**: Symbol of the pool token.

---

## Core Functions

### 1. **`onSwap`** 
   - **Purpose**: Executes a swap in the pool by calculating the output token amount.
   - **Parameters**: 
     - `PoolSwapParams calldata params`: Contains balances and amount details for the swap.
   - **Returns**: `amountCalculatedScaled18`: The calculated amount of the output token.
   - **Logic**: 
     - It uses a formula to compute the new balance of the output token based on the input token and respective balances.
     - Formula: 
       ```
       amountCalculatedScaled18 = (params.balancesScaled18[params.indexOut] * params.amountGivenScaled18) 
                                  / (params.balancesScaled18[params.indexIn] + params.amountGivenScaled18)
       ```

### 2. **`computeInvariant`** 
   - **Purpose**: Computes the pool’s invariant, which is a mathematical property representing the pool’s balance state.
   - **Parameters**: 
     - `balancesLiveScaled18`: An array of current pool balances (scaled to 18 decimals).
   - **Returns**: `invariant`: The calculated invariant as a `uint256`.
   - **Logic**: 
     - The invariant is computed by multiplying all token balances and taking the square root to get a balance ratio between tokens.

### 3. **`computeBalance`** 
   - **Purpose**: Computes the new balance of a token after a liquidity operation based on the invariant growth ratio.
   - **Parameters**: 
     - `balancesLiveScaled18`: Current balances for tokens.
     - `tokenInIndex`: The index of the token for which the balance is computed.
     - `invariantRatio`: The ratio of the new invariant to the old one.
   - **Returns**: `newBalance`: The new balance of the token.
   - **Logic**: 
     - Uses the invariant formula to calculate how the balance of a token would change after a liquidity change.

### 4. **`getMinimumSwapFeePercentage`** 
   - **Purpose**: Returns the minimum swap fee percentage for a pool (which is 0).
   - **Returns**: `_MIN_SWAP_FEE_PERCENTAGE`.

### 5. **`getMaximumSwapFeePercentage`** 
   - **Purpose**: Returns the maximum swap fee percentage (10%).
   - **Returns**: `_MAX_SWAP_FEE_PERCENTAGE`.

---

## Custom Liquidity Hooks

### 6. **`onAddLiquidityCustom`** 
   - **Purpose**: Custom logic for adding liquidity to the pool.
   - **Parameters**:
     - `router`: The address that initiated the add liquidity operation.
     - `maxAmountsInScaled18`: Maximum input amounts per token (scaled to 18 decimals).
     - `minBptAmountOut`: Minimum output of pool tokens (BPT).
     - `balancesScaled18`: Current pool balances (scaled to 18 decimals).
     - `userData`: Arbitrary data sent with the request.
   - **Returns**: 
     - `amountsInScaled18`: Actual input amounts of tokens.
     - `bptAmountOut`: Amount of pool tokens to be minted.
     - `swapFeeAmountsScaled18`: Swap fees charged for each token.
     - `returnData`: Custom return data.
   - **Logic**: 
     - It calculates the invariant before and after the liquidity addition.
     - Updates the balances of tokens and returns the amount of pool tokens to mint.

### 7. **`onRemoveLiquidityCustom`** 
   - **Purpose**: Custom logic for removing liquidity from the pool.
   - **Parameters**:
     - `router`: The address that initiated the remove liquidity operation.
     - `maxBptAmountIn`: Maximum amount of pool tokens to burn.
     - `minAmountsOutScaled18`: Minimum output amounts of each token.
     - `balancesScaled18`: Current pool balances (scaled to 18 decimals).
     - `userData`: Arbitrary data sent with the request.
   - **Returns**:
     - `bptAmountIn`: Amount of pool tokens burned.
     - `amountsOutScaled18`: Amount of tokens withdrawn.
     - `swapFeeAmountsScaled18`: Swap fees charged for each token.
     - `returnData`: Custom return data.
   - **Logic**: 
     - It calculates the invariant before and after the liquidity removal.
     - Reduces the pool token balances and returns the number of pool tokens burned.



