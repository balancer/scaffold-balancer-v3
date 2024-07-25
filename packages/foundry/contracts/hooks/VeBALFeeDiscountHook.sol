// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {
    BaseHooks,
    IVault,
    IHooks,
    TokenConfig,
    LiquidityManagement
} from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VeBAL Fee Discount Hook
 * @notice Applies a 50% discount to the swap fee for users holding veBAL tokens
 */
contract VeBALFeeDiscountHook is BaseHooks {
    address private immutable _allowedFactory;
    address private immutable _trustedRouter;
    IERC20 private immutable _veBAL;

    constructor(IVault vault, address allowedFactory, address trustedRouter, IERC20 veBAL) BaseHooks(vault) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        _veBAL = veBAL;
    }

    /**
     * @notice Hook executed when pool is registered
     * @dev Return true if registration was successful
     * @dev Return false to revert the registration of the pool
     * @dev Vault address can be accessed with msg.sender
     * @param factory Address of the pool factory
     * @param pool Address of the pool
     * @return success True if the hook allowed the registration, false otherwise
     */
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) external view override returns (bool) {
        // Only pools deployed by an allowed factory may register
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /**
     * @notice Returns flags informing which hooks are implemented in the contract.
     * @return hookFlags Flags indicating which hooks the contract supports
     */
    function getHookFlags() external pure override returns (IHooks.HookFlags memory hookFlags) {
        // Support the `onComputeDynamicSwapFeePercentage` hook
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    /**
     * @notice Called before `onBeforeSwap` if the pool has dynamic fees.
     * @param params Swap parameters (see IBasePool.PoolSwapParams for struct definition)
     * @param staticSwapFeePercentage Value of the static swap fee, for reference
     * @return success True if the pool wishes to proceed with settlement
     * @return dynamicSwapFee Value of the swap fee
     */
    function onComputeDynamicSwapFee(
        IBasePool.PoolSwapParams calldata params,
        address, // pool
        uint256 staticSwapFeePercentage
    ) external view override returns (bool success, uint256 dynamicSwapFee) {
        // If the router is not trusted, do not apply a fee discount
        if (params.router != _trustedRouter) {
            return (true, staticSwapFeePercentage);
        }

        // Find the user's address
        address user = IRouterCommon(params.router).getSender();

        // If the user owns veBAL, apply a 50% discount to the swap fee
        if (_veBAL.balanceOf(user) > 0) {
            return (true, staticSwapFeePercentage / 2);
        }

        // Otherwise, do not apply the discount
        return (true, staticSwapFeePercentage);
    }
}
