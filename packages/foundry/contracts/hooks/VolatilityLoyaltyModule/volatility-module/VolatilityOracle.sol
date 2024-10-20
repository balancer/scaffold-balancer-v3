// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import "../balancer-v2-oracle/library/WeightedPool2TokensMiscData.sol";
import "../balancer-v2-oracle/library/WeightedOracleMath.sol";
import "../balancer-v2-oracle/PoolPriceOracle.sol";
import "./IVolatilityOracle.sol";

import "forge-std/console.sol";

contract VolatilityOracle is IVolatilityOracle, PoolPriceOracle {
    using FixedPoint for uint256;
    using WeightedPool2TokensMiscData for bytes32;

    bytes32 internal _miscData;

    function getVolatility(uint256 ago) external view returns (uint256 volatility) {
        if (ago == 0) return 0;

        console.log("(getVolatility) Here 1", _miscData.oracleIndex(), ago);

        LogPairPrices[] memory logPairPrices = findAllSamples(_miscData.oracleIndex(), ago);
        console.log("(getVolatility) Here 2");

        if (logPairPrices.length < 2) return 0;

        uint256[] memory ratesOfChange = new uint256[](logPairPrices.length - 1);
        uint256 validValues;
        uint256 timeDuration;

        for (uint256 i = 1; i < logPairPrices.length; i++) {
            console.log("(getVolatility) i", i);
            if (logPairPrices[i - 1].timestamp == 0) continue;

            uint256 price1 = WeightedOracleMath._fromLowResLog(logPairPrices[i - 1].logPairPrice);
            console.log(
                "(getVolatility) logPairPrices[i - 1].logPairPrice, price1",
                uint256(logPairPrices[i - 1].logPairPrice),
                price1
            );
            uint256 price2 = WeightedOracleMath._fromLowResLog(logPairPrices[i].logPairPrice);
            console.log("(getVolatility) price2", price2);
            uint256 timestamp1 = ((logPairPrices[i - 1].timestamp));
            console.log("(getVolatility) timestamp1", timestamp1);
            uint256 timestamp2 = ((logPairPrices[i].timestamp));
            console.log("(getVolatility) timestamp2", timestamp2);

            uint256 priceChange = _absoluteSubtraction(price2, price1);
            console.log("(getVolatility) priceChange", priceChange);
            uint256 priceChangeFraction = priceChange.divDown(price1);
            console.log("(getVolatility) priceChangeFraction", priceChangeFraction);
            uint256 timeChange = timestamp2 - timestamp1;
            console.log("(getVolatility) timeChange", timeChange);

            uint256 rateOfChange = priceChangeFraction.divDown(timeChange) / FixedPoint.ONE;
            console.log("(getVolatility) rateOfChange", rateOfChange);

            ratesOfChange[i - 1] = rateOfChange;
            validValues += 1;
            timeDuration += (timestamp2 - timestamp1);
        }

        console.log("(getVolatility) timeDuration, ago", timeDuration, ago);

        volatility = _calculateStdDev(ratesOfChange, validValues);
        console.log("(getVolatility) volatility before scale", volatility);
        // calculate volatility over ago time interval
        volatility = volatility.mulDown(timeDuration * FixedPoint.ONE).divDown(ago * FixedPoint.ONE);
        console.log("(getVolatility) volatility", volatility);

        return volatility;
    }

    function updateOracle(uint256 balanceToken0, uint256 balanceToken1) public {
        console.log("(_updateOracle) Entered1");
        bytes32 miscData = _miscData;

        int256 logSpotPrice = WeightedOracleMath._calcLogSpotPrice(
            FixedPoint.ONE,
            balanceToken0,
            FixedPoint.ONE,
            balanceToken1
        );
        // console.log("(_updateOracle) logSpotPrice", logSpotPrice);

        int256 logBPTPrice = WeightedOracleMath._calcLogBPTPrice(
            FixedPoint.ONE,
            balanceToken0,
            miscData.logTotalSupply()
        );
        // console.log("(_updateOracle) logBPTPrice", logBPTPrice);

        uint256 oracleCurrentIndex = miscData.oracleIndex();
        console.log("(_updateOracle) oracleCurrentIndex", oracleCurrentIndex);
        uint256 oracleCurrentSampleInitialTimestamp = miscData.oracleSampleCreationTimestamp();
        console.log("(_updateOracle) oracleCurrentSampleInitialTimestamp", oracleCurrentSampleInitialTimestamp);
        uint256 oracleUpdatedIndex = _processPriceData(
            oracleCurrentSampleInitialTimestamp,
            oracleCurrentIndex,
            logSpotPrice
        );
        console.log("(_updateOracle) oracleUpdatedIndex", oracleUpdatedIndex);

        if (oracleCurrentIndex != oracleUpdatedIndex) {
            // solhint-disable not-rely-on-time
            miscData = miscData.setOracleIndex(oracleUpdatedIndex);
            miscData = miscData.setOracleSampleCreationTimestamp(block.timestamp);
            _miscData = miscData;
        }

        console.log("(_updateOracle) Finished");
    }

    function _calculateStdDev(uint256[] memory numbers, uint256 numbersLength) internal view returns (uint256) {
        if (numbersLength == 0) return 0;
        if (numbers.length == 0) return 0;
        // throw error if array is elmpty
        console.log("(calculateStdDev) entered here");
        console.log("(calculateStdDev) numbersLength", numbersLength);

        // Calculate mean first
        uint256 sum = 0;
        for (uint256 i = numbers.length - numbersLength; i < numbers.length; i++) {
            console.log("(calculateStdDev) numbers[i] i", i, numbers[i]);
            sum += numbers[i];
        }

        console.log("(calculateStdDev) sum", sum);
        uint256 mean = (sum) / numbersLength;

        console.log("(calculateStdDev) mean", mean);

        // Calculate sum of squared differences from mean
        uint256 sumSquaredDiff = 0;
        for (uint256 i = numbers.length - numbersLength; i < numbers.length; i++) {
            console.log("(calculateStdDev) numbers[i]", numbers[i]);
            if (numbers[i] > mean) {
                uint256 diff = ((numbers[i]) - mean);
                console.log("(calculateStdDev) diff", diff);
                sumSquaredDiff += (diff * diff);
            } else {
                uint256 diff = (mean - (numbers[i]));
                console.log("(calculateStdDev) diff", diff);
                sumSquaredDiff += (diff * diff);
            }
        }

        console.log("(calculateStdDev) sumSquaredDiff", sumSquaredDiff);

        // Calculate variance (mean of squared differences)
        uint256 variance = (sumSquaredDiff) / numbersLength;

        console.log("(calculateStdDev) variance", variance);

        // Calculate standard deviation (square root of variance)
        return _customSqrt(variance);
    }

    function _absoluteSubtraction(uint256 a, uint256 b) internal pure returns (uint256) {
        int256 result = int256(a) - int256(b);
        int256 absVal = result < 0 ? -result : result;

        return uint256(absVal);
    }

    function _customSqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
