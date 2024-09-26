// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { ISwapDiscountHook } from "./Interfaces/ISwapDiscountHook.sol";

contract DiscountCampaign is IDiscountCampaign, Ownable, ReentrancyGuard {
    // Public state variables
    mapping(uint256 => UserSwapData) public override userDiscountMapping;
    CampaignDetails public campaignDetails;
    uint256 public tokenRewardDistributed;

    // Private state variables
    ISwapDiscountHook private _swapHook;
    uint256 private _maxBuy;

    /**
     * @notice Initializes the discount campaign contract with the provided details.
     * @dev Sets the campaign details, owner, and swap hook address during contract deployment.
     * @param _campaignDetails A struct containing reward amount, expiration time, cooldown period, discount rate, and reward token.
     * @param _owner The owner address of the discount campaign contract.
     * @param _hook The address of the swap hook for tracking user discounts.
     */
    constructor(CampaignDetails memory _campaignDetails, address _owner, address _hook) Ownable(_owner) {
        campaignDetails = _campaignDetails;
        _swapHook = ISwapDiscountHook(_hook);
        _maxBuy = _campaignDetails.rewardAmount;
    }

    /**
     * @notice Updates the campaign details.
     * @dev Only the contract owner can update the campaign details. This will replace the existing campaign parameters.
     * @param _newCampaignDetails A struct containing updated reward amount, expiration time, cooldown period, discount rate, and reward token.
     */
    function updateCampaignDetails(CampaignDetails calldata _newCampaignDetails) external onlyOwner {
        campaignDetails = _newCampaignDetails;
        emit CampaignDetailsUpdated(_newCampaignDetails);
    }

    /**
     * @notice Allows the SwapDiscountHook to update the userDiscountMapping after a swap.
     * @param tokenId The token ID for which the discount data is being updated.
     * @param user The address of the user receiving the discount.
     * @param swappedAmount The amount that was swapped.
     * @param timeOfSwap The timestamp of when the swap occurred.
     */
    function updateUserDiscountMapping(
        uint256 tokenId,
        address user,
        uint256 swappedAmount,
        uint256 timeOfSwap
    ) external override {
        // Ensure only the SwapDiscountHook contract can call this function
        require(msg.sender == address(_swapHook), "Unauthorized");

        userDiscountMapping[tokenId] = UserSwapData({
            userAddress: user,
            campaignAddress: address(this),
            swappedAmount: swappedAmount,
            timeOfSwap: timeOfSwap,
            hasClaimed: false
        });
    }

    /**
     * @notice Checks the validity of a token ID and ensures it meets the required conditions.
     * @dev Reverts if the token ID is invalid, expired, or if the reward has already been claimed.
     * @param tokenID The ID of the token to be validated.
     */
    modifier checkAndAuthorizeTokenId(uint256 tokenID) {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];

        // Ensure the campaign address matches the current contract address
        if (userSwapData.campaignAddress != address(this)) {
            revert InvalidTokenID();
        }

        // Check if the swap happened before the campaign expiration
        if (userSwapData.timeOfSwap > campaignDetails.expirationTime) {
            revert DiscountExpired();
        }

        // Ensure the reward hasn't already been claimed
        if (userSwapData.hasClaimed) {
            revert RewardAlreadyClaimed();
        }

        if (block.timestamp <= campaignDetails.coolDownPeriod) {
            revert CoolDownPeriodNotPassed();
        }
        _;
    }

    /**
     * @notice Claims rewards for a specific token ID.
     * @dev Transfers the reward to the user associated with the token and marks the token as claimed.
     *      Reverts if the reward amount is zero or if the total rewards have been distributed.
     * @param tokenID The ID of the token for which the claim is made.
     */
    function claim(uint256 tokenID) public checkAndAuthorizeTokenId(tokenID) nonReentrant {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];
        uint256 reward = _getClaimableRewards(tokenID);

        if (reward == 0) {
            revert RewardAmountExpired();
        }

        tokenRewardDistributed += reward;
        _maxBuy -= reward;
        userDiscountMapping[tokenID].hasClaimed = true;
        IERC20(campaignDetails.rewardToken).transferFrom(address(this), userSwapData.userAddress, reward);
        _updateDiscount();
    }

    /**
     * @notice Returns the claimable reward amount for a specific token ID.
     * @dev Fetches the claimable reward based on the token's associated swap data and discount rate.
     * @param tokenID The ID of the token to check.
     * @return The claimable reward amount.
     */
    function getClaimableReward(uint256 tokenID) external view returns (uint256) {
        return _getClaimableRewards(tokenID);
    }

    /**
     * @notice Internal function to calculate the claimable reward for a given token ID.
     * @dev The reward is calculated based on the swapped amount and discount rate.
     * @param tokenID The ID of the token for which to calculate the reward.
     * @return claimableReward The amount of reward that can be claimed.
     */
    function _getClaimableRewards(uint256 tokenID) private view returns (uint256 claimableReward) {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];

        // Calculate claimable reward based on the swapped amount and discount rate
        claimableReward = (userSwapData.swappedAmount * campaignDetails.discountRate) / 100e18;
    }

    /**
     * @notice Updates the discount rate based on the distributed rewards.
     * @dev The discount rate decreases proportionally as more rewards are distributed.
     */
    function _updateDiscount() private {
        campaignDetails.discountRate =
            campaignDetails.discountRate *
            (1 - tokenRewardDistributed / campaignDetails.rewardAmount);
    }
}
