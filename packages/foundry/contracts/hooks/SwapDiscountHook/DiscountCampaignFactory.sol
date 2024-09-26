// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IPoolInfo } from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";

import { IDiscountCampaignFactory } from "./Interfaces/IDiscountCampaignFactory.sol";
import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { DiscountCampaign } from "./DiscountCampaign.sol";

contract DiscountCampaignFactory is ReentrancyGuard, IDiscountCampaignFactory, Ownable {
    // Mapping to store user swap discount data
    mapping(address => CampaignData) public override discountCampaigns;

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Create a new discount campaign for a specific liquidity pool.
     * @dev The function creates a new `DiscountCampaign` contract and stores its details.
     *      Reverts if a campaign for the specified pool already exists or if the reward token is invalid.
     * @param rewardAmount The total reward amount for the campaign.
     * @param expirationTime The expiration time of the discount campaign.
     * @param coolDownPeriod The cooldown period for rewards between claims.
     * @param discountAmount The discount rate offered in the campaign.
     * @param pool The address of the liquidity pool for which the campaign is being created.
     * @param owner The address of the owner of the campaign.
     * @param rewardToken The address of the reward token used in the campaign.
     * @return The address of the newly created `DiscountCampaign` contract.
     */
    function createCampaign(
        uint256 rewardAmount,
        uint256 expirationTime,
        uint256 coolDownPeriod,
        uint256 discountAmount,
        address pool,
        address owner,
        address rewardToken
    ) external nonReentrant returns (address) {
        CampaignData storage campaignData = discountCampaigns[pool];

        if (campaignData.campaignAddress != address(0)) {
            revert PoolCampaignAlreadyExist();
        }

        if (!_checkToken(pool, rewardToken)) {
            revert InvalidRewardToken();
        }

        // Create a CampaignDetails struct to pass into the constructor
        IDiscountCampaign.CampaignDetails memory campaignDetails = IDiscountCampaign.CampaignDetails({
            rewardAmount: rewardAmount,
            expirationTime: expirationTime,
            coolDownPeriod: coolDownPeriod,
            discountRate: discountAmount,
            rewardToken: rewardToken,
            poolAddress: pool,
            owner: owner
        });

        // Deploy the DiscountCampaign contract with the struct
        DiscountCampaign discountCampaign = new DiscountCampaign(campaignDetails, owner, address(this), address(this));

        // Store campaign details
        campaignData.campaignAddress = address(discountCampaign);
        campaignData.rewardToken = rewardToken;
        campaignData.owner = msg.sender;
        campaignData.timeOfCreation = block.timestamp;

        return address(discountCampaign);
    }

    function updateCampaign(
        uint256 rewardAmount,
        uint256 expirationTime,
        uint256 coolDownPeriod,
        uint256 discountAmount,
        address pool,
        address owner,
        address rewardToken
    ) external {
        CampaignData storage campaignData = discountCampaigns[pool];
        address campaignAddress = campaignData.campaignAddress;
        if (campaignAddress == address(0)) {
            revert PoolCampaignDoesnotExist();
        }

        if (msg.sender != campaignData.owner) {
            revert NOT_AUTHORIZED();
        }

        if (campaignData.expirationTime > block.timestamp) {
            revert PoolCampaignHasnotExpired();
        }

        if (!_checkToken(pool, rewardToken)) {
            revert InvalidRewardToken();
        }

        IDiscountCampaign.CampaignDetails memory campaignDetails = IDiscountCampaign.CampaignDetails({
            rewardAmount: rewardAmount,
            expirationTime: expirationTime,
            coolDownPeriod: coolDownPeriod,
            discountRate: discountAmount,
            rewardToken: rewardToken,
            poolAddress: pool,
            owner: owner
        });

        IDiscountCampaign(campaignAddress).updateCampaignDetails(campaignDetails);

        emit CampaignUpdated(
            campaignAddress,
            rewardAmount,
            expirationTime,
            coolDownPeriod,
            discountAmount,
            pool,
            owner,
            rewardToken
        );
    }

    /**
     * @notice Check if the given reward token is valid for the specified pool.
     * @dev This function iterates over the tokens in the pool to check if the reward token matches any of them.
     * @param pool The address of the liquidity pool.
     * @param rewardToken The address of the reward token to validate.
     * @return True if the reward token is valid for the pool, false otherwise.
     */
    function _checkToken(address pool, address rewardToken) internal view returns (bool) {
        IERC20[] memory tokens = IPoolInfo(pool).getTokens();
        uint256 tokensLength = tokens.length;

        for (uint256 i = 0; i < tokensLength; i++) {
            if (rewardToken == address(tokens[i])) {
                return true;
            }
        }

        return false;
    }
}
