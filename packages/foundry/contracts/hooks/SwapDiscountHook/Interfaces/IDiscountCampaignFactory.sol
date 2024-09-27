// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface IDiscountCampaignFactory {
    error PoolCampaignAlreadyExist();
    error PoolCampaignDoesnotExist();
    error PoolCampaignHasnotExpired();
    error InvalidRewardToken();
    error InsufficientRewardAmountBalance();
    error PoolAddressCannotBeChanged();
    error NOT_AUTHORIZED();

    event CampaignUpdated(
        address indexed campaign,
        uint256 rewardAmount,
        uint256 expirationTime,
        uint256 coolDownPeriod,
        uint256 discountAmount,
        address pool,
        address owner,
        address rewardToken
    );

    struct CampaignData {
        address campaignAddress;
        address owner;
    }

    /// Mapping from token ID to user swap data
    function discountCampaigns(address poolAddress) external view returns (address campaignAddress, address owner);
}
