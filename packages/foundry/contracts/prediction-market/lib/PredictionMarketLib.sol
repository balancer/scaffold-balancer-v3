// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { PredictionMarket } from '../Types.sol';

library PredictionMarketLib { 
    
    /**
     * @dev Get the unique market identifier for the given inputs
     * @param pool Address of the pool
     * @param tokenA First token in the trading pair
     * @param tokenB Second token in the trading pair
     *
     * @return id Unique market identifier
     */
    function getMarketId(
        address pool,
        address tokenA,
        address tokenB
    ) internal pure returns (bytes32 id) {
        (address token0, address token1) = tokenA > tokenB ? 
            (tokenA, tokenB) :
            (tokenB, tokenA);

        return keccak256(abi.encodePacked(pool, token0, token1));
    }

    function isInitalized(PredictionMarket memory self) internal pure returns (bool) {
        return self.openPrice > 0;
    }

    function isActive(PredictionMarket memory self) internal view returns (bool) {
        return isInitalized(self) && self.endTime < block.timestamp;
    }

    function addLiquidity(
        PredictionMarket memory self,
        uint256 amount
    ) internal returns (uint256 bullAmount, uint256 bearAmount) {
        
        return (amount/2, amount/2);
    }

    

}