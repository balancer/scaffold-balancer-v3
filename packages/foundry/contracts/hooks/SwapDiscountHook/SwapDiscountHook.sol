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

contract SwapDiscountHook is ISwapDiscountHook, BaseHooks, ERC721, Ownable, VaultGuard {
    using FixedPoint for uint256;

    // Immutable addresses for factory and router
    address private immutable allowedFactoryAddress;
    address private immutable trustedRouterAddress;

    // Token-related state variables
    address public discountTokenAddress;
    uint256 private _shareTokenId = 1;
    uint64 public swapDiscountRate;
    uint256 public expirationTime = 1 days;

    // Mapping to store user swap discount data
    mapping(uint256 => UserSwapData) public override userDiscountMapping;

    constructor(
        IVault vaultInstance,
        address factoryAddress,
        address routerAddress,
        address tokenAddress,
        uint64 discountRate,
        string memory name,
        string memory symbol
    ) VaultGuard(vaultInstance) ERC721(name, symbol) Ownable(msg.sender) {
        allowedFactoryAddress = factoryAddress;
        trustedRouterAddress = routerAddress;
        discountTokenAddress = tokenAddress;
        swapDiscountRate = discountRate;
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
            swapDiscountRate > 0 && address(params.tokenOut) == discountTokenAddress && params.kind == SwapKind.EXACT_IN
        ) {
            discountedAmount = _calculateDiscount(params);
            _applyDiscount(params, discountedAmount);
        }
        return (true, params.amountCalculatedRaw);
    }

    /// Calculate the discount based on swap parameters
    function _calculateDiscount(AfterSwapParams calldata params) internal view returns (uint256) {
        return params.amountCalculatedRaw.mulDown(swapDiscountRate);
    }

    /// Apply discount and mint token for the user
    function _applyDiscount(AfterSwapParams calldata params, uint256 discountedAmount) internal {
        uint256 newTokenId = _shareTokenId++;
        address user = IRouterCommon(params.router).getSender();

        UserSwapData storage userSwapData = userDiscountMapping[newTokenId];
        userSwapData.userAddress = user;
        userSwapData.expirationTime = block.timestamp + expirationTime;
        userSwapData.discountedTokenAmount = discountedAmount;

        _mint(user, newTokenId);
        emit SwapDiscountGranted(newTokenId, user, userSwapData.expirationTime, discountedAmount);
    }

    function updateDiscountRate(uint64 newDiscountRate) external onlyOwner {
        require(newDiscountRate <= 100, "IDR");
        swapDiscountRate = newDiscountRate;
    }

    function updateExpirationTime(uint256 newExpirationTime) external onlyOwner {
        require(newExpirationTime > block.timestamp, "IET");
        expirationTime = newExpirationTime;
    }
}
