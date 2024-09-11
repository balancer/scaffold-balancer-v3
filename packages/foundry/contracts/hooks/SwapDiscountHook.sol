// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    LiquidityManagement,
    RemoveLiquidityKind,
    AfterSwapParams,
    SwapKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { console } from "forge-std/console.sol";

contract SwapDiscountHook is BaseHooks {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    address private immutable _allowedFactory;
    address private immutable _trustedRouter;
    address public discountToken;

    uint64 public hookSwapDiscountPercentage;

    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        address _discountToken,
        uint64 _hookSwapDiscountPercentage
    ) BaseHooks(vault) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        discountToken = _discountToken;
        hookSwapDiscountPercentage = _hookSwapDiscountPercentage;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override returns (bool) {
        // NOTICE: In real hooks, make sure this function is properly implemented (e.g. check the factory, and check
        // that the given pool is from the factory). Returning true unconditionally allows any pool, with any
        // configuration, to use this hook.

        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.shouldCallAfterSwap = true;

        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 discountedAmount) {
        discountedAmount = params.amountCalculatedRaw;
        if (
            hookSwapDiscountPercentage > 0 &&
            address(params.tokenOut) == discountToken &&
            params.kind == SwapKind.EXACT_IN
        ) {
            discountedAmount = discountedAmount.mulDown(hookSwapDiscountPercentage);
            return (true, discountedAmount);
        }
        return (true, 0);
    }
}
