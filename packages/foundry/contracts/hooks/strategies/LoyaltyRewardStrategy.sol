// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import "./ILoyaltyRewardStrategy.sol";

/**
 * @notice Implements the discount and reward calculation logic for the LoyaltyHook.
 * @dev This contract calculates discounted fee percentages based on the user's LOYALTY token balance,
 * determines the mint amount for LOYALTY tokens considering action counts and decay factors, and computes exit fees.
 * It uses a tiered system for discounts and applies decay to reward calculations to incentivize user engagement.
 */
contract LoyaltyRewardStrategy is ILoyaltyRewardStrategy, Ownable {
    using FixedPoint for uint256;

    // Struct representing a loyalty tier with a threshold and corresponding discount percentage
    struct Tier {
        uint256 threshold; // Minimum loyalty token balance to qualify for this tier
        uint256 discount; // Discount percentage (18-decimal fixed-point) for this tier
    }

    Tier[] private _tiers; // Array storing all loyalty tiers
    uint256 private _decayPerAction; // Decay percentage applied per additional user action
    uint256 private _maxDecay; // Maximum total decay percentage allowed

    /**
     * @notice Emitted when the loyalty tiers are updated.
     * @dev This event is triggered whenever the contract owner updates the loyalty tiers, altering the thresholds
     *      and corresponding discount percentages.
     * @param thresholds An array of new LOYALTY token balance thresholds for each tier.
     * @param discounts An array of new discount percentages (in 18-decimal fixed-point format) corresponding to each tier.
     */
    event TiersUpdated(uint256[] thresholds, uint256[] discounts);

    /**
     * @notice Emitted when the decay parameters are updated.
     * @dev This event is emitted whenever the contract owner adjusts the decay factors that influence the
     *      loyalty rewards. The decay parameters control how the reward minting decreases based on user actions,
     *      preventing excessive reward accumulation from high activity.
     * @param decayPerAction The new decay percentage (in 18-decimal fixed-point format) applied per additional user action.
     *                       This value determines how much the mint amount decreases with each subsequent action.
     * @param maxDecay The new maximum total decay percentage (in 18-decimal fixed-point format) that can be applied.
     *                  This ensures that the decay factor does not exceed a certain limit, maintaining a floor for rewards.
     */
    event DecayParametersUpdated(uint256 decayPerAction, uint256 maxDecay);

    /**
     * @notice Constructor to initialize the LoyaltyRewardStrategy with tiers and decay parameters
     * @param thresholds Array of LOYALTY token balance thresholds for each tier
     * @param discounts Array of discount percentages corresponding to each tier
     * @param decayPerAction Decay percentage applied per additional action beyond the first
     * @param maxDecay Maximum total decay percentage that can be applied
     */
    constructor(
        uint256[] memory thresholds,
        uint256[] memory discounts,
        uint256 decayPerAction,
        uint256 maxDecay
    ) Ownable(msg.sender) {
        require(thresholds.length == discounts.length, "Thresholds and discounts length mismatch");
        require(_isSorted(thresholds), "Thresholds must be sorted in ascending order");

        // Initialize tiers based on provided thresholds and discounts
        for (uint256 i = 0; i < thresholds.length; i++) {
            _tiers.push(Tier({ threshold: thresholds[i], discount: discounts[i] }));
        }

        _decayPerAction = decayPerAction;
        _maxDecay = maxDecay;
    }

    // Fee Discount Methods

    /// @inheritdoc ILoyaltyRewardStrategy
    function calculateDiscountedFeePercentage(
        uint256 baseFeePercentage,
        uint256 loyaltyBalance
    ) public view override returns (uint256 discountedFeePercentage) {
        uint256 discountPercentage = 0;

        // Iterate through tiers to find the highest applicable discount
        for (uint256 i = 0; i < _tiers.length; i++) {
            if (loyaltyBalance >= _tiers[i].threshold) {
                discountPercentage = _tiers[i].discount;
            }
        }

        // Calculate the discount amount using fixed-point arithmetic
        uint256 discountAmount = baseFeePercentage.mulDown(discountPercentage);

        // Return the fee percentage after applying the discount
        return baseFeePercentage - discountAmount;
    }

    /// @inheritdoc ILoyaltyRewardStrategy
    function calculateExitFees(
        uint256[] memory baseAmounts,
        uint256 exitFeePercentage,
        uint256 loyaltyBalance
    ) external view override returns (uint256[] memory adjustedAmounts, uint256[] memory accruedFees) {
        uint256 discountedExitFeePercentage = calculateDiscountedFeePercentage(exitFeePercentage, loyaltyBalance);
        uint256 numTokens = baseAmounts.length;

        adjustedAmounts = new uint256[](numTokens);
        accruedFees = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 exitFee = baseAmounts[i].mulDown(discountedExitFeePercentage);
            accruedFees[i] = exitFee;
            adjustedAmounts[i] = baseAmounts[i] - exitFee;
        }
    }

    // Reward Calculation Methods

    /// @inheritdoc ILoyaltyRewardStrategy
    function calculateMintAmount(
        uint256 baseAmount,
        uint256 actionCount
    ) external view override returns (uint256 mintAmount) {
        uint256 totalDecay = _calculateDecayFactor(actionCount);
        uint256 mintPercentage = FixedPoint.ONE - totalDecay;
        return baseAmount.mulDown(mintPercentage);
    }

    /**
     * @notice Calculates the decay factor based on the number of user actions
     * @param actionCount The number of actions performed by the user
     * @return totalDecay The total decay factor to be applied
     */
    function _calculateDecayFactor(uint256 actionCount) internal view returns (uint256 totalDecay) {
        if (actionCount <= 1) return 0;

        // Calculate total decay based on the number of actions beyond the first
        totalDecay = _decayPerAction * (actionCount - 1);

        // Ensure that total decay does not exceed the maximum allowed decay
        if (totalDecay > _maxDecay) {
            totalDecay = _maxDecay;
        }
    }

    // Administrative Methods

    /**
     * @notice Updates the loyalty tiers with new thresholds and discounts
     * @dev Only callable by the contract owner
     * @param thresholds Array of new LOYALTY token balance thresholds for each tier
     * @param discounts Array of new discount percentages corresponding to each tier
     */
    function updateTiers(uint256[] memory thresholds, uint256[] memory discounts) external onlyOwner {
        require(thresholds.length == discounts.length, "Thresholds and discounts length mismatch");
        require(_isSorted(thresholds), "Thresholds must be sorted in ascending order");

        // Clear existing tiers
        delete _tiers;

        // Populate tiers with new thresholds and discounts
        for (uint256 i = 0; i < thresholds.length; i++) {
            _tiers.push(Tier({ threshold: thresholds[i], discount: discounts[i] }));
        }

        emit TiersUpdated(thresholds, discounts);
    }

    /**
     * @notice Updates the decay parameters for action tracking
     * @dev Only callable by the contract owner
     * @param decayPerAction New decay percentage applied per additional action beyond the first
     * @param maxDecay New maximum total decay percentage allowed
     */
    function updateDecayParameters(uint256 decayPerAction, uint256 maxDecay) external onlyOwner {
        _decayPerAction = decayPerAction;
        _maxDecay = maxDecay;

        emit DecayParametersUpdated(_decayPerAction, _maxDecay);
    }

    // Utility Methods

    /**
     * @dev Internal function to check if an array of thresholds is sorted in ascending order
     * @param thresholds The array of thresholds to check
     * @return isSorted Boolean indicating whether the array is sorted
     */
    function _isSorted(uint256[] memory thresholds) internal pure returns (bool isSorted) {
        for (uint256 i = 1; i < thresholds.length; i++) {
            if (thresholds[i] < thresholds[i - 1]) {
                return false;
            }
        }
        return true;
    }
}
