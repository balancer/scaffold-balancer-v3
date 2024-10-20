// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "./library/Buffer.sol";
import "./library/Samples.sol";
import "./library/Errors.sol";

import "./interface/IPriceOracle.sol";

import "forge-std/console.sol";

contract PoolPriceOracle {
    using Buffer for uint256;
    using Samples for bytes32;

    uint256 private constant _MAX_SAMPLE_DURATION = 1 seconds;

    mapping(uint256 => bytes32) public _samples;

    struct LogPairPrices {
        int256 logPairPrice;
        uint256 timestamp;
    }

    function findAllSamples(
        uint256 latestIndex,
        uint256 ago
    ) public view returns (LogPairPrices[] memory) {
        console.log("(findAllSamples) Here 1", latestIndex, ago);
        uint256 blockTimeStamp = block.timestamp;
        console.log("(findAllSamples) blockTimeStamp", blockTimeStamp);
        uint256 lookUpTime = blockTimeStamp - ago;
        console.log("(findAllSamples) lookUpTime", lookUpTime);
        uint256 offset = latestIndex < Buffer.SIZE ? 0 : latestIndex.next();
        console.log("(findAllSamples) offset", offset);

        uint256 low = 0;
        uint256 high = latestIndex < Buffer.SIZE ? latestIndex : Buffer.SIZE - 1;
        uint256 mid;

        uint256 sampleTimestamp;

        while (low <= high) {
            console.log("(findAllSamples) low", low);
            console.log("(findAllSamples) high", high);

            uint256 midWithoutOffset = (high + low) / 2;
            mid = midWithoutOffset.add(offset);
            console.log("(findAllSamples) midWithoutOffset, mid", midWithoutOffset, mid);

            (, , , , , , uint256 timestamp) = getSample(mid.add(offset));

            sampleTimestamp = timestamp;
            console.log("(findAllSamples) sampleTimestamp", sampleTimestamp);

            if (sampleTimestamp < lookUpTime) {
                console.log("(findAllSamples) sampleTimestamp < lookUpTime is true");
                low = midWithoutOffset + 1;
            } else if (sampleTimestamp > lookUpTime) {
                console.log("(findAllSamples) sampleTimestamp > lookUpTime is true");
                high = midWithoutOffset - 1;
            } else {
                console.log("(findAllSamples) break low high mid", low, high, mid);
                console.log("(findAllSamples) break midWithoutOffset", midWithoutOffset);
                break;
            }
        }

        console.log("(findAllSamples) out low high mid", low, high, mid);
        uint256 lowerBound;
        uint256 upperBound;

        if (latestIndex < Buffer.SIZE) {
            lowerBound = sampleTimestamp <= lookUpTime ? mid : mid > 0 ? mid - 1 : 0;
            upperBound = latestIndex;
        } else {
            lowerBound = sampleTimestamp >= lookUpTime ? mid : mid.prev();
            upperBound = Buffer.SIZE - 1;
        }

        console.log("(findAllSamples) lowerBound, upperBound, offset", lowerBound, upperBound, offset);

        LogPairPrices[] memory logPairPrices = new LogPairPrices[](upperBound - lowerBound + 1);

        for (uint256 i = lowerBound; i <= upperBound; i = i.next()) {
            (int256 logPairPrice, , , , , , uint256 timestamp) = getSample(i.add(offset));
            console.log("(findAllSamples) i, timestamp", i, timestamp, uint256(logPairPrice));
            logPairPrices[i-lowerBound] = (LogPairPrices(logPairPrice, timestamp));
        }

        return logPairPrices;
    }

    function findAllSamples1(
        uint256 latestIndex,
        uint256 ago
    ) public view returns (LogPairPrices[] memory logPairPrices) {
        console.log("(findAllSamples) Here 1", latestIndex, ago);
        uint256 blockTimeStamp = block.timestamp;
        uint256 lookUpTime = blockTimeStamp - ago;
        uint256 offset = latestIndex > (Buffer.SIZE - 1) ? latestIndex - (Buffer.SIZE - 1) : 0;
        console.log("(findAllSamples) offset", offset);

        uint256 low = 0;
        uint256 high = Buffer.SIZE - 1;
        uint256 mid;

        uint256 sampleTimestamp;

        console.log("(findAllSamples) Here 2");

        while (low <= high) {
            console.log("(findAllSamples) low", low);
            console.log("(findAllSamples) high", high);

            mid = (high + low) / 2;
            console.log("(findAllSamples) mid", mid);
            console.log("(findAllSamples) mid.add(offset)", mid.add(offset));
            (, , , , , , uint256 timestamp) = getSample(mid.add(offset));
            sampleTimestamp = timestamp;
            console.log("(findAllSamples) sampleTimestamp", sampleTimestamp);
            console.log("(findAllSamples) lookUpTime", lookUpTime);

            if (sampleTimestamp > lookUpTime) {
                console.log("(findAllSamples) sampleTimestamp > lookUpTime is true");
                low = mid + 1;
            } else if (sampleTimestamp < lookUpTime) {
                console.log("(findAllSamples) sampleTimestamp < lookUpTime is true");
                high = mid - 1;
            } else {
                console.log("(findAllSamples) break low high mid", low, high, mid);
                break;
            }
        }
        console.log("(findAllSamples) Here 3");

        uint256 lowerBound = sampleTimestamp <= lookUpTime ? mid : mid.prev();
        console.log("(findAllSamples) Here 4");
        console.log("(findAllSamples) lowerBound", lowerBound);
        console.log("(findAllSamples) high", high);
        console.log("(findAllSamples) offset", offset);

        for (uint256 i = lowerBound; i <= high; i++) {
            console.log("(findAllSamples) i", i);
            console.log("(findAllSamples) i.add(offset)", i.add(offset));
            (int256 logPairPrice, , , , , , uint256 timestamp) = getSample(i.add(offset));
            console.log("(findAllSamples) timestamp", timestamp);
            logPairPrices[i - lowerBound] = LogPairPrices(logPairPrice, timestamp);
        }
        console.log("(findAllSamples) Here 5");
        return logPairPrices;
    }

    function getSample(
        uint256 index
    )
        public
        view
        returns (
            int256 logPairPrice,
            int256 accLogPairPrice,
            int256 logBptPrice,
            int256 accLogBptPrice,
            int256 logInvariant,
            int256 accLogInvariant,
            uint256 timestamp
        )
    {
        _require(index < Buffer.SIZE, Errors.ORACLE_INVALID_INDEX);

        bytes32 sample = _getSample(index);
        return sample.unpack();
    }

    function getTotalSamples() external pure returns (uint256) {
        return Buffer.SIZE;
    }

    function _processPriceData(
        uint256 latestSampleCreationTimestamp,
        uint256 latestIndex,
        int256 logPairPrice,
        int256 logBptPrice,
        int256 logInvariant
    ) internal returns (uint256) {
        bytes32 sample = _getSample(latestIndex).update(logPairPrice, logBptPrice, logInvariant, block.timestamp);

        bool newSample = block.timestamp - latestSampleCreationTimestamp >= _MAX_SAMPLE_DURATION;
        latestIndex = newSample ? latestIndex.next() : latestIndex;

        _samples[latestIndex] = sample;

        return latestIndex;
    }

    function _getInstantValue(IPriceOracle.Variable variable, uint256 index) public view returns (int256) {
        bytes32 sample = _getSample(index);
        _require(sample.timestamp() > 0, Errors.ORACLE_NOT_INITIALIZED);

        return sample.instant(variable);
    }

    function _getPastAccumulator(
        IPriceOracle.Variable variable,
        uint256 latestIndex,
        uint256 ago
    ) internal view returns (int256) {
        _require(block.timestamp >= ago, Errors.ORACLE_INVALID_SECONDS_QUERY);
        uint256 lookUpTime = block.timestamp - ago;

        bytes32 latestSample = _getSample(latestIndex);
        uint256 latestTimestamp = latestSample.timestamp();

        _require(latestTimestamp > 0, Errors.ORACLE_NOT_INITIALIZED);

        if (latestTimestamp <= lookUpTime) {
            return
                latestSample.accumulator(variable) +
                (latestSample.instant(variable) * int256(lookUpTime - latestTimestamp));
        } else {
            _require(latestTimestamp <= lookUpTime, Errors.ORACLE_QUERY_TOO_OLD);

            (bytes32 prev, bytes32 next) = _findNearestSample(lookUpTime, latestIndex.next());

            if (next.timestamp() - prev.timestamp() > 0) {
                return
                    prev.accumulator(variable) +
                    ((next.accumulator(variable) - prev.accumulator(variable)) *
                        int256(lookUpTime - prev.timestamp())) /
                    int256(next.timestamp() - prev.timestamp());
            } else {
                return prev.accumulator(variable);
            }
        }
    }

    function _findNearestSample(uint256 lookUpDate, uint256 offset) public view returns (bytes32 prev, bytes32 next) {
        uint256 low = 0;
        uint256 high = Buffer.SIZE - 1;
        uint256 mid;

        bytes32 sample;
        uint256 sampleTimestamp;

        while (low <= high) {
            mid = (high + low) / 2;
            sample = _getSample(mid.add(offset));
            sampleTimestamp = sample.timestamp();

            if (sampleTimestamp < lookUpDate) {
                low = mid + 1;
            } else if (sampleTimestamp > lookUpDate) {
                high = mid - 1;
            } else {
                return (sample, sample);
            }
        }

        return sampleTimestamp < lookUpDate ? (sample, _getSample(mid.next())) : (_getSample(mid.prev()), sample);
    }

    function _findNearestSample1(uint256 lookUpDate, uint256 offset) public view returns (uint256 prev, uint256 next) {
        uint256 low = 0;
        uint256 high = Buffer.SIZE - 1;
        uint256 mid;

        bytes32 sample;
        uint256 sampleTimestamp;

        while (low <= high) {
            mid = (high + low) / 2;
            sample = _getSample(mid.add(offset));
            sampleTimestamp = sample.timestamp();

            if (sampleTimestamp < lookUpDate) {
                low = mid + 1;
            } else if (sampleTimestamp > lookUpDate) {
                high = mid - 1;
            } else {
                return (mid, mid);
            }
        }

        return sampleTimestamp < lookUpDate ? (mid, mid.next()) : (mid.prev(), mid);
    }

    function _getSample(uint256 index) internal view returns (bytes32) {
        return _samples[index];
    }
}
