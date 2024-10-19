// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { PredictionMarket } from '../Types.sol';
import { PredictionMarketLib } from './PredictionMarketLib.sol';
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

library PredictionMarketStorage {
    using PredictionMarketLib for PredictionMarket;

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

    function store(
        mapping(bytes32 => PredictionMarket) storage self,
        PredictionMarket memory market
    ) internal {
        self[market.id] = market;
    }

    function get(
        mapping(bytes32 => PredictionMarket) storage self,
        bytes32 id
    ) internal view returns (PredictionMarket memory){
        return self[id];
    }

    function getOrCreate(
        mapping(bytes32 => PredictionMarket) storage self,
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp,
        IVault vault
    ) internal returns (PredictionMarket memory market) {
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
            swapFees: 0
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