// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import {
    AddLiquidityParams,
    HookFlags,
    LiquidityManagement,
    AddLiquidityKind,
    TokenConfig,
    PoolSwapParams,
    RemoveLiquidityKind,
    AfterSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { LoyaltyToken } from "../mocks/LoyaltyToken.sol";
import { ILoyaltyRewardStrategy } from "./strategies/ILoyaltyRewardStrategy.sol";

/**
 * @title LoyaltyHook
 * @notice Hook for managing loyalty-based fee discounts and rewards within Balancer pools.
 * @dev Implements fee adjustments, reward minting based on user actions, and exit fee processing.
 */
contract LoyaltyHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    address private immutable _trustedRouter;
    LoyaltyToken private immutable _loyaltyToken;
    ILoyaltyRewardStrategy private _loyaltyRewardStrategy;

    // Percentages are represented as 18-decimal FP numbers, which have a maximum value of FixedPoint.ONE (100%),
    // so 60 bits are sufficient.

    // normal fee when no LOYALTY, decreased with when LOYALTY
    uint256 public hookSwapFeePercentage;

    // exit fee when no LOYALTY, no exit fee when LOYALTY
    uint256 public exitFeePercentage;

    // Maximum exit fee of 10%
    uint256 public constant MAX_EXIT_FEE_PERCENTAGE = 10 * 1e16;

    // Mapping to track the number of actions per user
    mapping(address => uint256) public userActionCount;

    // Mapping to track the action reset per user
    mapping(address => uint256) public lastActionReset;

    // Reset decay after set interval
    uint256 public resetInterval = 30 days;

    // Events
    /**
     * @notice Emitted when a user's discount tier is updated.
     * @param user The address of the user.
     * @param newTier The new tier level assigned to the user.
     */
    event DiscountTierChanged(address indexed user, uint256 newTier);

    /**
     * @notice Emitted when a user performs an add liquidity action.
     * @param user The address of the user.
     * @param actionCount The total number of actions performed by the user.
     * @param mintAmount The amount of LOYALTY tokens minted for the user.
     */
    event AddLiquidityActionTracked(address indexed user, uint256 actionCount, uint256 mintAmount);

    /**
     * @notice Emitted when the LoyaltyHook is registered with a pool.
     * @param hooksContract The address of the LoyaltyHook contract.
     * @param pool The address of the pool being registered.
     */
    event LoyaltyHookRegistered(address indexed hooksContract, address indexed pool);

    /**
     * @notice Emitted when a fee is charged by the hook.
     * @param hooksContract The address of the LoyaltyHook contract.
     * @param token The token for which the fee is charged.
     * @param feeAmount The amount of fee charged.
     */
    event HookFeeCharged(address indexed hooksContract, IERC20 indexed token, uint256 feeAmount);

    /**
     * @notice Emitted when the swap fee percentage is changed.
     * @param hooksContract The address of the LoyaltyHook contract.
     * @param hookFeePercentage The new swap fee percentage.
     */
    event HookSwapFeePercentageChanged(address indexed hooksContract, uint256 hookFeePercentage);

    /**
     * @notice Emitted when an exit fee is charged during liquidity removal.
     * @param pool The address of the pool from which liquidity is removed.
     * @param token The token for which the exit fee is charged.
     * @param feeAmount The amount of exit fee charged.
     */
    event ExitFeeCharged(address indexed pool, IERC20 indexed token, uint256 feeAmount);

    /**
     * @notice Emitted when the exit fee percentage is updated.
     * @param hookContract The address of the LoyaltyHook contract.
     * @param exitFeePercentage The new exit fee percentage.
     */
    event ExitFeePercentageChanged(address indexed hookContract, uint256 exitFeePercentage);

    /**
     * @notice Emitted when a user performs a swap action.
     * @param user The address of the user.
     * @param actionCount The total number of actions performed by the user.
     * @param mintAmount The amount of LOYALTY tokens minted for the user.
     */
    event SwapActionTracked(address indexed user, uint256 actionCount, uint256 mintAmount);

    /**
     * @notice Emitted when the reset interval is changed.
     * @param oldInterval The previous reset interval duration.
     * @param newInterval The new reset interval duration.
     */
    event ResetIntervalChanged(uint256 oldInterval, uint256 newInterval);

    // Custom Errors
    error PoolDoesNotSupportDonation();
    error InvalidExitFeePercentage();

    /**
     * @notice Constructor for LoyaltyHook.
     * @param vault The address of the Balancer Vault.
     * @param trustedRouter The address of the trusted router.
     * @param loyaltyToken The address of the LoyaltyToken.
     * @param loyaltyRewardStrategy_ The address of the LoyaltyRewardStrategy contract.
     */
    constructor(
        IVault vault,
        address trustedRouter,
        address loyaltyToken,
        address loyaltyRewardStrategy_
    ) VaultGuard(vault) Ownable(msg.sender) {
        _loyaltyToken = LoyaltyToken(loyaltyToken);
        _trustedRouter = trustedRouter;
        _loyaltyRewardStrategy = ILoyaltyRewardStrategy(loyaltyRewardStrategy_);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallAfterSwap = true;
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallAfterAddLiquidity = true;
        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        // Ensure that the pool supports donation
        if (liquidityManagement.enableDonation == false) {
            revert PoolDoesNotSupportDonation();
        }
        // Emit an event indicating that the LoyaltyHook has been registered with the pool
        emit LoyaltyHookRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address, // pool address (not needed here)
        uint256
    ) public view override onlyVault returns (bool success, uint256 dynamicSwapFeePercentage) {
        // If the router is not trusted, do not apply any discount and return the standard swap fee
        if (params.router != _trustedRouter) {
            return (true, hookSwapFeePercentage);
        }

        // Retrieve the user initiating the swap from the trusted router
        address user = IRouterCommon(params.router).getSender();
        // Calculate the discounted swap fee based on the user's LOYALTY balance
        dynamicSwapFeePercentage = _loyaltyRewardStrategy.calculateDiscountedFeePercentage(
            hookSwapFeePercentage,
            _loyaltyToken.balanceOf(user)
        );

        return (true, dynamicSwapFeePercentage);
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        // If the router is not trusted, no LOYALTY tokens are minted
        if (params.router != _trustedRouter) {
            return (true, params.amountCalculatedRaw);
        }

        // Retrieve the user initiating the swap from the trusted router
        address user = IRouterCommon(params.router).getSender();

        // Check for the zero address**
        if (user == address(0)) {
            // Skip minting and other actions since the user address is invalid
            return (true, params.amountCalculatedRaw);
        }

        // Reset the user's action count if the reset interval has passed
        _resetActionCountIfNeeded(user);

        // Increment the user's action count
        userActionCount[user]++;

        // Calculate the adjusted mint amount based on the user's current action count and apply decay
        uint256 adjustedMintAmount = _loyaltyRewardStrategy.calculateMintAmount(
            params.amountCalculatedRaw,
            userActionCount[user]
        );
        // Mint LOYALTY tokens to the user based on the adjusted amount
        _loyaltyToken.mint(user, adjustedMintAmount);

        // Emit an event tracking the swap action
        emit SwapActionTracked(user, userActionCount[user], adjustedMintAmount);

        return (true, params.amountCalculatedRaw);
    }

    /// @inheritdoc IHooks
    function onAfterAddLiquidity(
        address router,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256 bptAmountOut,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool success, uint256[] memory adjustedAmountsInRaw) {
        // If the router is not trusted, no LOYALTY tokens are minted
        if (router != _trustedRouter) {
            return (true, amountsInRaw);
        }

        // Retrieve the user initiating the add liquidity from the trusted router
        address user = IRouterCommon(router).getSender();
        // Add a check for the zero address**
        if (user == address(0)) {
            // Skip minting and other actions since the user address is invalid
            return (true, amountsInRaw);
        }

        // Reset the user's action count if the reset interval has passed
        _resetActionCountIfNeeded(user);

        // Increment the user's action count
        userActionCount[user]++;

        // Calculate the adjusted mint amount based on the BPT amount received and apply decay
        uint256 adjustedMintAmount = _loyaltyRewardStrategy.calculateMintAmount(bptAmountOut, userActionCount[user]);
        // Mint LOYALTY tokens to the user based on the adjusted amount
        _loyaltyToken.mint(user, adjustedMintAmount);

        // Emit an event tracking the add liquidity action
        emit AddLiquidityActionTracked(user, userActionCount[user], adjustedMintAmount);

        return (true, amountsInRaw);
    }

    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind kind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public override returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw) {
        // Only support proportional liquidity removals
        if (kind != RemoveLiquidityKind.PROPORTIONAL) {
            return (false, amountsOutRaw);
        }

        // Retrieve the user initiating the liquidity removal from the trusted router
        address user = IRouterCommon(router).getSender();

        // Check if an exit fee should be applied
        if (exitFeePercentage > 0) {
            uint256[] memory accruedFees;
            // Calculate the exit fees and adjust the amounts out accordingly
            (hookAdjustedAmountsOutRaw, accruedFees) = _loyaltyRewardStrategy.calculateExitFees(
                amountsOutRaw,
                exitFeePercentage,
                _loyaltyToken.balanceOf(user)
            );

            // Retrieve the tokens associated with the pool
            IERC20[] memory tokens = _vault.getPoolTokens(pool);

            // Emit events for each token
            for (uint256 i = 0; i < tokens.length; i++) {
                emit ExitFeeCharged(pool, tokens[i], accruedFees[i]);
            }

            // Donate the accrued fees back to the pool as liquidity
            _vault.addLiquidity(
                AddLiquidityParams({
                    pool: pool,
                    to: msg.sender,
                    maxAmountsIn: accruedFees,
                    minBptAmountOut: 0,
                    kind: AddLiquidityKind.DONATION,
                    userData: bytes("")
                })
            );
        } else {
            // If no exit fee is applicable, return the raw amounts out
            hookAdjustedAmountsOutRaw = amountsOutRaw;
        }

        return (true, hookAdjustedAmountsOutRaw);
    }

    /**
     * @notice Resets the action count for a user if the reset interval has elapsed since the last reset.
     * @param user The address of the user.
     */
    function _resetActionCountIfNeeded(address user) internal {
        // Check if the current time has passed the last reset time plus the reset interval
        if (block.timestamp >= lastActionReset[user] + resetInterval) {
            // Reset the user's action count
            userActionCount[user] = 0;
            // Update the last reset timestamp to the current time
            lastActionReset[user] = block.timestamp;
        }
    }

    /**
     * @notice Sets a new LoyaltyRewardStrategy contract.
     * @param newLoyaltyRewardStrategy The address of the new LoyaltyRewardStrategy contract.
     * @dev Only the contract owner can call this function.
     */
    function setLoyaltyRewardStrategy(address newLoyaltyRewardStrategy) external onlyOwner {
        _loyaltyRewardStrategy = ILoyaltyRewardStrategy(newLoyaltyRewardStrategy);
    }

    /**
     * @notice Sets a new exit fee percentage.
     * @param newExitFeePercentage The new exit fee percentage to set.
     * @dev Only the contract owner can call this function.
     *      The new exit fee percentage must not exceed the maximum allowed limit.
     *      Emits an ExitFeePercentageChanged event upon successful update.
     */
    function setExitFeePercentage(uint64 newExitFeePercentage) external onlyOwner {
        // Ensure the new exit fee percentage does not exceed the maximum allowed limit
        if (newExitFeePercentage > MAX_EXIT_FEE_PERCENTAGE) {
            revert InvalidExitFeePercentage();
        }
        // Update the exit fee percentage
        exitFeePercentage = newExitFeePercentage;
        // Emit an event indicating that the exit fee percentage has been changed
        emit ExitFeePercentageChanged(address(this), newExitFeePercentage);
    }

    /**
     * @notice Sets a new hook swap fee percentage.
     * @param newHookFeePercentage The new hook swap fee percentage to set.
     * @dev Only the contract owner can call this function.
     *      Emits a HookSwapFeePercentageChanged event upon successful update.
     */
    function setHookSwapFeePercentage(uint256 newHookFeePercentage) external onlyOwner {
        // Update the hook swap fee percentage
        hookSwapFeePercentage = newHookFeePercentage;
        // Emit an event indicating that the hook swap fee percentage has been changed
        emit HookSwapFeePercentageChanged(address(this), hookSwapFeePercentage);
    }

    /**
     * @notice Sets a new reset interval for action count decay.
     * @param newResetInterval The new reset interval in seconds.
     * @dev Only the contract owner can call this function.
     *      This interval determines how frequently a user's action count is reset.
     *      Emits a ResetIntervalChanged event upon successful update.
     */
    function setResetInterval(uint256 newResetInterval) external onlyOwner {
        // Store the old reset interval for the event
        uint256 oldInterval = resetInterval;
        // Update the reset interval for action count decay
        resetInterval = newResetInterval;
        // Emit an event indicating that the reset interval has been changed
        emit ResetIntervalChanged(oldInterval, newResetInterval);
    }
}
