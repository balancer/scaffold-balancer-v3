// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { 
    PredictionMarket,
    Side 
} from '../Types.sol';

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library PredictionMarketLib { 

    /**
     * @notice Prediction market has zero token balance for one of both pair tokens
     */
    error ZeroTokenBalance();

    /**
     * @notice Prediction market has insufficent liquidity to execute swap
     */
    error CannotSwapInMarket();

    /**
     * @notice Prediction market does not have liquidity on both sides
     * @dev Occurs when a user tries to add liquidity proportionally to a single sided market
     * In this case, the market cannot quote the side with zero liquidity
     */
     error CannotAddProportionalLiquidityToSingleSidedMarket();

    
    /**
     * @notice Quote the current prices (probabilities) of the prediction market
     * @dev The total value of the market is always equal to the deposited liquidity, thus to
     * get the probability or price of each outcome, we need to divide the net outcome balance
     * by the total deposited liquidity.
     * @param self The prediction market to quote
     */
    function quote(
        PredictionMarket memory self
    ) internal pure returns (uint256 quoteBull, uint256 quoteBear) {
        quoteBull = Math.mulDiv(self.balanceBull, 1e18, self.liquidity);
        quoteBear = Math.mulDiv(self.balanceBear, 1e18, self.liquidity);
    }

    /**
     * @notice Quote the asset pair in the underlying pool
     * @dev Uses the total assets held by the pool and provide a simple quote based on assetA relative 
     * to assetB instead of using the pool pricing model
     *
     * Reverts if the pool balance of either asset is 0
     * @param self The prediction market to quote
     * @param vault The vault to get token balances from
     */
    function quoteUnderlying(
        PredictionMarket memory self,
        IVault vault
    ) internal view returns(uint256) {
        // Fetch token balances from pool for each token in the pair. 
        (IERC20[] memory tokens,,,uint256[] memory lastBalancesLiveScaled18) = vault.getPoolTokenInfo(self.pool);

        uint256 balanceToken0;
        uint256 balanceToken1;

        for(uint256 i=0; i < tokens.length; i++){
            address token = address(tokens[i]);

            if(token == self.token0) {
                balanceToken0 = lastBalancesLiveScaled18[i];
            } else if(token == self.token1) {
                balanceToken1 = lastBalancesLiveScaled18[i];
            }
        }

        // Revert if either token has a zero balance.
        if(balanceToken0 * balanceToken1 == 0){
            revert ZeroTokenBalance();
        }

        // Quote balance0 relative to balance1
        // This approach does not take into account token weights for weighted pools, quotes are not
        // expected to match other pricing methods.
        return Math.mulDiv(balanceToken0, 1e18, balanceToken1);
    }

    /**
     * @notice Whether a market has been initalized
     * @dev All initalized markets have at minimum an open price
     * @param self The prediction market
     */
    function isInitalized(PredictionMarket memory self) internal pure returns (bool) {
        return self.openPrice > 0;
    }

    /**
     * @notice Whether a market is currently active 
     * @dev A market is active and can accept swaps / deposits if it is initalized and the
     * end time has not passed
     * @param self The prediction market
     */
    function isActive(PredictionMarket memory self) internal view returns (bool) {
        return isInitalized(self) && self.endTime < block.timestamp;
    }

    /**
     * @notice Whether swaps can be facilitated in the market
     * @dev If a market has liquidity on only 1 side, then a swap is not possible
     */
    function canSwap(PredictionMarket memory self) internal view returns (bool) {
        return isActive(self) && self.balanceBear * self.balanceBull != 0;
    }

    /**
     * @notice Add liquidity to a given market 
     * @dev Credits msg.sender with value of bull/bear units and increments liquidity.
     * @param self The prediction market
     * @param amount The deposited liquidity amount
     * @param side The side to add liquidit to
     * @return bullAmount The bull amount of units credited
     * @return bearAmount The bear amount of units credited
     */
    function addLiquidity(
        PredictionMarket memory self,
        uint256 amount,
        Side side
    ) internal returns (uint256 bullAmount, uint256 bearAmount) {
        if(side == Side.Both){
            return _addProportionalLiquidity(self, amount);
        } else {
            return _addSingleSidedLiquidity(self, side, amount);
        }
    }

    /**
     * @notice Add liquidity to a given market 
     * @dev Credits msg.sender with a proportional value of bull/bear units and increments liquidity.
     *
     * For new markets (no pre-existing liquidity), users are credited an equal balance of bull/bear
     * @param self The prediction market
     * @param amount The deposited liquidity amount
     */
    function _addProportionalLiquidity(
        PredictionMarket memory self,
        uint256 amount
    ) private returns (uint256 bullAmount, uint256 bearAmount) {
        if(self.liquidity == 0){
            bullAmount = amount/2;
            bearAmount = amount/2;
        } else if(self.balanceBear == 0 || self.balanceBull == 0) {
            revert CannotAddProportionalLiquidityToSingleSidedMarket();
        } else {
            (uint256 quoteBull, uint256 quoteBear) = quote(self);

            bullAmount = Math.mulDiv(amount, quoteBull, 1e18);
            bearAmount = Math.mulDiv(amount, quoteBear, 1e18);
        }
        
        self.liquidity += amount;
        self.balanceBear += bullAmount;
        self.balanceBull += bearAmount;
    }

    /**
     * @notice Add liquidity to one side of the market
     * @dev Adding single sided liquidity will have price impact for subsequent swaps
     * @param self The prediction market
     * @param amount The deposited liquidity amount
     * @param side Side of the market to add liquidity to 
     */
    function _addSingleSidedLiquidity(
        PredictionMarket memory self,
        Side side,
        uint256 amount
    ) private returns (uint256 bullAmount, uint256 bearAmount) {
        // Revert if there is no liquidity in the market, then amounts will be equal to the deposited amount
        // otherwise amounts will equal the proportioned amount based on current market values
        if(self.liquidity == 0){
            (bullAmount, bearAmount) = side == Side.Bull ? (amount, uint256(0)) : (0, amount);
        } else {
            (uint256 quoteBull, uint256 quoteBear) = quote(self);
            
            bullAmount = side == Side.Bull ? Math.mulDiv(amount, 1e18, quoteBull) : 0;
            bearAmount = side == Side.Bear ? Math.mulDiv(amount, 1e18, quoteBear) : 0;
        }

        // adjust the market balances based on the calculated values
        self.liquidity += amount;
        self.balanceBear += bearAmount;
        self.balanceBull += bullAmount;
    }

    /**
     * @notice Given an input amount and side, returns the maximum output amount of the other side
     * @dev Exchange fees are not taken into account here sice fees are calculated once markets are settled
     * @param self The prediction market
     * @param amountIn The deposited liquidity amount
     * @param side Side to swap FROM
     */
    function getAmountOut(
        PredictionMarket memory self,
        Side side,
        uint256 amountIn
    ) internal pure returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = side == Side.Bull ? 
            (self.balanceBull, self.balanceBear) :
            (self.balanceBear, self.balanceBull);

        return Math.mulDiv(amountIn, reserveOut, reserveIn);
    }

    /**
     * @notice Swap the given input amount and side from one side to the other
     * @dev Swap fees are accumulated and deducted during market settlement
     * @param self The prediction market
     * @param amountIn The deposited liquidity amount
     * @param side Side to swap FROM
     * @param fee Swap fee perentage
     * @return amountOut Units in the opposing side quoted from the swap
     */
    function swap(
        PredictionMarket memory self,
        Side side,
        uint256 amountIn,
        uint256 fee
    ) internal view returns (uint256 amountOut) {
        // revert if the market has 0 liquidity on either side
        if(!canSwap(self)){
            revert CannotSwapInMarket();
        }

        // fees are determined by the asset value in terms of the liquidity token
        (uint256 quoteBull, uint256 quoteBear) = quote(self);
        uint256 sideQuote = side == Side.Bull ? quoteBull : quoteBear;
        uint256 liquidityTokenValue = Math.mulDiv(sideQuote, amountIn, 1e18);
        uint256 swapFeeAmt = Math.mulDiv(liquidityTokenValue, fee, 1e6);

        // determine the output amount based on the side and amountIn 
        amountOut = getAmountOut(self, side, amountIn);


        // update the market to reflect the swap
        if(side == Side.Bull){
            self.balanceBull -= amountIn;
            self.balanceBear += amountOut;
        } else {
            self.balanceBear -= amountIn;
            self.balanceBull += amountOut;
        }

        self.swapFees += swapFeeAmt;
    }

    

}