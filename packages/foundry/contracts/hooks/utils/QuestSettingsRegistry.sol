// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IQuestBoard.sol";

/// @title QuestSettingsRegistry
/// @notice A contract to store quest settings for each incentive token
contract QuestSettingsRegistry is Ownable {
    struct QuestSettings {
        uint48 duration;
        uint256 minRewardPerVote;
        uint256 maxRewardPerVote;
        IQuestBoard.QuestVoteType voteType;
        IQuestBoard.QuestCloseType closeType;
        address[] voterList;
    }

    mapping(address => QuestSettings) public questSettings;

    constructor(address initialOwner) Ownable(initialOwner) { }

    function setQuestSettings(
        address incentiveToken,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        IQuestBoard.QuestVoteType voteType,
        IQuestBoard.QuestCloseType closeType,
        address[] calldata voterList
    ) external onlyOwner {
        questSettings[incentiveToken] =
            QuestSettings(duration, minRewardPerVote, maxRewardPerVote, voteType, closeType, voterList);
    }

    function getQuestSettings(address incentiveToken) external view returns (QuestSettings memory) {
        return questSettings[incentiveToken];
    }
}
