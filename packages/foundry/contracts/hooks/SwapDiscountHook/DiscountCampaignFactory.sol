// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IPoolInfo } from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { IDiscountCampaignFactory } from "./Interfaces/IDiscountCampaignFactory.sol";
import { ISwapDiscountHook } from "./Interfaces/ISwapDiscountHook.sol";
import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { DiscountCampaign } from "./DiscountCampaign.sol";

contract DiscountCampaignFactory is ReentrancyGuard, IDiscountCampaignFactory, Ownable {
    // Mapping to store user swap discount data
    mapping(address => CampaignData) public override discountCampaigns;

    address public swapDiscountHook;

    constructor() Ownable(msg.sender) {}

    modifier onlyCampaignOwner(address pool) {
        if (msg.sender != discountCampaigns[pool].owner) revert NOT_AUTHORIZED();
        _;
    }

    modifier campaignExists(address pool) {
        address campaignAddress = discountCampaigns[pool].campaignAddress;
        if (campaignAddress == address(0)) revert PoolCampaignDoesnotExist();
        (, , , , , , address poolAddress, ) = IDiscountCampaign(discountCampaigns[pool].campaignAddress)
            .campaignDetails();
        if (pool != poolAddress) {
            revert PoolAddressCannotBeChanged();
        }
        _;
    }

    modifier campaignNotExpired(address pool) {
        (, , uint256 expirationTime, , , , , ) = IDiscountCampaign(discountCampaigns[pool].campaignAddress)
            .campaignDetails();
        if (expirationTime > block.timestamp) {
            revert PoolCampaignHasnotExpired();
        }
        _;
    }

    modifier verifyHook(address _hookAddress) {
        if (_hookAddress == address(0)) {
            revert InvalidHookAddress();
        }
        _;
    }

    modifier isHookUpdated() {
        if (swapDiscountHook == address(0)) {
            revert InvalidHookAddress();
        }
        _;
    }

    function setSwapDiscountHook(address _hookAddress) external onlyOwner verifyHook(_hookAddress) {
        swapDiscountHook = _hookAddress;
    }

    /**
     * @notice Create a new discount campaign for a specific liquidity pool.
     * @dev Creates a new `DiscountCampaign` contract and stores its details.
     *      Reverts if a campaign for the specified pool already exists or if the reward token is invalid.
     * @param params The parameters for creating the discount campaign.
     * @return The address of the newly created `DiscountCampaign` contract.
     */
    function createCampaign(CampaignParams memory params) external nonReentrant isHookUpdated returns (address) {
        CampaignData storage campaignData = discountCampaigns[params.pool];

        if (campaignData.campaignAddress != address(0)) revert PoolCampaignAlreadyExist();
        validateTokenAndPool(params.pool, params.rewardToken);

        // Prepare campaign details
        IDiscountCampaign.CampaignDetails memory campaignDetails = _prepareCampaignDetails(params);

        // Deploy the DiscountCampaign contract with the struct
        DiscountCampaign discountCampaign = new DiscountCampaign(
            campaignDetails,
            params.owner,
            swapDiscountHook,
            address(this)
        );
        TransferHelper.safeTransfer(params.rewardToken, address(discountCampaign), params.rewardAmount);
        IDiscountCampaign(address(discountCampaign)).updateCampaignDetails(campaignDetails);

        // Store campaign details
        campaignData.campaignAddress = address(discountCampaign);
        campaignData.owner = msg.sender;

        emit CampaignCreated(
            address(discountCampaign),
            params.rewardAmount,
            params.expirationTime,
            params.coolDownPeriod,
            params.discountAmount,
            params.pool,
            params.owner,
            params.rewardToken
        );

        return address(discountCampaign);
    }

    /**
     * @notice Update the campaign details for a specific pool.
     * @dev Updates the campaign details if the campaign has expired and belongs to the caller.
     * @param params The parameters for updating the discount campaign.
     */
    function updateCampaign(
        CampaignParams memory params
    ) external campaignExists(params.pool) onlyCampaignOwner(params.pool) campaignNotExpired(params.pool) {
        validateTokenAndPool(params.pool, params.rewardToken);

        address campaignAddress = discountCampaigns[params.pool].campaignAddress;

        IDiscountCampaign.CampaignDetails memory campaignDetails = _prepareCampaignDetails(params);

        TransferHelper.safeTransfer(params.rewardToken, campaignAddress, params.rewardAmount);

        IDiscountCampaign(campaignAddress).updateCampaignDetails(campaignDetails);

        uint256 rewardAmount = params.rewardAmount;
        uint256 expirationTime = params.expirationTime;
        uint256 coolDownPeriod = params.coolDownPeriod;
        uint256 discountAmount = params.discountAmount;
        address pool = params.pool;
        address owner = params.owner;
        address rewardToken = params.rewardToken;
        bytes32 campaignID = 

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

    function _prepareCampaignDetails(
        CampaignParams memory params
    ) internal view returns (IDiscountCampaign.CampaignDetails memory) {
        return
            IDiscountCampaign.CampaignDetails({
                campaignID: keccak256(abi.encode(block.timestamp, params.expirationTime)),
                rewardAmount: params.rewardAmount,
                expirationTime: block.timestamp + params.expirationTime,
                coolDownPeriod: block.timestamp + params.coolDownPeriod,
                discountRate: params.discountAmount,
                rewardToken: params.rewardToken,
                poolAddress: params.pool,
                owner: params.owner
            });
    }

    function recoverERC20(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, owner(), amount);
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

    /**
     * @notice Validate the token and pool for a campaign.
     * @param pool The address of the liquidity pool.
     * @param rewardToken The address of the reward token to validate.
     */
    function validateTokenAndPool(address pool, address rewardToken) internal view {
        if (!_checkToken(pool, rewardToken)) revert InvalidRewardToken();
    }
}
