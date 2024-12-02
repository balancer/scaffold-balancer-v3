// SPDX-License-Identifier: MIT
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
import { IDiscountCampaignFactory } from "./Interfaces/IDiscountCampaignFactory.sol";
import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { DiscountCampaign } from "./DiscountCampaign.sol";

contract SwapDiscountHook is ISwapDiscountHook, BaseHooks, ERC721, Ownable, VaultGuard, ReentrancyGuard {
    using FixedPoint for uint256;

    // Immutable addresses for factory and router
    IDiscountCampaignFactory public discountCampaignFactory;
    address private immutable allowedFactoryAddress;
    address private immutable trustedRouterAddress;
    uint256 private _shareTokenId = 1;

    constructor(
        IVault vaultInstance,
        address _factoryAddress,
        address _routerAddress,
        address _campaignFactory,
        string memory name,
        string memory symbol
    ) VaultGuard(vaultInstance) ERC721(name, symbol) Ownable(msg.sender) {
        allowedFactoryAddress = _factoryAddress;
        trustedRouterAddress = _routerAddress;
        discountCampaignFactory = IDiscountCampaignFactory(_campaignFactory);
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
        (address campaignAddress, ) = discountCampaignFactory.discountCampaigns(params.pool);
        if (campaignAddress != address(0)) {
            IDiscountCampaign campaign = IDiscountCampaign(campaignAddress);
            (bytes32 campaignID, , , , , address rewardToken, address poolAddress, ) = campaign.campaignDetails();
            if (
                params.kind == SwapKind.EXACT_IN &&
                address(params.tokenOut) == rewardToken &&
                poolAddress == params.pool
            ) {
                mint(params, campaign, campaignID);
            }
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
    function mint(
        AfterSwapParams calldata params,
        IDiscountCampaign _campaign,
        bytes32 _campaignID
    ) internal nonReentrant {
        uint256 newTokenId = _shareTokenId++;
        address user = IRouterCommon(params.router).getSender();
        _campaign.updateUserDiscountMapping(_campaignID, newTokenId, user, params.amountCalculatedRaw, block.timestamp);
        _mint(user, newTokenId);
    }

    /**
     * @notice Updates the address of the discount campaign factory.
     * @dev Can only be called by the contract owner. Reverts if the new factory address is invalid.
     * @param newFactory The address of the new discount campaign factory.
     */
    function updateCampaignFactory(address newFactory) external onlyOwner {
        if (newFactory == address(0)) {
            revert InvalidCampaignAddress();
        }
        discountCampaignFactory = IDiscountCampaignFactory(newFactory);
    }
}
