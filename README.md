# 🏗︎ Balancer v3 Hooks

## LP Incentivized Hook

The **LPIncentive Hook** is a smart contract designed to incentivize liquidity providers (LPs) based on both the volume of liquidity they provide and the duration for which they keep their liquidity in the pool. This hook allows protocols to reward LPs with more granular control by using these two factors to calculate rewards, ensuring that long-term and high-volume liquidity providers are appropriately rewarded.

### What the hook does

1. Volume-Based Incentive:

**Liquidity Volume:** 
The hook tracks the total volume of liquidity an LP adds to the pool. As LPs reach certain predefined volume milestones, they unlock higher tiers of rewards.

**Milestone-Based Rewards:** 
For example, if an LP provides liquidity exceeding certain thresholds (e.g., 10,000 tokens, 50,000 tokens, etc.), they are entitled to receive higher rewards, such as extra tokens or fee rebates.

2. Time-Based Incentive:

**Holding Duration:** 
LPs are incentivized to keep their liquidity in the pool for a longer period. The longer an LP keeps liquidity staked in the pool without withdrawing, the higher their rewards.

**Reward Vesting:** 
LP rewards are distributed based on how long the liquidity has been staked. For example, an LP must hold liquidity for at least 30 days to become eligible for certain rewards. If the liquidity is withdrawn before that period, the LP forfeits the time-based reward.

### Pool Lifecycle Implementation Point(s)

**onAfterAddLiquidity**
- Update the total liquidity for the user
- Calculate the rewards
- Distribute the rewards

**onAfterRemoveLiquidity**
- Update the total liquidity for the user

### Advantages and Applications

**Encourages Long-Term Commitment:** 
The time-based rewards ensure that LPs who commit their capital for longer periods are rewarded more generously than short-term participants, promoting pool stability.

**Rewards High-Volume LPs:** 
By providing tiered rewards based on volume, the protocol incentivizes LPs to add more liquidity, which improves liquidity depth and enhances the user experience for traders.

**Fair and Transparent Reward Distribution:** 
With clear volume and time-based milestones, LPs understand exactly how much liquidity and how long they need to stake to maximize their rewards.

**Prevents Abuse:** 
The withdrawal penalty prevents LPs from gaming the system by adding and removing liquidity frequently, ensuring rewards are fairly distributed to committed participants.


## SwapReferrer Hook

The **SwapReferrer Hook** is a specialized smart contract that integrates a referral-based discount mechanism into a token swap operation on a decentralized finance (DeFi) platform. This hook allows both users and referrers to benefit from reduced swap fees.

### What the hook does

The **SwapReferrer Hook** is designed for DeFi protocols that want to incentivize user acquisition through a referral system. It allows liquidity providers and swappers to benefit from discounted swap fees when they either use a referral code or are referrers themselves.

The smart contract has the following key features and processes:

1. Referral Code Generation:

When a user swaps for the first time, a unique referral code is generated for them automatically. This referral code can be used by other users for future swaps, but the user cannot use their own referral code.
The referral code is stored and linked to the user’s address.

2. User Benefit (Instant Swap Fee Discount):

When a user performs a token swap and provides a referral code, they instantly receive a discount on the swap fee. This discount is a percentage of the predefined swap fee (e.g., 50% off the original fee).
The predefined swap fee is passed as a percentage by the calling contract (e.g., 0.01e18 for 1%). The discount is calculated as a percentage reduction on this predefined fee.
For example, if the predefined swap fee is 1% (0.01e18), and the user is eligible for a 50% discount, the user only pays a 0.5% fee.

3. Referrer Benefit (Redeemable Swap Fee Discount):

For each new user who swaps using a referral code, the referrer accumulates a redeemable swap fee discount (e.g., 30% discount for each referral).
When the referrer performs their next swap, they can use the accumulated discount to reduce their swap fee.
If the accumulated discount exceeds 100% of the swap fee, only up to 100% is applied, and any leftover discount is carried over to future swaps.
For example:
If 5 users swap using the same referral code, the referrer accumulates a 150% discount (30% per user × 5 users).
When the referrer swaps next, they can only use up to 100% of the discount to perform the swap for free, and the remaining 50% will be carried forward to future swaps.

4. Discount Limits and Controls:

The smart contract ensures that:
A user can only use a referral code once when performing their first swap.
The final swap fee for a user can never go below 0%.
The referrer’s discount is applied with a cap of 100%, ensuring that the referrer cannot receive more than a full swap fee reduction on a single swap.

5. Swap Fee Output in Percentage:

The swap fee after applying discounts (both user and referrer) is calculated and returned as a percentage.
This makes the hook compatible with other contracts that calculate swap fees based on percentages, ensuring that it integrates seamlessly into a broader DeFi protocol.

### Pool Lifecycle Implementation Point(s)

**onBeforeSwap**
- Calculate the user discount
- Generate the Referral code for a new user
- Calculate the referrer discount
- Store the final discount in variable

**onComputeDynamicSwapFeePercentage**
- Update the swap fee based on final discount

**onAfterSwap**
- Update the final swap fee to zero for a new swap

### Advantages and Applications

**User Incentive:** 
Users are motivated to share their referral code because they receive an immediate discount on swap fees. This reduces the friction of high fees for new users entering the DeFi ecosystem.

**Referrer Incentive:** 
Referrers benefit from long-term rewards as their discounts accumulate over time. This encourages liquidity providers and active participants to invite more users to the platform.

**Controlled Fee System:** 
The hook ensures that swap fees remain within predefined limits (i.e., no negative fees, and referrers can only get 100% discount at most per swap). It prevents abuse while still providing a generous incentive structure.
