// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

// External Libraries
import "forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Balancer Contracts
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

// Internal Imports
import { LoyaltyToken } from "../mocks/LoyaltyToken.sol";

contract LoyaltyHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    address private immutable _trustedRouter;
    LoyaltyToken private immutable _loyaltyToken;

    // Percentages are represented as 18-decimal FP numbers, which have a maximum value of FixedPoint.ONE (100%),
    // so 60 bits are sufficient.

    // normal fee when no $LOYALTY, decreased with when $LOYALTY
    uint256 public hookSwapFeePercentage;

    // exit fee when no $LOYALTY, no exit fee when $LOYALTY
    uint256 public exitFeePercentage;

    // Maximum exit fee of 10%
    uint256 public constant MAX_EXIT_FEE_PERCENTAGE = 10 * 1e16;

    // Token amount thresholds
    uint256 public constant TIER1_THRESHOLD = 100 * 1e18; // 100 tokens
    uint256 public constant TIER2_THRESHOLD = 500 * 1e18; // 500 tokens
    uint256 public constant TIER3_THRESHOLD = 1000 * 1e18; // 1000 tokens

    // Discount percentages (18 decimal fixed-point representation)
    uint256 public constant TIER1_DISCOUNT = 50 * 1e16; // 50% discount
    uint256 public constant TIER2_DISCOUNT = 80 * 1e16; // 80% discount
    uint256 public constant TIER3_DISCOUNT = 90 * 1e16; // 90% discount

    // Mapping to track the number of actions per user
    mapping(address => uint256) public userActionCount;

    // Mapping to track the action reset per user
    mapping(address => uint256) public lastActionReset;

    // Reset decay after set interval
    uint256 public resetInterval = 30 days;

    uint256 public constant DECAY_PER_ACTION = 10 * 1e16; // 10% decay, represented as fixed point
    uint256 public constant MAX_DECAY = 90 * 1e16; // 90% max decay, represented as fixed point

    // Events
    event DiscountTierChanged(address indexed user, uint256 newTier);
    event AddLiquidityActionTracked(address indexed user, uint256 actionCount, uint256 mintAmount);
    event LoyaltyHookRegistered(address indexed hooksContract, address indexed pool);
    event HookFeeCharged(address indexed hooksContract, IERC20 indexed token, uint256 feeAmount);
    event HookSwapFeePercentageChanged(address indexed hooksContract, uint256 hookFeePercentage);
    event ExitFeeCharged(address indexed pool, IERC20 indexed token, uint256 feeAmount);
    event ExitFeePercentageChanged(address indexed hookContract, uint256 exitFeePercentage);
    event SwapActionTracked(address indexed user, uint256 actionCount, uint256 mintAmount);
    event ResetIntervalChanged(uint256 oldInterval, uint256 newInterval);

    error PoolDoesNotSupportDonation();
    error InvalidExitFeePercentage();

    /**
     * @notice Constructor for LoyaltyHook
     * @param vault The address of the Balancer Vault
     * @param trustedRouter The address of the trusted router
     * @param loyaltyToken The address of the loyalty token
     */
    constructor(IVault vault, address trustedRouter, address loyaltyToken) VaultGuard(vault) Ownable(msg.sender) {
        _loyaltyToken = LoyaltyToken(loyaltyToken);
        _trustedRouter = trustedRouter;
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
        // Calculate the discounted swap fee based on the user's loyalty balabcer
        dynamicSwapFeePercentage = calculateDiscountedFee(hookSwapFeePercentage, user);

        return (true, dynamicSwapFeePercentage);
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        // If the router is not trusted, no loyalty tokens are minted
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
        uint256 adjustedMintAmount = _calculateAdjustedMintAmount(user, params.amountCalculatedRaw);
        // Mint loyalty tokens to the user based on the adjusted amount
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
        // If the router is not trusted, no loyalty tokens are minted
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
        uint256 adjustedMintAmount = _calculateAdjustedMintAmount(user, bptAmountOut);
        // Mint loyalty tokens to the user based on the adjusted amount
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

        // Check if an exit fee should be applied based on the user's LOYALTY balance
        if (exitFeePercentage > 0) {
            uint256[] memory accruedFees;
            // Calculate the exit fees and adjust the amounts out accordingly
            (hookAdjustedAmountsOutRaw, accruedFees) = _calculateExitFees(pool, user, amountsOutRaw);

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
     * @notice Calculates the adjusted mint amount based on the swap token (onAfterSwap) or BPT amount (onAfterAddLiquidity) and decay factor
     * @param user The address of the user
     * @param inputAmount The amount of BPT out or swapped token as an input for LOYALTY mint calculation
     * @return mintAmount The adjusted mint amount
     */
    function _calculateAdjustedMintAmount(address user, uint256 inputAmount) internal view returns (uint256) {
        uint256 actionCount = userActionCount[user];

        // Initialize total decay to zero
        uint256 totalDecay = 0;
        if (actionCount > 1) {
            // Calculate total decay based on the number of actions performed
            totalDecay = DECAY_PER_ACTION * (actionCount - 1);
            // Ensure that the total decay does not exceed the maximum allowed decay
            if (totalDecay > MAX_DECAY) {
                totalDecay = MAX_DECAY;
            }
        }

        // Determine the mint percentage after applying the total decay
        uint256 mintPercentage = FixedPoint.ONE - totalDecay; // FixedPoint.ONE is 1e18

        // Calculate the final mint amount by applying the mint percentage to the input amount
        return (inputAmount * mintPercentage) / FixedPoint.ONE;
    }

    /**
     * @notice Calculates the discounted fee based on the user's loyalty balance
     * @param originalFee The original fee amount
     * @param user The address of the user
     * @return discountedFee The discounted fee amount
     */
    function calculateDiscountedFee(uint256 originalFee, address user) public view returns (uint256 discountedFee) {
        // Retrieve the user's LOYALTY token balance
        uint256 loyaltyBalance = _loyaltyToken.balanceOf(user);

        // Determine the discount percentage based on the user's LOYALTY tier
        uint256 discountPercentage;
        if (loyaltyBalance >= TIER3_THRESHOLD) {
            discountPercentage = TIER3_DISCOUNT;
        } else if (loyaltyBalance >= TIER2_THRESHOLD) {
            discountPercentage = TIER2_DISCOUNT;
        } else if (loyaltyBalance >= TIER1_THRESHOLD) {
            discountPercentage = TIER1_DISCOUNT;
        } else {
            // If the user does not meet any tier threshold, return the original fee
            return originalFee; // No discount
        }

        // Calculate the discount amount by applying the discount percentage to the original fee
        uint256 discountAmount = originalFee.mulDown(discountPercentage);
        // Subtract the discount amount from the original fee to get the discounted fee
        return originalFee - discountAmount;
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
     * @notice Calculates exit fees when a user removes liquidity from a pool.
     * @param pool The address of the pool from which liquidity is being removed.
     * @param user The address of the user removing liquidity.
     * @param amountsOutRaw The raw amounts of tokens the user will receive from the removal.
     * @return hookAdjustedAmountsOutRaw The amounts after applying exit fees.
     * @return accruedFees The fees accrued from the exit.
     */
    function _calculateExitFees(
        address pool,
        address user,
        uint256[] memory amountsOutRaw
    ) internal returns (uint256[] memory hookAdjustedAmountsOutRaw, uint256[] memory accruedFees) {
        // Calculate the discounted exit fee percentage based on the user's loyalty status
        uint256 discountedExitFeePercentage = calculateDiscountedFee(exitFeePercentage, user);
        // Retrieve the tokens associated with the pool
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256 numTokens = amountsOutRaw.length;

        // Initialize arrays to store the adjusted amounts out and accrued fees for each token
        accruedFees = new uint256[](numTokens);
        hookAdjustedAmountsOutRaw = new uint256[](numTokens);

        // Iterate over each token to calculate and apply exit fees
        for (uint256 i = 0; i < numTokens; i++) {
            // Calculate the exit fee for the current token
            uint256 exitFee = amountsOutRaw[i].mulDown(discountedExitFeePercentage);
            accruedFees[i] = exitFee;
            // Deduct the exit fee from the raw amount out to get the adjusted amount out
            hookAdjustedAmountsOutRaw[i] = amountsOutRaw[i] - exitFee;

            // Emit an event indicating that an exit fee has been charged for the current token
            emit ExitFeeCharged(pool, tokens[i], exitFee);
        }
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
     * @param hookFeePercentage The new hook swap fee percentage to set.
     * @dev Only the contract owner can call this function.
     *      Emits a HookSwapFeePercentageChanged event upon successful update.
     */
    function setHookSwapFeePercentage(uint256 hookFeePercentage) external onlyOwner {
        // Update the hook swap fee percentage
        hookSwapFeePercentage = hookFeePercentage;
        // Emit an event indicating that the hook swap fee percentage has been changed
        emit HookSwapFeePercentageChanged(address(this), hookFeePercentage);
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
