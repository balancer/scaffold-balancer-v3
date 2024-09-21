// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IQuestBoard.sol";

/// @title QuestSettingsRegistry
/// @notice A contract to store quest settings for each incentive token
/// @author 0xtekgrinder & Kogaroshi
contract QuestSettingsRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct QuestSettings {
        uint48 duration;
        uint256 minRewardPerVote;
        uint256 maxRewardPerVote;
        IQuestBoard.QuestVoteType voteType;
        IQuestBoard.QuestCloseType closeType;
        address[] voterList;
    }

    /*//////////////////////////////////////////////////////////////
                             MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address => QuestSettings) public questSettings;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address initialOwner) Ownable(initialOwner) {}

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the quest settings for a specific incentive token
     * @param incentiveToken The incentive token address
     * @return QuestSettings The quest settings for the incentive token
     */
    function getQuestSettings(address incentiveToken) external view returns (QuestSettings memory) {
        return questSettings[incentiveToken];
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the quest settings for a specific incentive token
     * @param incentiveToken The incentive token address
     * @param duration The duration of the quest
     * @param minRewardPerVote The minimum reward per vote
     * @param maxRewardPerVote The maximum reward per vote
     * @param voteType The vote type
     * @param closeType The close type
     * @param voterList The list of voters
     * @custom:require Owner
     */
    function setQuestSettings(
        address incentiveToken,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        IQuestBoard.QuestVoteType voteType,
        IQuestBoard.QuestCloseType closeType,
        address[] calldata voterList
    ) external onlyOwner {
        questSettings[incentiveToken] = QuestSettings(
            duration,
            minRewardPerVote,
            maxRewardPerVote,
            voteType,
            closeType,
            voterList
        );
    }
}
