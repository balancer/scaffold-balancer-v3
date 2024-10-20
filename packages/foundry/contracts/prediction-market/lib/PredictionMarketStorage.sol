// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { PredictionMarketLib } from './PredictionMarketLib.sol';
import { 
    PredictionMarket,
    Side 
} from '../Types.sol';

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

library PredictionMarketStorage {
    using PredictionMarketLib for PredictionMarket;

    /// @notice Market is inactive and cannot be traded
    error MarketIsNotActive();

    /// @notice Market is settled and cannot be settled again
    error MarketIsSettled();

    /// @notice Market is not initalized and cannot be closed
    error MarketIsNotInitalized();

    /// @notice Market is still active and cannot be closed
    error MarketIsActive();

    /// @notice Settlement cannot occur too soon after the last pool swap
    error SettlementTooSoonAfterSwap();
    
    /**
     * @dev Get the unique market identifier for the given inputs
     * @param pool Address of the pool
     * @param tokenA First token in the trading pair
     * @param tokenB Second token in the trading pair
     * @param closedAtTimestamp Closing time of the market
     *
     * @return id Unique market identifier
     */
    function getMarketId(
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp
    ) internal pure returns (bytes32) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        return keccak256(abi.encodePacked(pool, token0, token1, closedAtTimestamp));
    } 


    /**
     * @notice Add liquidity to a given market 
     * @dev creates the market if it does not exist
     * @param self The mapping from marketId to market
     * @param pool Pool hosting the prediction market
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param closedAtTimestamp Timestamp for when the market closes
     * @param vault The balancer vault 
     * @param side The side to add liquidity to
     * @param amount Deposit amount
     * @param feePercentage The fee amount
     * @return bullAmount The bull amount of units credited
     * @return bearAmount The bear amount of units credited
     * @return market The modified market
     */
    function addLiquidity(
        mapping(bytes32 => PredictionMarket) storage self,
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp,
        IVault vault,
        Side side,
        uint256 amount,
        uint256 feePercentage
    ) internal returns (uint256 bullAmount, uint256 bearAmount, PredictionMarket memory market) {
        market = _getOrCreate(self, pool, tokenA, tokenB, closedAtTimestamp, vault);

        (bullAmount, bearAmount) = market.addLiquidity(side, amount, feePercentage);

        self[market.id] = market;
    }

    /**
     * @notice settle a market after the trading window has closed
     * @param self mapping from marketId to PredictionMarket
     * @param marketId market to close
     * @param lastSwapBlock block number of the last swap in the underlying pool supporting the market
     * @param waitingPeriod minimum blocks between settlement and the last pool swap
     * @param vault The vault
     * @return market The settled market
     */
    function settle(
        mapping(bytes32 => PredictionMarket) storage self,
        bytes32 marketId,
        uint256 lastSwapBlock,
        uint256 waitingPeriod,
        IVault vault
    ) internal returns (PredictionMarket memory market) {
        market = self[marketId];

        // Ensure the market can be settled
        uint256 elapsedWaitingPeriod = block.number - lastSwapBlock;

        if(market.settled) {
            revert MarketIsSettled();
        } else if(!market.isInitalized()){
            revert MarketIsNotInitalized(); // market was never initalized with liquidity
        } else if(market.isActive()){
            revert MarketIsActive(); // end time has not been reached
        } else if(elapsedWaitingPeriod < waitingPeriod){
            revert SettlementTooSoonAfterSwap();
        }

        // settle the market by recording it's closing price and determing the payout values
        // for each side accoring to the liquidity in the market and the bet amounts
        market.closePrice = market.quoteUnderlying(vault);

        Side winningSide = market.closePrice > market.openPrice ? Side.Bull : Side.Bear;

        uint256 winningBalance = winningSide == Side.Bull ? market.balanceBull : market.balanceBear;
        uint256 feeTokenDecimals = IERC20Metadata(market.token0).decimals();
        uint256 winningPayout = Math.mulDiv(market.netLiquidity(), 10**feeTokenDecimals, winningBalance);

        market.closingBullValue = winningSide == Side.Bull ? winningPayout : 0;
        market.closingBearValue = winningSide == Side.Bear ? winningPayout : 0;
        market.settled = true;

        self[marketId] = market;

        return market;
    }
    
     /**
     * @notice swap a position holdings between sides 
     * @dev bull -> bear or bear -> bull
     *
     * Fees are charged for each swap and maintained on the market for processing during settlement
     * @param self mapping from marketId to PredictionMarket
     * @param marketId Identifier of the market to swap
     * @param side Side to swap from
     * @param amountIn Amount to swap
     * @param feeAmount The fee to charge for the swap
     * @return amountOut Output amount creditied to the position
     */
    function swap(
        mapping(bytes32 => PredictionMarket) storage self,
        bytes32 marketId,
        Side side,
        uint256 amountIn,
        uint256 feeAmount
    ) internal returns (uint256 amountOut) {
        PredictionMarket memory market = self[marketId];

        // revert if the market is not active. Either not initalized or beyond the close timestamp
        if(!market.isActive()) {
            revert MarketIsNotActive();
        }

        amountOut = market.swap(side, amountIn, feeAmount);

        // store the updated market
        self[marketId] = market;
    }

    /**
     * @notice Get or create a market for the given params
     * @param self The mapping from marketId to market
     * @param pool Pool hosting the prediction market
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param closedAtTimestamp Timestamp for when the market closes
     * @param vault The balancer vault 
     */
    function _getOrCreate(
        mapping(bytes32 => PredictionMarket) storage self,
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp,
        IVault vault
    ) private returns (PredictionMarket memory market) {
        bytes32 marketId = getMarketId(pool, tokenA, tokenB, closedAtTimestamp);

        market = self[marketId];

        if(market.isInitalized()) { 
            return market;
        }

        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        market = PredictionMarket({
            id: getMarketId(pool, tokenA, tokenB, closedAtTimestamp),
            pool: pool,
            token0: token0,
            token1: token1,
            liquidity: 0,
            balanceBull: 0,
            balanceBear: 0,
            openPrice: 0,
            closePrice: 0,
            endTime: closedAtTimestamp,
            fees: 0,
            closingBullValue: 0,
            closingBearValue: 0,
            settled: false
        });

        market.openPrice = market.quoteUnderlying(vault);
    }

    function _sortTokens(
        address tokenA,
        address tokenB
    ) private pure returns (address token0, address token1) {
        (token0, token1) = tokenA > tokenB ? 
            (tokenA, tokenB) :
            (tokenB, tokenA);
    }
}