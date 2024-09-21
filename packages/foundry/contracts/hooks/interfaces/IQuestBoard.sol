// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IQuestBoard {
    enum QuestVoteType {
        NORMAL,
        BLACKLIST,
        WHITELIST
    }
    enum QuestCloseType {
        NORMAL,
        ROLLOVER,
        DISTRIBUTE
    }

    function createFixedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 rewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType voteType,
        QuestCloseType closeType,
        address[] calldata voterList
    ) external returns (uint256);

    function createRangedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType voteType,
        QuestCloseType closeType,
        address[] calldata voterList
    ) external returns (uint256);

    function platformFeeRatio() external view returns (uint256);

    function getAllPeriodsForQuestId(uint256 questID) external view returns (uint48[] memory);

    function getCurrentPeriod() external view returns (uint256);
}
