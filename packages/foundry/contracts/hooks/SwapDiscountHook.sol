// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol"; // Importing IRouterCommon
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
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

contract SwapDiscountHook is BaseHooks {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    address private immutable _allowedFactory;
    address private immutable _trustedRouter;
    address public discountToken; // The token to check for discount eligibility (BAL)
    uint256 public requiredBalance; // The balance of BAL required for discount eligibility
    uint64 public hookSwapDiscountPercentage; // The discount percentage to apply

    // modifier onlyVault() {
    //     require(msg.sender == address(IVault), "Caller is not the vault");
    //     _;
    // }

    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        address _discountToken,
        uint64 _hookSwapDiscountPercentage,
        uint256 _requiredBalance // Setting the required balance for discount eligibility
    ) BaseHooks() {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        discountToken = _discountToken;
        hookSwapDiscountPercentage = _hookSwapDiscountPercentage;
        requiredBalance = _requiredBalance; // Store the required balance
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override returns (bool) {
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallAfterSwap = true;
        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public view override returns (bool success, uint256 discountedAmount) {
        discountedAmount = params.amountCalculatedRaw;

        // Check if the user holds enough BAL tokens for a discount
        if (
            hookSwapDiscountPercentage > 0 &&
            address(params.tokenOut) == discountToken &&
            params.kind == SwapKind.EXACT_IN
        ) {
            // Get the sender's balance of the discount token
            uint256 userBalance = IERC20(discountToken).balanceOf(IRouterCommon(params.router).getSender());

            // Apply discount if user holds enough BAL tokens
            if (userBalance >= requiredBalance) {
                discountedAmount = discountedAmount.mulDown(hookSwapDiscountPercentage);
                return (true, discountedAmount);
            }
        }
        return (true, discountedAmount); // No discount applied, return original amount
    }
}
