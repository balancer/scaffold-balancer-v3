// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GaugeRegistry
/// @notice A mock contract to register gauges for pools
/// @dev This contract is used for testing purposes only while waiting from feedback of balancer team regarding the balancer v3 gauge registry
contract GaugeRegistry {
    mapping(address pool => address gauge) public gauges;

    function register(address pool, address gauge) external {
        gauges[pool] = gauge;
    }

    function getPoolGauge(address pool) external view returns (address) {
        return gauges[pool];
    }
}
