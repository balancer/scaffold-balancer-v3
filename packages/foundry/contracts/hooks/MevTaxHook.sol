// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { PoolSwapParams, TokenConfig, LiquidityManagement, HookFlags } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

contract MevTaxHook is BaseHooks, VaultGuard {
    using FixedPoint for uint256;

    address private immutable _factory;
    uint256 public immutable MEV_TAX_MULTIPLIER;

    constructor(IVault vault, address factory, uint256 mevTaxMultiplier) BaseHooks() VaultGuard(vault) {
        _factory = factory;
        MEV_TAX_MULTIPLIER = mevTaxMultiplier;
    }

    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override onlyVault returns (bool) {
        // Ensure:
        // * factory matches the one provided in the constructor
        // * pool is from the expected factory
        return (factory == _factory && IBasePoolFactory(factory).isPoolFromFactory(pool));
    }

    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        return hookFlags;
    }

    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata,
        address,
        uint256 staticSwapFeePercentage
    ) public view override returns (bool success, uint256 dynamicSwapFeePercentage) {

        // Default to static swap fee if there are gas price shenanigans going on
        // such as unexpected gas behavior from builders/sequencers or query functions
        // using placeholder values for `tx.gasprice` and/or `block.basefee`
        if (tx.gasprice < block.basefee) {
            return (true, staticSwapFeePercentage);
        }

        // Unchecked because of the check above
        uint256 priorityFee;
        unchecked {
            priorityFee = tx.gasprice - block.basefee;
        }

        // Calculate MEV tax based on priority fee
        uint256 mevTaxPercentage = MEV_TAX_MULTIPLIER.mulUp(priorityFee);

        uint256 feeMultiplier = FixedPoint.ONE + mevTaxPercentage;

        // Calculate swap fee as fn of static fee and fee multiplier
        uint256 swapFeeOut = staticSwapFeePercentage.mulUp(feeMultiplier);

        return (true, swapFeeOut);
    }
}