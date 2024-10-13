// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

contract CalculateDynamicFeeHook is BaseHooks, VaultGuard {

        // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;
    // Only trusted routers are allowed to call this hook, because the hook relies on the `getSender` implementation
    // implementation to work properly.
    address private immutable _trustedRouter; //see this what is trusted router
    // The gauge token received from staking the 80/20 BAL/WETH pool token.
    // IERC20 private immutable _veBAL;

    constructor(IVault vault, address allowedFactory, address trustedRouter) VaultGuard(vault) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        // _veBAL = IERC20(veBAL);
    }

    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata 
    ) public override onlyVault returns (bool) {
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool); 
    }

    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // Only trusted routers are allowed to call this hook.
        require(msg.sender == _trustedRouter, "CalculateDynamicFeeHook: Only trusted routers can call this hook");

        
    
    }




}