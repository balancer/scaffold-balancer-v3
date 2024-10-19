// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

struct Position {
    uint256 bullAmount;
    uint256 bearAmount;
}

struct PredictionMarket {
    bytes32 id;
    address token0;
    address token1;
    uint256 endTime;
    uint256 liquidity;
    uint256 balanceBull;
    uint256 balanceBear;
    uint256 openPrice;
    uint256 closePrice;
}