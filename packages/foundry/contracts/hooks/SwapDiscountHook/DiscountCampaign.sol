// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { ISwapDiscountHook } from "./Interfaces/ISwapDiscountHook.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";

/**
 * @title DiscountCampaign
 * @notice This contract is used to manage discount campaigns, allowing users to earn rewards through swaps.
 * @dev Implements IDiscountCampaign interface. Includes reward distribution, user discount data updates, and campaign management.
 */
contract DiscountCampaign is IDiscountCampaign, Ownable, ReentrancyGuard {
    /// @notice Maps token IDs to user-specific swap data.
    mapping(uint256 => UserSwapData) public override userDiscountMapping;

    /// @notice Holds the details of the current discount campaign.
    CampaignDetails public campaignDetails;

    /// @notice Total amount of reward tokens distributed so far.
    uint256 public tokenRewardDistributed;

    /// @notice Address of the discount campaign factory that can manage campaign updates.
    address public discountCampaignFactory;

    /// @notice Address of the swap discount hook for tracking user swaps.
    ISwapDiscountHook private _swapHook;

    /// @notice Maximum buyable reward amount during the campaign.
    uint256 private _maxBuy;

    /// @notice Maximum discount rate available in the campaign.
    uint256 private _maxDiscountRate;

    /**
     * @notice Initializes the discount campaign contract with the provided details.
     * @dev Sets the campaign details, owner, and swap hook address during contract deployment.
     * @param _campaignDetails A struct containing reward amount, expiration time, cooldown period, discount rate, and reward token.
     * @param _owner The owner address of the discount campaign contract.
     * @param _hook The address of the swap hook for tracking user discounts.
     * @param _discountCampaignFactory The address of the discount campaign factory.
     */
    constructor(
        CampaignDetails memory _campaignDetails,
        address _owner,
        address _hook,
        address _discountCampaignFactory
    ) Ownable(_owner) {
        campaignDetails = _campaignDetails;
        _swapHook = ISwapDiscountHook(_hook);
        _maxBuy = _campaignDetails.rewardAmount;
        _maxDiscountRate = _campaignDetails.discountRate;
        discountCampaignFactory = _discountCampaignFactory;
    }

    /**
     * @notice Modifier to restrict access to the factory contract.
     * @dev Reverts with `NOT_AUTHORIZED` if the caller is not the factory.
     */
    modifier onlyFactory() {
        if (msg.sender != discountCampaignFactory) {
            revert NOT_AUTHORIZED();
        }
        _;
    }

    /**
     * @notice Modifier to check and authorize a token ID before processing claims.
     * @dev Ensures the token is valid, the campaign has not expired, and the reward has not been claimed.
     * @param tokenID The ID of the token to be validated.
     */
    modifier checkAndAuthorizeTokenId(uint256 tokenID) {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];

        // Ensure the campaign address matches the current contract address
        if (userSwapData.campaignAddress != address(this)) {
            revert InvalidTokenID();
        }

        // Ensure the campaign ID matches the current campaign ID
        if (userSwapData.campaignID != campaignDetails.campaignID) {
            revert CampaignExpired();
        }

        // Check if the swap happened before the campaign expiration
        if (block.timestamp > campaignDetails.expirationTime) {
            revert DiscountExpired();
        }

        // Ensure the reward hasn't already been claimed
        if (userSwapData.hasClaimed) {
            revert RewardAlreadyClaimed();
        }

        // Ensure the cooldown period has passed
        if (userSwapData.timeOfSwap + campaignDetails.coolDownPeriod > block.timestamp) {
            revert CoolDownPeriodNotPassed();
        }
        _;
    }

    /**
     * @notice Updates the campaign details.
     * @dev Can only be called by the factory contract. This will replace the existing campaign parameters.
     * @param _newCampaignDetails A struct containing updated reward amount, expiration time, cooldown period, discount rate, and reward token.
     */
    function updateCampaignDetails(CampaignDetails calldata _newCampaignDetails) external onlyFactory {
        campaignDetails = _newCampaignDetails;
        emit CampaignDetailsUpdated(_newCampaignDetails);
    }

    /**
     * @notice Allows the SwapDiscountHook to update the user discount mapping after a swap.
     * @dev Can only be called by the SwapDiscountHook contract.
     * @param campaignID The ID of the campaign associated with the user.
     * @param tokenId The token ID for which the discount data is being updated.
     * @param user The address of the user receiving the discount.
     * @param swappedAmount The amount that was swapped.
     * @param timeOfSwap The timestamp of when the swap occurred.
     */
    function updateUserDiscountMapping(
        bytes32 campaignID,
        uint256 tokenId,
        address user,
        uint256 swappedAmount,
        uint256 timeOfSwap
    ) external override {
        require(msg.sender == address(_swapHook), "Unauthorized");

        userDiscountMapping[tokenId] = UserSwapData({
            campaignID: campaignID,
            userAddress: user,
            campaignAddress: address(this),
            swappedAmount: swappedAmount,
            timeOfSwap: timeOfSwap,
            hasClaimed: false
        });
    }

    /**
     * @notice Claims rewards for a specific token ID.
     * @dev Transfers the reward to the user associated with the token and marks the token as claimed.
     *      Reverts if the reward amount is zero or if the total rewards have been distributed.
     * @param tokenID The ID of the token for which the claim is made.
     */
    function claim(uint256 tokenID) public checkAndAuthorizeTokenId(tokenID) nonReentrant {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];
        uint256 reward = _getClaimableRewards(userSwapData);

        if (reward == 0) {
            revert RewardAmountExpired();
        }

        tokenRewardDistributed += reward;
        _maxBuy -= reward;
        userDiscountMapping[tokenID].hasClaimed = true;
        TransferHelper.safeTransfer(campaignDetails.rewardToken, userSwapData.userAddress, reward);
        _updateDiscount();
    }

    /**
     * @notice Internal function to calculate the claimable reward for a given token ID.
     * @dev The reward is calculated based on the swapped amount and discount rate.
     * @param tokenID The ID of the token for which to calculate the reward.
     * @return claimableReward The amount of reward that can be claimed.
     */
    function getClaimableReward(uint256 tokenID) external view returns (uint256 claimableReward) {
        UserSwapData memory userSwapData = userDiscountMapping[tokenID];
        return _getClaimableRewards(userSwapData);
    }

    /**
     * @notice Overloaded version of _getClaimableRewards that takes UserSwapData as input.
     * @param userSwapData The UserSwapData struct containing the necessary information for calculating rewards.
     * @return claimableReward The amount of reward that can be claimed.
     */
    function _getClaimableRewards(UserSwapData memory userSwapData) private view returns (uint256 claimableReward) {
        uint256 swappedAmount = userSwapData.swappedAmount;

        // Calculate claimable reward based on the swapped amount and discount rate
        if (swappedAmount <= _maxBuy) {
            claimableReward = (swappedAmount * campaignDetails.discountRate) / 100e18;
        } else {
            claimableReward = (_maxBuy * campaignDetails.discountRate) / 100e18;
        }
    }

    /**
     * @notice Updates the discount rate based on the distributed rewards.
     * @dev The discount rate decreases proportionally as more rewards are distributed.
     */
    function _updateDiscount() private {
        campaignDetails.discountRate =
            (_maxDiscountRate * (campaignDetails.rewardAmount - tokenRewardDistributed)) /
            campaignDetails.rewardAmount;
    }

    /**
     * @notice Recovers any ERC20 tokens that are mistakenly sent to the contract.
     * @dev Can only be called by the contract owner.
     * @param tokenAddress Address of the ERC20 token to recover.
     * @param tokenAmount Amount of tokens to recover.
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        TransferHelper.safeTransfer(tokenAddress, owner(), tokenAmount);
    }
}
