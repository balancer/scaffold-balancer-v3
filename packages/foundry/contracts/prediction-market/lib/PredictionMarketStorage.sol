// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { PredictionMarket } from '../Types.sol';
import { PredictionMarketLib } from './PredictionMarketLib.sol';

library PredictionMarketStorage {
    using PredictionMarketLib for PredictionMarket;

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

    function getOrCreate(
        mapping(bytes32 => PredictionMarket) storage self,
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp,
        uint256 price
    ) internal returns (PredictionMarket memory) {
        bytes32 marketId = getMarketId(pool, tokenA, tokenB, closedAtTimestamp);

        PredictionMarket memory market = self[marketId];

        if(market.isInitalized()) { 
            return market;
        }

        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        return PredictionMarket({
            id: getMarketId(pool, tokenA, tokenB, closedAtTimestamp),
            token0: token0,
            token1: token1,
            liquidity: 0,
            balanceBull: 0,
            balanceBear: 0,
            openPrice: price,
            closePrice: 0,
            endTime: closedAtTimestamp
        });
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