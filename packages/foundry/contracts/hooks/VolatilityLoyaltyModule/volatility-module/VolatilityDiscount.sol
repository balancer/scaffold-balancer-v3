// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import "./IVolatilityOracle.sol";
import "./IVolatilityDiscount.sol";

import "forge-std/console.sol";

contract VolatilityDiscount is IVolatilityDiscount {
    using FixedPoint for uint256;

    uint256 private constant _VOLATILITY_WINDOW = 10 seconds;

    uint256 private constant _VOLATILITY_FEE_CAP = 0.04e18;

    function getVolatilityFeePercent(address oracleAddress) external view returns (uint256) {
        IVolatilityOracle volatilityOracle = IVolatilityOracle(oracleAddress);
        uint256 volatility = volatilityOracle.getVolatility(_VOLATILITY_WINDOW);
        console.log("(getVolatilityFee) volatility", volatility);
        uint256 volatilityFeePercent = getVolatilityFeePercentOnCap(volatility);
        console.log("(getVolatilityFee) volatilityFeePercent", volatilityFeePercent);
        uint256 volatilityFee = (_VOLATILITY_FEE_CAP * (volatilityFeePercent)) / FixedPoint.ONE;
        console.log("(getVolatilityFee) volatilityFee", volatilityFee);
        return volatilityFee;
    }

    // volatility -> percent change per second
    function getVolatilityFeePercentOnCap(uint256 volatility) internal pure returns (uint256) {
        if (volatility > 0 && volatility <= 0.001e18) {
            // less than 0.1 %/second
            return 0; // no fee
        } else if (volatility > 0.001e18 && volatility <= 0.005e18) {
            // less than 0.5 %/second
            return 0.1e18; // 10% of max fee
        } else if (volatility > 0.005e18 && volatility <= 0.015e18) {
            // less than 1.5 %/second
            return 0.2e18; // 20% of max fee
        } else if (volatility > 0.015e18 && volatility <= 0.02e18) {
            // less than 2 %/second
            return 0.3e18; // 30% of max fee
        } else if (volatility > 0.02e18 && volatility <= 0.05e18) {
            // less than 5 %/second
            return 0.5e18; // 50% of max fee
        } else if (volatility > 0.05e18 && volatility <= 0.1e18) {
            // less than 10 %/second
            return 0.7e18; // 70% of max fee
        } else if (volatility > 0.1e18 && volatility <= 0.2e18) {
            // less than 20 %/second
            return 0.9e18; // 90% of max fee
        } else if (volatility > 0.2e18) {
            // greater than 20%/second
            return 1e18; // 100% of max fee
        } else {
            return 0; // no fee
        }
    }
}
