# Volatility and Loyalty Hook for Balancer V3 Hackathon

The hook aims to stimulate trading activity in a newly launched pool of a project on Balancer by rewarding users in the form of a discount on the static swap fee for buying the project tokens from the pool and holding them for a longer duration at the same time keeping the volatility in check by increasing the swap fee.

### Hook lifecycle points
##### onAfterRemoveLiquidity(), onAfterAddLiquidity() :
Updates the new price of the token in the Volatility Oracle along with the timestamps.

##### onAfterSwap():
Updates the new price of the token in the Volatility Oracle along with the timestamps.

Updates the loyalty index of the user.


##### onComputeDynamicSwapFeePercentage():
Calculates the swap fee based on the pool volatility and user's loyalty index.

![BalancerHookDiagram](https://github.com/user-attachments/assets/6453b5b8-03ad-4108-bc66-228cc684716f)


### Swap fee Calculation
##### swap fee = swapFeeWithLoyaltyDiscount + volatilityFee

##### swapFeeWithLoyaltyDiscount
It reduces the staticSwapFee, but maintains a **minimum fee that needs to be paid** and also maintains a **cap on the loyalty discount** that can be availed so that it is not misused by whales.
In the following example, minimum fee that needs to be paid = 1 % and cap on the loyalty discount = 1%.

Lets say the MAX_LOYALTY_FEE is 1%, then


if (staticSwapFee <= 1%) swapFeeWithLoyaltyDiscount = staticSwapFee;

else if (1% < staticSwapFee < 2% *{1% + MAX_LOYALTY_FEE}* ) swapFeeWithLoyaltyDiscount = 1% + (staticSwapFee - 1%) * (1 - loyaltyPercentage);

else if (staticSwapFee == 2% *{1% + MAX_LOYALTY_FEE}* ) swapFeeWithLoyaltyDiscount = 1% + MAX_LOYALTY_FEE * (1 - loyaltyPercentage);

else swapFeeWithLoyaltyDiscount = 1% + MAX_LOYALTY_FEE * (1 - loyaltyPercentage) + (staticSwapFee - 1% - MAX_LOYALTY_FEE);

#### To calculate loyaltyPercentage, we calculate a loyaltyIndex as:

newLoyaltyIndex = previousLoyaltyIndex + (tokens held at the previous transaction) * (current timestamp - previous swap transaction timestamp)

Using loyaltyIndex, we calculate the loyaltyPercentage using a tier based system.

This method of calculating the loyaltyIndex based on the time the tokens are held prevent the pool from **flash loan attacks**.

The loyalty index is refreshed if the previous transaction happened **_LOYALTY_REFRESH_WINDOW** (30 days) ago.


##### volatilityFee
volatilityFee = MAX_VOLATILITY_FEE * volatilityPercentage

##### How is volatilityPercentage calculated
Maintain the (price, timestamp) objects in a circular buffer, have a time interval lets say 2 minutes, during which the last price update shall be considered, for example, if a price object was inserted, and within 2mins another object is to be inserted, then it will override the previous object, but if inserted after 2mins, then it will be inserted as a new entry into the buffer. This way we can maintain a constant size circular buffer.

The implementation of the PriceOracle using a circular buffer has been inspired from the implementation of the PriceOracle in balancer v2 - https://etherscan.deth.net/address/0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0

Once we have the prices over a span of time, we extract the prices for 1 hour (in demo it maybe less) ago using **binary search** from the oracle, and the formula used to calculate the volatility is:

<img width="378" alt="Screenshot 2024-10-21 at 1 58 47 AM" src="https://github.com/user-attachments/assets/02f19b11-0132-400c-a19a-5a3db1834584">

where tf and ti are respectively the final and initial timestamps of the samples collected from the buffer for last **ago** seconds.

The unit of the volatility is **% price change per second**.

Using this volatility value, we evaluate the volatility fee percent using a tier based system.

