// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @notice Interface defining the discount and reward calculation functions for the LoyaltyHook.
 * @dev This interface specifies the methods required for calculating fees based on LOYALTY token balance,
 * adjusting mint amounts for LOYALTY rewards considering action counts and decay factors, and computing exit fees.
 * Implementing contracts should provide the logic for these calculations to be used by the LoyaltyHook.
 */
interface ILoyaltyRewardStrategy {
    /**
     * @notice Calculates the discounted fee percentage based on the base fee percentage and user's LOYALTY balance.
     * @param baseFeePercentage The original fee percentage before discount.
     * @param loyaltyBalance The user's current LOYALTY token balance.
     * @return discountedFeePercentage The fee percentage after applying the appropriate discount.
     */
    function calculateDiscountedFeePercentage(
        uint256 baseFeePercentage,
        uint256 loyaltyBalance
    ) external view returns (uint256 discountedFeePercentage);

    /**
     * @notice Calculates the accrued fees based on the exit fee percentage and user's LOYALTY balance.
     * @param baseAmounts The raw amounts of tokens the user will receive from the removal.
     * @param exitFeePercentage The base exit fee percentage before discount.
     * @param loyaltyBalance The user's current LOYALTY token balance.
     * @return adjustedAmounts The amounts after applying exit fees.
     * @return accruedFees The fees accrued from the liquidity removal.
     */
    function calculateExitFees(
        uint256[] memory baseAmounts,
        uint256 exitFeePercentage,
        uint256 loyaltyBalance
    ) external view returns (uint256[] memory adjustedAmounts, uint256[] memory accruedFees);

    /**
     * @notice Calculates the mint amount for LOYALTY tokens based on base amount and action count.
     * @param baseAmount The amount used as a base for LOYALTY mint calculation.
     * @param actionCount The user's action count.
     * @return mintAmount The calculated mint amount after applying decay.
     */
    function calculateMintAmount(uint256 baseAmount, uint256 actionCount) external view returns (uint256 mintAmount);
}
