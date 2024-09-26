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

    error CoolDownPeriodNotPassed();

    /**
     * @notice A struct containing key parameters related to a discount campaign.
     * @param rewardAmount Total amount of rewards that can be distributed during the campaign.
     * @param expirationTime The timestamp after which the campaign expires and discounts cannot be claimed.
     * @param coolDownPeriod Time in seconds a user must wait between making swaps to be eligible for rewards.
     * @param discountRate The percentage rate used to calculate discounts for users based on their swaps.
     * @param rewardToken The address of the token used to reward users for participating in the campaign.
     * @param poolAddress The address of the pool associated with the campaign.
     */
    struct CampaignDetails {
        uint256 rewardAmount;
        uint256 expirationTime;
        uint256 coolDownPeriod;
        uint256 discountRate;
        address rewardToken;
        address poolAddress;
    }

    /**
     * @notice A struct used to store user-specific data about a swap and their eligibility for rewards.
     * @param userAddress The address of the user participating in the campaign.
     * @param campaignAddress The address of the associated discount campaign contract.
     * @param swappedAmount The amount of tokens the user swapped during the campaign.
     * @param timeOfSwap The timestamp of when the swap was executed.
     * @param hasClaimed Indicates whether the user has already claimed the discount/reward for this swap.
     */
    struct UserSwapData {
        address userAddress;
        address campaignAddress;
        uint256 swappedAmount;
        uint256 timeOfSwap;
        bool hasClaimed;
    }

    /**
     * @notice Updates the user discount mapping for a given token ID.
     * @dev This function is called by the swap hook to store the discount data for a user after a swap.
     *      Only the authorized hook contract should be able to call this function.
     * @param tokenId The ID of the token being associated with the user's swap.
     * @param user The address of the user for whom the discount is being recorded.
     * @param swappedAmount The amount of tokens that the user swapped.
     * @param timeOfSwap The timestamp when the swap occurred.
     */
    function updateUserDiscountMapping(
        uint256 tokenId,
        address user,
        uint256 swappedAmount,
        uint256 timeOfSwap
    ) external;

    /**
     * @notice Retrieves the swap data associated with a specific token ID.
     * @param tokenId The ID of the token for which the swap data is being requested.
     * @return userAddress The address of the user who made the swap.
     * @return campaignAddress The address of the discount campaign.
     * @return swappedAmount The amount of tokens swapped by the user.
     * @return timeOfSwap The timestamp of when the swap occurred.
     * @return hasClaimed Whether the reward for this swap has been claimed.
     */
    function userDiscountMapping(
        uint256 tokenId
    )
        external
        view
        returns (
            address userAddress,
            address campaignAddress,
            uint256 swappedAmount,
            uint256 timeOfSwap,
            bool hasClaimed
        );

    /**
     * @notice Retrieves the details of the current discount campaign.
     * @return rewardAmount The total amount of rewards available for the campaign.
     * @return expirationTime The timestamp after which the campaign expires.
     * @return coolDownPeriod The required cooldown time between swaps for users to be eligible for rewards.
     * @return discountRate The discount rate applied to swaps.
     * @return rewardToken The token address used for distributing rewards.
     * @return poolAddress The address of the associated liquidity pool for the campaign.
     */
    function campaignDetails()
        external
        view
        returns (
            uint256 rewardAmount,
            uint256 expirationTime,
            uint256 coolDownPeriod,
            uint256 discountRate,
            address rewardToken,
            address poolAddress
        );

    /**
     * @notice Emitted when the campaign details are updated by the contract owner.
     * @param _newCampaignDetails The updated campaign details.
     */
    event CampaignDetailsUpdated(CampaignDetails _newCampaignDetails);
}
