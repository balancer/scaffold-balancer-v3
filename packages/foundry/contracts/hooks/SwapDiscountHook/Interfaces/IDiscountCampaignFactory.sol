// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface IDiscountCampaignFactory {
    error poolCampaignAlreadyExist();
    error InvalidRewardToken();
    error NOT_AUTHORIZED();

    struct CampaignData {
        address campaignAddress;
        address owner;
        address rewardToken;
        uint256 timeOfCreation;
    }

    /// Mapping from token ID to user swap data
    function discountCampaigns(
        address poolAddress
    ) external view returns (address campaignAddress, address owner, address rewardToken, uint256 timeOfCreation);
}
