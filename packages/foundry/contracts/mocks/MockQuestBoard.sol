// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../hooks/interfaces/IQuestBoard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockQuestBoard is IQuestBoard {
    uint256 public currentPeriod;
    uint256 public platformFeeRatio;
    mapping(uint256 => uint48[]) periodsForQuestId;

    constructor(uint256 _platformFeeRatio, uint256 _currentPeriod) {
        currentPeriod = _currentPeriod;
        platformFeeRatio = _platformFeeRatio;
    }

    function setPlatformFeeRatio(uint256 ratio) external {
        platformFeeRatio = ratio;
    }

    function setPeriod(uint256 period) external {
        currentPeriod = period;
    }

    function setPeriodsForQuestId(uint256 questID, uint48[] calldata periods) external {
        periodsForQuestId[questID] = periods;
    }

    function createRangedQuest(
        address, // gauge
        address rewardToken,
        bool, // startNextPeriod
        uint48, // duration
        uint256, // minRewardPerVote
        uint256, // maxRewardPerVote
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType, // voteType
        QuestCloseType, // closeType
        address[] calldata // voterList
    ) external returns (uint256) {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), totalRewardAmount + feeAmount);
        return 1;
    }

    function createFixedQuest(
        address, // gauge
        address rewardToken,
        bool, // startNextPeriod
        uint48, // duration
        uint256, // rewardPerVote
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType, // voteType
        QuestCloseType, // closeType
        address[] calldata // voterList
    ) external returns (uint256) {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), totalRewardAmount + feeAmount);
        return 1;
    }

    function getAllPeriodsForQuestId(uint256 questID) external view returns (uint48[] memory) {
        return periodsForQuestId[questID];
    }

    function getCurrentPeriod() external view returns (uint256) {
        return currentPeriod;
    }
}
