// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IDiscountCampaignFactory
 * @notice Interface for the Discount Campaign Factory, responsible for creating and managing discount campaigns.
 */
interface IDiscountCampaignFactory {
    /// @notice Reverts if a campaign for the specified pool already exists.
    error PoolCampaignAlreadyExist();

    /// @notice Reverts if a campaign for the specified pool does not exist.
    error PoolCampaignDoesnotExist();

    /// @notice Reverts if attempting to update a campaign that has not expired.
    error PoolCampaignHasnotExpired();

    /// @notice Reverts if the provided reward token is invalid for the campaign.
    error InvalidRewardToken();

    /// @notice Reverts if the provided hook address is invalid.
    error InvalidHookAddress();

    /// @notice Reverts if the reward amount balance is insufficient for the campaign.
    error InsufficientRewardAmountBalance();

    /// @notice Reverts if the pool address associated with a campaign is changed.
    error PoolAddressCannotBeChanged();

    /// @notice Reverts if the caller is not authorized to perform the action.
    error NOT_AUTHORIZED();

    /**
     * @notice Emitted when a campaign is updated with new parameters.
     * @param campaign Address of the updated discount campaign.
     * @param rewardAmount Updated reward amount for the campaign.
     * @param expirationTime Updated expiration time for the campaign.
     * @param coolDownPeriod Updated cooldown period for the campaign.
     * @param discountAmount Updated discount rate for the campaign.
     * @param pool Address of the associated liquidity pool.
     * @param owner Address of the campaign owner.
     * @param rewardToken Address of the reward token used for the campaign.
     */
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

    /**
     * @notice Emitted when a new campaign is created.
     * @param campaign Address of the newly created discount campaign.
     * @param rewardAmount Total reward amount for the campaign.
     * @param expirationTime Expiration time for the campaign.
     * @param coolDownPeriod Cooldown period for the campaign.
     * @param discountAmount Discount rate for the campaign.
     * @param pool Address of the associated liquidity pool.
     * @param owner Address of the campaign owner.
     * @param rewardToken Address of the reward token used for the campaign.
     */
    event CampaignCreated(
        address indexed campaign,
        uint256 rewardAmount,
        uint256 expirationTime,
        uint256 coolDownPeriod,
        uint256 discountAmount,
        address pool,
        address owner,
        address rewardToken
    );

    /**
     * @notice Struct representing campaign data.
     * @param campaignAddress Address of the discount campaign contract.
     * @param owner Address of the campaign owner.
     */
    struct CampaignData {
        address campaignAddress;
        address owner;
    }

    /**
     * @notice Struct representing the parameters required to create or update a discount campaign.
     * @param rewardAmount Total reward amount for the campaign.
     * @param expirationTime Campaign expiration timestamp.
     * @param coolDownPeriod Cooldown period required between swaps to be eligible for rewards.
     * @param discountAmount Discount rate for the campaign.
     * @param pool Address of the associated liquidity pool.
     * @param owner Address of the campaign owner.
     * @param rewardToken Address of the reward token for the campaign.
     */
    struct CampaignParams {
        uint256 rewardAmount;
        uint256 expirationTime;
        uint256 coolDownPeriod;
        uint256 discountAmount;
        address pool;
        address owner;
        address rewardToken;
    }

    /**
     * @notice Retrieves the discount campaign data for a specific pool address.
     * @param poolAddress The address of the liquidity pool.
     * @return campaignAddress The address of the discount campaign contract.
     * @return owner The address of the campaign owner.
     */
    function discountCampaigns(address poolAddress) external view returns (address campaignAddress, address owner);
}
