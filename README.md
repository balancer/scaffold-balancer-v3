# Volatility and Loyalty Hook for Balancer V3 Hackathon

The Volatility and Loyalty Hook aims to stimulate trading activity in a newly launched pool on Balancer by rewarding users with discounts on swap fees when they hold project tokens for a longer duration. It simultaneously ensures stability by increasing swap fees during periods of high volatility.

## Contents
- [Hook Lifecycle Points](#hook-lifecycle-points)
- [Swap Fee Calculation](#swap-fee-calculation)
  - [Swap Fee with Loyalty Discount](#swap-fee-with-loyalty-discount)
  - [Volatility Fee](#volatility-fee)
- [Volatility Percentage Calculation](#volatility-percentage-calculation)
- [References](#references)

## Hook Lifecycle Points

- **onAfterRemoveLiquidity(), onAfterAddLiquidity():**  
  Updates the new token price in the Volatility Oracle along with the timestamps.
  
- **onAfterSwap():**  
  Updates the new token price in the Volatility Oracle along with the timestamps.  
  Updates the loyalty index of the user.

- **onComputeDynamicSwapFeePercentage():**  
  Calculates the swap fee based on the pool's volatility and the user's loyalty index.

![Balancer Hook Diagram](https://github.com/user-attachments/assets/6453b5b8-03ad-4108-bc66-228cc684716f)

## Swap Fee Calculation

The swap fee is calculated as the sum of the **swapFeeWithLoyaltyDiscount** and the **volatilityFee**.

### Swap Fee with Loyalty Discount

This reduces the static swap fee but maintains a **minimum fee** and a **cap on the loyalty discount** to prevent exploitation by large holders (whales).

- **Minimum fee that must be paid:** 1%
- **Cap on loyalty discount:** 1%

Let’s assume `MAX_LOYALTY_FEE = 1%`. The logic is as follows:

- If `staticSwapFee <= 1%`:  
  `swapFeeWithLoyaltyDiscount = staticSwapFee`
  
- If `1% < staticSwapFee < 2%` (1% + `MAX_LOYALTY_FEE`):  
  `swapFeeWithLoyaltyDiscount = 1% + (staticSwapFee - 1%) * (1 - loyaltyPercentage)`

- If `staticSwapFee == 2%` (1% + `MAX_LOYALTY_FEE`):  
  `swapFeeWithLoyaltyDiscount = 1% + MAX_LOYALTY_FEE * (1 - loyaltyPercentage)`

- Else:  
  `swapFeeWithLoyaltyDiscount = 1% + MAX_LOYALTY_FEE * (1 - loyaltyPercentage) + (staticSwapFee - 1% - MAX_LOYALTY_FEE)`

#### Loyalty Percentage Calculation

We calculate a **loyaltyIndex** based on the time the tokens have been held, preventing **flash loan attacks**:

`newLoyaltyIndex = previousLoyaltyIndex + (tokens held at the previous transaction) * (current timestamp - previous swap transaction timestamp)`

Using this **loyaltyIndex**, we calculate the **loyaltyPercentage** through a tier-based system.

The loyalty index is refreshed if the previous transaction occurred more than **_LOYALTY_REFRESH_WINDOW** (30 days) ago.

### Volatility Fee

`volatilityFee = MAX_VOLATILITY_FEE * volatilityPercentage`

## Volatility Percentage Calculation

The volatility percentage is calculated using a circular buffer to maintain a history of price and timestamp objects. The buffer ensures price updates are stored at intervals of, for example, 2 minutes. If an update occurs within this interval, the previous entry is overwritten; if it occurs later, a new entry is added.

Once the prices over a span of time are captured, the price 1 hour ago (or a shorter duration for demo purposes) is extracted using **binary search** from the oracle.

The formula for calculating volatility is:

<img width="378" alt="Screenshot 2024-10-21 at 1 58 47 AM" src="https://github.com/user-attachments/assets/02f19b11-0132-400c-a19a-5a3db1834584">

Where:
- **tf** and **ti** are the final and initial timestamps of the samples collected from the buffer for the last **ago** seconds.

The unit of volatility is **% price change per second**. A tier-based system is then used to calculate the **volatility fee percent**.

## References
- Implementation of PriceOracle in Balancer V2:  
  [Etherscan](https://etherscan.deth.net/address/0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0)
