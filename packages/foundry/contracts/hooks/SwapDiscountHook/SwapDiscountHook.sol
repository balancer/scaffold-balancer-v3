// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
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
import { DiscountCampaign } from "./DiscountCampaign.sol";

contract SwapDiscountHook is ISwapDiscountHook, BaseHooks, ERC721, Ownable, VaultGuard {
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
        if (params.kind == SwapKind.EXACT_IN && discountCampaigns[params.pool].campaignAddress != address(0)) {
            mint(params);
        }
        return (true, params.amountCalculatedRaw);
    }

    /// Apply discount and mint token for the user
    function mint(AfterSwapParams calldata params) internal {
        uint256 newTokenId = _shareTokenId++;
        address user = IRouterCommon(params.router).getSender();

        UserSwapData storage userSwapData = userDiscountMapping[newTokenId];
        userSwapData.userAddress = user;
        userSwapData.swappedAmount = params.amountCalculatedRaw;
        userSwapData.campaignAddress = discountCampaigns[params.pool].campaignAddress;
        userSwapData.timeOfSwap = block.timestamp;

        _mint(user, newTokenId);
    }

    function createCampaign(
        uint256 rewardAmount,
        uint256 expirationTime,
        uint256 coolDownPeriod,
        uint256 discountAmount,
        address pool,
        address owner
    ) external {
        if (discountCampaigns[pool].campaignAddress != address(0)) {
            revert poolCampaignAlreadyExist();
        }
        DiscountCampaign discountCampaign = new DiscountCampaign(
            rewardAmount,
            expirationTime,
            coolDownPeriod,
            discountAmount,
            owner,
            address(this)
        );

        CampaignData storage campaignData = discountCampaigns[pool];
        campaignData.campaignAddress = address(discountCampaign);
        campaignData.owner = msg.sender;
        campaignData.timeOfCreation = block.timestamp;
    }
}
