// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import "../balancer-v2-oracle/library/WeightedPool2TokensMiscData.sol";
import "../balancer-v2-oracle/library/WeightedOracleMath.sol";
import "../balancer-v2-oracle/PoolPriceOracle.sol";
import "./IVolatilityOracle.sol";

contract VolatilityOracle is IVolatilityOracle, PoolPriceOracle {
    using FixedPoint for uint256;
    using WeightedPool2TokensMiscData for bytes32;

    bytes32 internal _miscData;

    function getVolatility(uint256 ago) external view returns (uint256 volatility) {
        if (ago == 0) return 0;

        LogPairPrices[] memory logPairPrices = findAllSamples(_miscData.oracleIndex(), ago);

        if (logPairPrices.length < 2) return 0;

        uint256[] memory ratesOfChange = new uint256[](logPairPrices.length - 1);
        uint256 validValues;
        uint256 timeDuration;

        for (uint256 i = 1; i < logPairPrices.length; i++) {
            if (logPairPrices[i - 1].timestamp == 0) continue;

            uint256 price1 = WeightedOracleMath._fromLowResLog(logPairPrices[i - 1].logPairPrice);
            uint256 price2 = WeightedOracleMath._fromLowResLog(logPairPrices[i].logPairPrice);
            uint256 timestamp1 = ((logPairPrices[i - 1].timestamp));
            uint256 timestamp2 = ((logPairPrices[i].timestamp));

            uint256 priceChange = _absoluteSubtraction(price2, price1);
            uint256 priceChangeFraction = priceChange.divDown(price1);
            uint256 timeChange = timestamp2 - timestamp1;

            uint256 rateOfChange = priceChangeFraction.divDown(timeChange) / FixedPoint.ONE;

            ratesOfChange[i - 1] = rateOfChange;
            validValues += 1;
            timeDuration += (timestamp2 - timestamp1);
        }

        volatility = _calculateStdDev(ratesOfChange, validValues);
        volatility = volatility.mulDown(timeDuration * FixedPoint.ONE).divDown(ago * FixedPoint.ONE);

        return volatility;
    }

    function updateOracle(uint256 balanceToken0, uint256 balanceToken1) public {
        bytes32 miscData = _miscData;

        int256 logSpotPrice = WeightedOracleMath._calcLogSpotPrice(
            FixedPoint.ONE,
            balanceToken0,
            FixedPoint.ONE,
            balanceToken1
        );

        int256 logBPTPrice = WeightedOracleMath._calcLogBPTPrice(
            FixedPoint.ONE,
            balanceToken0,
            miscData.logTotalSupply()
        );

        uint256 oracleCurrentIndex = miscData.oracleIndex();
        uint256 oracleCurrentSampleInitialTimestamp = miscData.oracleSampleCreationTimestamp();
        uint256 oracleUpdatedIndex = _processPriceData(
            oracleCurrentSampleInitialTimestamp,
            oracleCurrentIndex,
            logSpotPrice
        );

        if (oracleCurrentIndex != oracleUpdatedIndex) {
            miscData = miscData.setOracleIndex(oracleUpdatedIndex);
            miscData = miscData.setOracleSampleCreationTimestamp(block.timestamp);
            _miscData = miscData;
        }
    }

    function _calculateStdDev(uint256[] memory numbers, uint256 numbersLength) internal view returns (uint256) {
        if (numbersLength == 0) return 0;
        if (numbers.length == 0) return 0;

        uint256 sum = 0;
        for (uint256 i = numbers.length - numbersLength; i < numbers.length; i++) {
            sum += numbers[i];
        }

        uint256 mean = (sum) / numbersLength;

        uint256 sumSquaredDiff = 0;
        for (uint256 i = numbers.length - numbersLength; i < numbers.length; i++) {
            if (numbers[i] > mean) {
                uint256 diff = ((numbers[i]) - mean);
                sumSquaredDiff += (diff * diff);
            } else {
                uint256 diff = (mean - (numbers[i]));
                sumSquaredDiff += (diff * diff);
            }
        }

        uint256 variance = (sumSquaredDiff) / numbersLength;

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
