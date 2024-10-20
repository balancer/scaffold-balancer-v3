// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "./library/Buffer.sol";
import "./library/Samples.sol";

import "forge-std/console.sol";

contract PoolPriceOracle {
    using Buffer for uint256;
    using Samples for bytes32;

    uint256 private constant _MAX_SAMPLE_DURATION = 1 seconds;

    mapping(uint256 => bytes32) private _samples;

    struct LogPairPrices {
        int256 logPairPrice;
        uint256 timestamp;
    }

    function findAllSamples(uint256 latestIndex, uint256 ago) public view returns (LogPairPrices[] memory) {
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

            (, uint256 timestamp) = getSample(mid.add(offset));

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
            (int256 logPairPrice, uint256 timestamp) = getSample(i.add(offset));
            console.log("(findAllSamples) i, timestamp", i, timestamp, uint256(logPairPrice));
            logPairPrices[i - lowerBound] = (LogPairPrices(logPairPrice, timestamp));
        }

        return logPairPrices;
    }

    function getSample(uint256 index) public view returns (int256 logPairPrice, uint256 timestamp) {
        // add error for buffer size

        bytes32 sample = _getSample(index);
        return sample.unpack();
    }

    function _processPriceData(
        uint256 latestSampleCreationTimestamp,
        uint256 latestIndex,
        int256 logPairPrice
    ) internal returns (uint256) {
        bytes32 sample = _getSample(latestIndex).update(logPairPrice, block.timestamp);

        bool newSample = block.timestamp - latestSampleCreationTimestamp >= _MAX_SAMPLE_DURATION;
        latestIndex = newSample ? latestIndex.next() : latestIndex;

        _samples[latestIndex] = sample;

        return latestIndex;
    }

    function _getSample(uint256 index) internal view returns (bytes32) {
        return _samples[index];
    }
}
