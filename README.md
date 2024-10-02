# LoyaltyHook - BAL Hookathon submission

A custom Balancer V3 Pool Hook designed to incentivize user engagement and loyalty within a liquidity pool by rewarding users with Loyalty Tokens (`LOYALTY`).

## 🪧 Table of contents

- [📖 Overview](#-overview)
- [🎯 What the hook does](#-what-the-hook-does)
- [💡 Example uise case](#-example-use-case)
- [🏦 Benefits for pool creators](#-benefits-for-pool-creators)
- [👍 DevX feedback](#-devx-feedback)
- [📜 LoyaltyToken](#-loyaltytoken-implementation)

## 📖 Overview

The **LoyaltyHook** is a custom Balancer V3 Pool Hook designed to incentivize user engagement and loyalty within a liquidity pool. By integrating this hook, pools can reward users with **Loyalty Tokens (`LOYALTY`)** when they add liquidity or perform swaps. Additionally, the hook dynamically adjusts swap and exit fees based on the user's `LOYALTY` token balance, offering significant discounts to loyal participants.

## 🎯 What the hook does

The LoyaltyHook enhances a Balancer V3 liquidity pool with the following features:

1. **Minting loyalty tokens**: Users earn `LOYALTY` tokens when they add liquidity or execute swaps through the pool. The amount minted is adjusted based on their activity level, incorporating a decay mechanism to balance rewards.

2. **Dynamic swap fees**: Swap fees are dynamically calculated based on the user's `LOYALTY` token holdings. Higher `LOYALTY` balances result in greater fee discounts, encouraging users to accumulate and retain tokens.

3. **Exit fees**: When users remove liquidity, an exit fee is applied. However, users with sufficient `LOYALTY` tokens receive discounts on these fees, potentially eliminating them entirely at the highest loyalty tiers.

4. **Action tracking and decay mechanism**: The hook tracks user actions and applies a decay to the `LOYALTY` tokens minted over time. Frequent actions within a reset interval (e.g., 30 days) result in reduced mint amounts per action, promoting consistent engagement without over-rewarding.

### Loyalty tiers and discounts

- **Tier 1**:
  - **Threshold**: ≥ 100 `LOYALTY` tokens
  - **Discount**: 50% off swap and exit fees

- **Tier 2**:
  - **Threshold**: ≥ 500 `LOYALTY` tokens
  - **Discount**: 80% off swap and exit fees

- **Tier 3**:
  - **Threshold**: ≥ 1000 `LOYALTY` tokens
  - **Discount**: 90% off swap and exit fees

## 💡 Example use case

**Scenario**:

Imagine Alice, an active trader and liquidity provider, interacts with a Balancer pool that has integrated the LoyaltyHook.

1. **Adding Liquidity**:
   - Alice adds liquidity to the pool.
   - She receives `LOYALTY` tokens proportional to her contribution and activity level.
   - Her action count increases, and the decay mechanism adjusts her rewards appropriately.

2. **Performing Swaps**:
   - Alice swaps tokens within the pool.
   - She earns additional `LOYALTY` tokens for each swap.
   - Her growing `LOYALTY` balance moves her up the loyalty tiers.

3. **Receiving Fee Discounts**:
   - As her `LOYALTY` balance surpasses tier thresholds, she enjoys reduced swap and exit fees.
   - At Tier 2, she gets an 80% discount, significantly lowering her trading costs.

4. **Removing Liquidity**:
   - When Alice decides to withdraw her liquidity, her high `LOYALTY` balance grants her reduced or waived exit fees.
   - This maximizes her returns and encourages her to continue participating in the future.

**Benefits for Alice**:

- Lower fees enhance her profitability.
- Earning `LOYALTY` tokens adds value to her participation.
- Incentives align with her interest in staying active within the pool.

## 🏦 Benefits for pool creators

- **Increased user engagement**: Incentivizes users to interact more with the pool, increasing liquidity and trading volume. By rewarding users with `LOYALTY` tokens, deployers can foster a more vibrant and active pool ecosystem.
- **Future extensions**: There's potential to implement a staking contract where users can stake their `LOYALTY` tokens for additional benefits, further enhancing user commitment and offering new utility for the token.

## 👍 DevX fedback

Developing the LoyaltyHook provided valuable insights into the Balancer V3 ecosystem. Here are some observations:

### Positive aspects:

- **Comprehensive documentation**: The Balancer documentation is excellent, with sample hooks that were instrumental in understanding the hook system. Many of the tests and mechanisms in the LoyaltyHook were based on these examples.

- **Deploy scripts**: The provided deploy scripts were very helpful. They enabled seamless deployment of the pool and LoyaltyHook, and facilitated interaction with the frontend effectively.

- **Interactive frontend**: The frontend offered a practical environment to test and interact with custom contracts, making the development and debugging process more efficient.

### Suggestions

- **Documentation consistency**:
  - **Observation**: Some of the documentation is spread across the `scaffold-balancer-v3` repository and the official documentation site, which was discovered late in the development process.

  - **Suggestion**: Unifying the documentation by consolidating resources and examples in one place would enhance accessibility.

### Overall Experience

Developing the LoyaltyHook was a rewarding experience, showcasing the flexibility and power of the Balancer V3 platform. The ability to customize pool behavior through hooks opens up possibilities for innovation in DeFi. The supportive documentation and tools provided made the development process smooth and enjoyable.

## 📜 LoyaltyToken Implementation

The `LOYALTY` token is implemented using OpenZeppelin's `ERC20` and `AccessControl` contracts, ensuring standard token functionality and secure role-based permissions. The code is as follows:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LoyaltyToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Function to grant minter role (can only be called by admin)
    function grantMinterRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    // Function to revoke minter role (can only be called by admin)
    function revokeMinterRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }
}
```

For testing purposes, the `LoyaltyHook` contract is granted the `MINTER_ROLE` to mint `LOYALTY` tokens appropriately.

---

**Note**: This hook is a submission for the BAL Hookathon and aims to demonstrate the potential of customizable hooks in enhancing user engagement and value within the Balancer ecosystem.

---

# Thank you for considering the LoyaltyHook for the BAL Hookathon!

Feel free to reach out for any questions or further discussions.