// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IPoolInfo } from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";

import {
    LiquidityManagement,
    AfterSwapParams,
    SwapKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

import { ISwapDiscountHook } from "./Interfaces/ISwapDiscountHook.sol";
import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { DiscountCampaign } from "./DiscountCampaign.sol";

contract SwapDiscountHook is ISwapDiscountHook, BaseHooks, ERC721, Ownable, VaultGuard, ReentrancyGuard {
    using FixedPoint for uint256;

    // Immutable addresses for factory and router
    address private immutable allowedFactoryAddress;
    address private immutable trustedRouterAddress;

    // Token-related state variables
    address public discountTokenAddress;
    uint256 private _shareTokenId = 1;

    // Mapping to store user swap discount data
    mapping(uint256 => UserSwapData) public override userDiscountMapping;
    mapping(address => CampaignData) public override discountCampaigns;

    constructor(
        IVault vaultInstance,
        address factoryAddress,
        address routerAddress,
        string memory name,
        string memory symbol
    ) VaultGuard(vaultInstance) ERC721(name, symbol) Ownable(msg.sender) {
        allowedFactoryAddress = factoryAddress;
        trustedRouterAddress = routerAddress;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override returns (bool) {
        return factory == allowedFactoryAddress && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallAfterSwap = true;
        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 discountedAmount) {
        if (
            params.kind == SwapKind.EXACT_IN &&
            discountCampaigns[params.pool].campaignAddress != address(0) &&
            address(params.tokenOut) == discountCampaigns[params.pool].rewardToken
        ) {
            mint(params);
        }
        return (true, params.amountCalculatedRaw);
    }

    /**
     * @notice Apply discount and mint a new token for the user.
     * @dev This function mints a token for the user after applying the discount and storing relevant swap data.
     *      The function uses memory for `UserSwapData` to minimize storage operations until the final write to storage.
     * @param params The parameters of the swap after it has been executed.
     *        - params.router: The address of the router handling the swap.
     *        - params.amountCalculatedRaw: The amount swapped by the user.
     *        - params.pool: The liquidity pool involved in the swap.
     */
    function mint(AfterSwapParams calldata params) internal nonReentrant {
        uint256 newTokenId = _shareTokenId++;
        address user = IRouterCommon(params.router).getSender();

        // Use memory for userSwapData until final write to storage
        UserSwapData memory userSwapData;
        userSwapData.userAddress = user;
        userSwapData.swappedAmount = params.amountCalculatedRaw;
        userSwapData.campaignAddress = discountCampaigns[params.pool].campaignAddress;
        userSwapData.timeOfSwap = block.timestamp;

        // Write once to storage
        userDiscountMapping[newTokenId] = userSwapData;

        _mint(user, newTokenId);
    }

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
            revert poolCampaignAlreadyExist();
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
            rewardToken: rewardToken
        });

        // Deploy the DiscountCampaign contract with the struct
        DiscountCampaign discountCampaign = new DiscountCampaign(campaignDetails, owner, address(this));

        // Store campaign details
        campaignData.campaignAddress = address(discountCampaign);
        campaignData.rewardToken = rewardToken;
        campaignData.owner = msg.sender;
        campaignData.timeOfCreation = block.timestamp;

        return address(discountCampaign);
    }

    /**
     * @notice Mark the token as 'claimed' for the given token ID.
     * @dev This function sets the `hasClaimed` status of a token to true.
     *      Can only be called by the respective DiscountCampaign contract.
     * @param tokenID The ID of the token to mark as claimed.
     */
    function setHasClaimed(uint256 tokenID) external override {
        // Ensure the caller is the discount campaign associated with the token
        address campaignAddress = userDiscountMapping[tokenID].campaignAddress;
        if (msg.sender != campaignAddress) revert NOT_AUTHORIZED();

        // Set the 'hasClaimed' status to true
        UserSwapData storage userSwapData = userDiscountMapping[tokenID];
        userSwapData.hasClaimed = true;
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
