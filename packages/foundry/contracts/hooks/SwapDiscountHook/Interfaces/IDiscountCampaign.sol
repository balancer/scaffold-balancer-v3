// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface IDiscountCampaign {
    /// @notice Reverts when the provided token ID does not match the campaign.
    error InvalidTokenID();

    /// @notice Reverts when attempting to claim a discount for a token after the campaign has expired.
    error DiscountExpired();

    /// @notice Reverts when attempting to claim a reward for a token that has already been claimed.
    error RewardAlreadyClaimed();

    /// @notice Reverts when the total reward amount has already been distributed, and no further rewards can be claimed.
    error RewardAmountExpired();

    /// @notice Reverts when attempting to claim a reward without waiting for the required cooldown period.
    error CoolDownPeriodNotPassed();

    /// @notice Reverts when attempting to interact with an expired campaign.
    error CampaignExpired();

    /// @notice Reverts when the caller is not authorized to perform the action.
    error NOT_AUTHORIZED();

    /**
     * @notice Contains parameters related to a discount campaign.
     * @param rewardAmount Total rewards available for the campaign.
     * @param expirationTime Campaign expiration timestamp.
     * @param coolDownPeriod Time a user must wait between swaps to be eligible for rewards.
     * @param discountRate Percentage rate for discounts based on swaps.
     * @param rewardToken Token used to reward users.
     * @param poolAddress Address of the associated liquidity pool.
     * @param owner Owner of the campaign.
     */
    struct CampaignDetails {
        bytes32 campaignID;
        uint256 rewardAmount;
        uint256 expirationTime;
        uint256 coolDownPeriod;
        uint256 discountRate;
        address rewardToken;
        address poolAddress;
        address owner;
    }

    /**
     * @notice Contains user-specific data related to a swap.
     * @param userAddress Address of the participating user.
     * @param campaignAddress Address of the discount campaign contract.
     * @param swappedAmount Amount swapped during the campaign.
     * @param timeOfSwap Timestamp of the swap.
     * @param hasClaimed Indicates if the reward for this swap has been claimed.
     */
    struct UserSwapData {
        bytes32 campaignID;
        address userAddress;
        address campaignAddress;
        uint256 swappedAmount;
        uint256 timeOfSwap;
        bool hasClaimed;
    }

    /**
     * @notice Updates user discount mapping for a given token ID.
     * @dev Can only be called by authorized contracts.
     * @param tokenId ID of the token being updated.
     * @param user Address of the user whose discount is being recorded.
     * @param swappedAmount Amount of tokens swapped.
     * @param timeOfSwap Timestamp of the swap.
     */
    function updateUserDiscountMapping(
        bytes32 campaignID,
        uint256 tokenId,
        address user,
        uint256 swappedAmount,
        uint256 timeOfSwap
    ) external;

    /**
     * @notice Updates campaign details.
     * @param _newCampaignDetails Struct containing the new campaign details.
     */
    function updateCampaignDetails(CampaignDetails calldata _newCampaignDetails) external;

    /**
     * @notice Retrieves swap data for a specific token ID.
     * @param tokenId ID of the token.
     * @return campaignID Campaign ID related to the token.
     * @return userAddress User who made the swap.
     * @return campaignAddress Campaign address.
     * @return swappedAmount Amount swapped.
     * @return timeOfSwap Timestamp of the swap.
     * @return hasClaimed Indicates if the reward was claimed.
     */
    function userDiscountMapping(
        uint256 tokenId
    )
        external
        view
        returns (
            bytes32 campaignID,
            address userAddress,
            address campaignAddress,
            uint256 swappedAmount,
            uint256 timeOfSwap,
            bool hasClaimed
        );

    /**
     * @notice Retrieves details of the discount campaign.
     * @return campaignID Campaign ID.
     * @return rewardAmount Total rewards available.
     * @return expirationTime Expiration time of the campaign.
     * @return coolDownPeriod Cooldown time between swaps for eligibility.
     * @return discountRate Discount rate applied to swaps.
     * @return rewardToken Reward token address.
     * @return poolAddress Address of the liquidity pool.
     * @return owner Campaign owner.
     */
    function campaignDetails()
        external
        view
        returns (
            bytes32 campaignID,
            uint256 rewardAmount,
            uint256 expirationTime,
            uint256 coolDownPeriod,
            uint256 discountRate,
            address rewardToken,
            address poolAddress,
            address owner
        );

    /**
     * @notice Emitted when the campaign details are updated.
     * @param _newCampaignDetails Updated campaign details.
     */
    event CampaignDetailsUpdated(CampaignDetails _newCampaignDetails);
}
