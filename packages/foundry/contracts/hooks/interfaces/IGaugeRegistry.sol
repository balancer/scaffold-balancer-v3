// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGaugeRegistry {
    function getPoolGauge(address pool) external view returns (address);
}
