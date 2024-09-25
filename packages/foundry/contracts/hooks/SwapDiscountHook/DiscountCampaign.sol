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
    uint256 public rewardAmount;
    uint256 public expirationTime;
    uint256 public coolDownPeriod;
    uint256 public discountRate;
    address public rewardToken;
    uint256 public tokenRewardDistributed;

    // Private state variables
    uint256 private _previousDiscountRate;
    ISwapDiscountHook private _swapHook;

    /**
     * @dev Constructor to initialize the contract state.
     * @param _rewardAmount The total reward amount.
     * @param _expirationTime The expiration time of the campaign.
     * @param _coolDownPeriod The cool-down period for rewards.
     * @param _discountAmount The initial discount rate.
     * @param _rewardToken The address of the reward token contract.
     * @param _owner The owner of the contract.
     * @param _hook The address of the discount hook for tracking discounts.
     */
    constructor(
        uint256 _rewardAmount,
        uint256 _expirationTime,
        uint256 _coolDownPeriod,
        uint256 _discountAmount,
        address _rewardToken,
        address _owner,
        address _hook
    ) Ownable(_owner) {
        rewardAmount = _rewardAmount;
        expirationTime = _expirationTime;
        coolDownPeriod = _coolDownPeriod;
        discountRate = _discountAmount;
        rewardToken = _rewardToken;
        _swapHook = ISwapDiscountHook(_hook);
    }

    /**
     * @dev Modifier to check the validity of the token ID.
     * Reverts if the token ID is invalid or if the discount has expired.
     * @param tokenID The ID of the token to be validated.
     */
    modifier authorizeTokenId(uint256 tokenID) {
        (address user, address campaignAddress, , uint256 timeOfSwap, bool hasClaimed) = _swapHook.userDiscountMapping(
            tokenID
        );
        if (campaignAddress != address(this)) {
            revert InvalidTokenID();
        }
        if (timeOfSwap > expirationTime) {
            revert DiscountExpired();
        }

        if (hasClaimed == true) {
            revert RewardAlreadyClaimed();
        }
        _;
    }

    /**
     * @dev Claim rewards for a specific token ID.
     * Transfers the token to the contract and rewards the user with claimable tokens.
     * @param tokenID The ID of the token for which the claim is made.
     */
    function claim(uint256 tokenID) public authorizeTokenId(tokenID) nonReentrant {
        (address user, , , , ) = _swapHook.userDiscountMapping(tokenID);
        uint256 reward = _getClaimableRewards(tokenID);

        if (reward == 0 && tokenRewardDistributed == rewardAmount) {
            revert RewardAmountExpired();
        }

        IERC20(rewardToken).transferFrom(address(this), user, reward);
        tokenRewardDistributed += reward;
        updateDiscount();
        _swapHook.setHasClaimed(tokenID);
    }

    /**
     * @dev Get the claimable reward for a specific token ID.
     * @param tokenID The ID of the token to check.
     * @return The claimable reward amount.
     */
    function getClaimableReward(uint256 tokenID) external view returns (uint256) {
        return _getClaimableRewards(tokenID);
    }

    /**
     * @dev Internal function to calculate the claimable rewards for a token ID.
     * @param tokenID The ID of the token.
     * @return claimableReward The amount of reward that can be claimed.
     */
    function _getClaimableRewards(
        uint256 tokenID
    ) internal view authorizeTokenId(tokenID) returns (uint256 claimableReward) {
        (, , uint256 swappedAmount, , ) = _swapHook.userDiscountMapping(tokenID);

        // Calculate claimable reward based on the swapped amount and discount rate
        claimableReward = (swappedAmount * discountRate) / 100e18;
    }

    /**
     * @dev Update the discount rate based on the reward distribution.
     * The discount rate decreases as more rewards are distributed.
     */
    function updateDiscount() internal {
        discountRate = discountRate * (1 - tokenRewardDistributed / rewardAmount);
    }
}
