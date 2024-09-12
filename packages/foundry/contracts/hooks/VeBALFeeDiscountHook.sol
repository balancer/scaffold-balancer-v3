// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

/**
 * @title VeBAL Fee Discount Hook
 * @notice Applies a 50% discount to the swap fee for users holding veBAL tokens
 */
contract VeBALFeeDiscountHook is BaseHooks, VaultGuard {
    address private immutable _allowedFactory;
    address private immutable _trustedRouter;
    address private immutable _veBAL;

    constructor(IVault vault, address allowedFactory, address trustedRouter, address veBAL) VaultGuard(vault) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        _veBAL = veBAL;
    }

    // Determines if a pool is allowed to register using this hook
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override onlyVault returns (bool) {
        // Only pools deployed by an allowed factory may register
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    // Return HookFlags struct that indicates which hooks this contract supports
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        // Support the `onComputeDynamicSwapFeePercentage` hook
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    // Alter the swap fee percentage
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address, // pool
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool success, uint256 dynamicSwapFeePercentage) {
        // If the router is not trusted, do not apply a fee discount
        if (params.router != _trustedRouter) {
            return (true, staticSwapFeePercentage);
        }

        // If the user owns veBAL, apply a 50% discount to the swap fee
        address user = IRouterCommon(params.router).getSender();

        if (IERC20(_veBAL).balanceOf(user) > 0) {
            return (true, staticSwapFeePercentage / 2);
        }

        // If the user holds zero veBAL, no discount
        return (true, staticSwapFeePercentage);
    }
}
