// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

interface IVolatilityOracle {
    function getVolatility(uint256 ago) external view returns (uint256);

    function updateOracle(uint256 balanceToken0, uint256 balanceToken1) external;
}
