// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Epoch {
    uint256 public startTime;
    uint256 public currentEpoch;
    uint256 public constant EPOCH_DURATION = 1 weeks;

    event NewEpochStarted(uint256 epochNumber, uint256 startTime);

    constructor() {
        startTime = block.timestamp;
        currentEpoch = 0;
        emit NewEpochStarted(currentEpoch, startTime);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    function getTimeUntilNextEpoch() public view returns (uint256) {
        uint256 timeElapsedInCurrentEpoch = (block.timestamp - startTime) %
            EPOCH_DURATION;

        if (timeElapsedInCurrentEpoch >= EPOCH_DURATION) {
            return 0;
        }

        return EPOCH_DURATION - timeElapsedInCurrentEpoch;
    }

    function isNewEpoch() public view returns (bool) {
        return (block.timestamp - startTime) / EPOCH_DURATION > currentEpoch;
    }

    function startNewEpoch() internal {
        require(isNewEpoch(), "Cannot start a new epoch yet");
        currentEpoch++;
        startTime = block.timestamp;
        emit NewEpochStarted(currentEpoch, startTime);
    }
}
