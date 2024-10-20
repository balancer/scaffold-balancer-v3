# Prediction Market Hook
Asset price prediction markets (binary options in tradfi) are a popular way for market participants to get leverage, hedge or speculate on short term price movements. In their current form, they exist on-chain as services with either partially or fully centralized components. 

This hook allows any registered pool to permissionlessly host prediction markets and use incentives to maintain the integrity of the market by giving 0% swap fees to prediction market participants to incentivize arbitrage.

Liquidity providers are compensated by receiving 100% of the swap fees generated from prediction markets. As such, this hook introduces an additional revenue source for liquidity provides that does not depend on price movement. One can think of this style of hook as offering additional value to the ecosystem that participants are willing to compensate LP's for.

## How it Brings Value
1. Open the doors for new prediction markets by removing centralized components and friction. Any asset pair hosted in a balancer pool can now become its own prediction market.

1. Introduce a novel approach to reducing Impermanent Loss in volatile pools by introducing an additional source of fee revenue.

1. Decentralized leveraged trading for short term traders. Traders have the opportunity to 2x+ capital within short time intervals.

1. LP's can hedge expected price movements during volatile markets to further reduce IL.

## How it Works
After pool registration, any asset with a non zero balance can become part of a pair used in a prediction market. Below is a description of the core components when interacting with a market.

### Creating a position
Users can create a new or  add to a position by calling **addLiquidity**. The function takes in the pool, pair, liquidity amount and end date of the market. If the market does not exist then it will be automatically created. Users can add liquidity in proportional amounts or single sided. 

After adding liquidity a users internal balance of bull/bear units will be updated. In the event of a new pool creation and proportional liquidity each side will be valued at 50% of the input token, representing a 50% probability of each outcome.

A 1% transaction fee is charged for each liquidity addition.

### Swapping
Unlike other platforms, users can swap between sides as markets develop. To do this one can call the **swap** method with an input amount, the side to swap from and the marketId.

The swap uses an implementation of uniswapV2 math to determine the swap exchange rate. The users balance and the market balances are updated after the swap.

A 1% transaction fee is charged for each swap.

### Settling the Market (determining payouts)
Upon closing of  market (the duration has expired), the market can be settled by calling the **settle** method. At this time the winning side of the market is determined ad the payouts for the bull/bear sides are calculated.

The winning payout will be a split between the total deposited liquidity and the total amount to units on the winning side. For example, if 10ETH are deposited and 7ETH of value is on the winning side then the value of each winning unit received a 1.42x payout.

One should consider that during the duration of the market being open, prices will range/move. So that unit of the winning side may have been able to be purchased at say .2 (20% probability). This structure of a dynamic market rewards traders with forecasting ability and thus will attract volume to the market

### Collecting Payouts
A winning user can claim their payout by calling the **collect** method with the corresponding marketId. 

## Guarding Against Price Manipulation
Price manipulation is an obvious concern for a market like this. A bad actor is incentivized to the move the pool price right before settlement. To remove this risk a few measures are taken.

1. Prediction market participants are incentivized to be arbitragers. This is done by overriding the computeDynamicSwapFeePercentage method to give market participants a 0% trading fee. This trading fee discount makes arbitrage available to bring prices back into line quickly if the are manipulated by a bad actor.

2. There is a built in waiting period between the last swap/liquidity action in a pool and when it can be settled. Configured in blocks, this gives arbitrage enough time to rebalance prices before taking a final price snapshot during settlement.

When combined, the system properly incentivizes participants to rebalance the pool in the event of manipulation of a bad actor.

## Overriden Hook Methods
**onComputeDynamicSwapFeePercentage:** Used to give prediction market participants 0% trading fees. Allowing them to arbitragers responsible for maintaining price integrity of the pool.

**onAfterSwap:** Record the last activity block number for a given pool. Used during settlement in conjunction with the settlement waiting period.

**onAfterAddLiquidity:** Record the last activity block since non proportional adds will impact price

**onAfterRemoveLiquidity:** Record the last activity block since non proportional removes will impact price

## Custom Hook Methods
**addLiquidity:** Create or add to a prediction market position.

**swap:** Swap from one side of the market to the other

**settle:** Close a market and compute winning payouts

**collect:** Claim payouts from a market

## Next Steps

- Add more unit tests
- Add KYC to comply with laws in certain juristictions
- Audit
