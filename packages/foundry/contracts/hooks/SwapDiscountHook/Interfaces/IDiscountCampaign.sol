// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface IDiscountCampaign {
    error InvalidTokenID();
    error DiscountExpired();
    error RewardAlreadyClaimed();
    error RewardAmountExpired();

    // Struct to group campaign-related parameters
    struct CampaignDetails {
        uint256 rewardAmount;
        uint256 expirationTime;
        uint256 coolDownPeriod;
        uint256 discountRate;
        address rewardToken;
    }

    event CampaignDetailsUpdated(CampaignDetails _newCampaignDetails);
}
