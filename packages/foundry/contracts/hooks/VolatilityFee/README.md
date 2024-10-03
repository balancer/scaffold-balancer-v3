# 🪝Volatility Fee Hook

A dynamic Swap Fee hook based on volatiltiy of the pool. The Hook calculates utilization ratio based on Amount of Token Out and Balance of Token Out in the pool, and charges igher fee when the utilization ratio increases.

<br>

## 🔑Key Advantages
- Increased Protection during Volatility
- Smoother Market Conditions
- Disincentivizes Pool Exploits
- Customisable Fee Logic
- Reduction in Impermanent Loss for LPs

## 🏃‍♂️How to Run
1. Ensure to Follow the Scaffold-Balancer-v3 `README.md`

2. For Step 5, instead of deploying simple, use deployWith Hook to deploy, mock tokens, pool factories, Constant Product Pool, and Constant Product Pool with Volatility Fee Hook V1 and V2.
```bash
yarn deployWithHook
```
3. Use the Pool Addresses from deploy Terminal, and search in the scaffold frontend to access the pool.


### ⭐️Volatility Fee Hook v1 
was developed simply to discretely distinguish fee ranges:
Technicals:
1. Utilization Ratio > 10%, pool/hook will charge x5 the staticSwapFee
2. Utilization Ratio > 20%, pool/hook will charge x10 the staticSwapFee
3. Utilization Ratio > 30%, pool/hook will charge x20 the staticSwapFee
4. Utilization Ratio > 40%, pool/hook will charge x50 the staticSwapFee

Developers can update the fee charge ranges in `function _calculateSwapFee`.

- Hook.sol: `packages/foundry/contracts/hooks/VolatiltiyFeeHook.sol`
- Test.t.sol: `packages/foundry/test/VolatilityFeeHook.t.sol`

<br>

### ✨Volatility Fee Hook V2
v2 is developed on a continuous exponential curve for charging Swap Fee.
The core equation behind charging these swap fee is:

`feeMultiplier = 1 + (utilization Ratio^2 * 99)`

multiplying by 99 ensures that at max utilization the fee multiplier reaches 100x

- Hook.sol: `packages/foundry/contracts/hooks/VolatiltiyFeeHookV2.sol`
- Script.s.sol: `packages/foundry/scripts/08_DeployVolatiltiyFeePool.s.sol`

<br>


``` 
Caution: This repository have many changes and additions to learn Balancer Smart Contract Ecosystem, and may differ in working from original Balancer Scaffold V3 
```

<br>

***📢 Big Shoutout to Team Balancer and Matthu.eth for encouraging learning and Development at every step***
