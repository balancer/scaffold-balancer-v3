// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { BalancerPoolToken } from "@balancer-labs/balancer-v3-monorepo/pkg/vault/contracts/BalancerPoolToken.sol";
import { IPoolLiquidity } from "@balancer-labs/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IPoolLiquidity.sol";
import { FixedPoint } from "@balancer-labs/balancer-v3-monorepo/pkg/solidity-utils/contracts/math/FixedPoint.sol";
import { Math } from "@balancer-labs/balancer-v3-monorepo/pkg/vault/contracts/BasePoolMath.sol";
import { IERC20 } from "@balancer-labs/balancer-v3-monorepo/pkg/interfaces/contracts/tokens/IERC20.sol";

contract SafeSwap is IBasePool, IPoolLiquidity, BalancerPoolToken {
    using FixedPoint for uint256;

    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 0;
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%
    uint256 private constant _DISCOUNT_PERCENTAGE = 10; // 10% discount

    address public discountToken; // Address of the token that provides a discount

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        address _discountToken // Address of the discount token to be passed in constructor
    ) BalancerPoolToken(vault, name, symbol) {
        discountToken = _discountToken;
    }

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(PoolSwapParams calldata params) external view returns (uint256 amountCalculatedScaled18) {
        uint256 swapFee = _MAX_SWAP_FEE_PERCENTAGE; // Default fee

        // Check if the user holds the discount token and apply the discount if applicable
        if (IERC20(discountToken).balanceOf(msg.sender) > 0) {
            swapFee = swapFee - ((swapFee * _DISCOUNT_PERCENTAGE) / 100); // Apply 10% discount
        }

        // Swap logic with discounted swap fee
        amountCalculatedScaled18 =
            (params.balancesScaled18[params.indexOut] * params.amountGivenScaled18) /
            (params.balancesScaled18[params.indexIn] + params.amountGivenScaled18);

        // Apply the swap fee (using the discounted or full fee)
        amountCalculatedScaled18 = amountCalculatedScaled18.mulDown(FixedPoint.ONE - swapFee);
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances
     * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18) public pure returns (uint256 invariant) {
        // expected to work with 2 tokens only
        invariant = FixedPoint.ONE;
        for (uint256 i = 0; i < balancesLiveScaled18.length; ++i) {
            invariant = invariant.mulDown(balancesLiveScaled18[i]);
        }
        // scale the invariant to 1e18
        invariant = Math.sqrt(invariant) * 1e9;
    }

    /**
     * @dev Computes the new balance of a token after an operation, given the invariant growth ratio and all other balances.
     * @param balancesLiveScaled18 Current live balances (adjusted for decimals, rates, etc.)
     * @param tokenInIndex The index of the token we're computing the balance for, in token registration order
     * @param invariantRatio The ratio of the new invariant (after an operation) to the old
     * @return newBalance The new balance of the selected token, after the operation
     */
    function computeBalance(
        uint256[] memory balancesLiveScaled18,
        uint256 tokenInIndex,
        uint256 invariantRatio
    ) external pure returns (uint256 newBalance) {
        uint256 otherTokenIndex = tokenInIndex == 0 ? 1 : 0;

        uint256 newInvariant = computeInvariant(balancesLiveScaled18).mulDown(invariantRatio);

        newBalance = (newInvariant * newInvariant) / balancesLiveScaled18[otherTokenIndex];
    }

    /// @return minimumSwapFeePercentage The minimum swap fee percentage for a pool
    function getMinimumSwapFeePercentage() external pure returns (uint256) {
        return _MIN_SWAP_FEE_PERCENTAGE;
    }

    /// @return maximumSwapFeePercentage The maximum swap fee percentage for a pool
    function getMaximumSwapFeePercentage() external pure returns (uint256) {
        return _MAX_SWAP_FEE_PERCENTAGE;
    }

    /**
     * @notice Custom add liquidity hook.
     * @param router The address that initiated the operation
     * @param maxAmountsInScaled18 Maximum input amounts, sorted in token registration order
     * @param minBptAmountOut Minimum amount of output pool tokens
     * @param balancesScaled18 Current pool balances, sorted in token registration order
     * @param userData Arbitrary data sent with the request
     * @return amountsInScaled18 Input token amounts, sorted in token registration order
     * @return bptAmountOut Calculated pool token amount to receive
     * @return swapFeeAmountsScaled18 The amount of swap fees charged for each token
     * @return returnData Arbitrary data with an encoded response from the pool
     */
    function onAddLiquidityCustom(
        address router,
        uint256[] memory maxAmountsInScaled18,
        uint256 minBptAmountOut,
        uint256[] memory balancesScaled18,
        bytes memory userData
    )
        external
        override
        returns (
            uint256[] memory amountsInScaled18,
            uint256 bptAmountOut,
            uint256[] memory swapFeeAmountsScaled18,
            bytes memory returnData
        )
    {
        // Custom logic for adding liquidity
        uint256 invariantBefore = computeInvariant(balancesScaled18);
        amountsInScaled18 = maxAmountsInScaled18; // You can modify this based on custom liquidity logic
        swapFeeAmountsScaled18 = new uint256[](balancesScaled18.length); // Placeholder for swap fees

        // Update balances after adding liquidity
        for (uint256 i = 0; i < balancesScaled18.length; ++i) {
            balancesScaled18[i] += amountsInScaled18[i];
        }

        uint256 invariantAfter = computeInvariant(balancesScaled18);
        bptAmountOut = invariantAfter - invariantBefore; // Example calculation

        returnData = userData; // Custom return data
    }

    /**
     * @notice Custom remove liquidity hook.
     * @param router The address that initiated the operation
     * @param maxBptAmountIn Maximum amount of input pool tokens
     * @param minAmountsOutScaled18 Minimum output amounts, sorted in token registration order
     * @param balancesScaled18 Current pool balances, sorted in token registration order
     * @param userData Arbitrary data sent with the request
     * @return bptAmountIn Calculated pool token amount to burn
     * @return amountsOutScaled18 Amount of tokens to receive, sorted in token registration order
     * @return swapFeeAmountsScaled18 The amount of swap fees charged for each token
     * @return returnData Arbitrary data with an encoded response from the pool
     */
    function onRemoveLiquidityCustom(
        address router,
        uint256 maxBptAmountIn,
        uint256[] memory minAmountsOutScaled18,
        uint256[] memory balancesScaled18,
        bytes memory userData
    )
        external
        override
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOutScaled18,
            uint256[] memory swapFeeAmountsScaled18,
            bytes memory returnData
        )
    {
        // Custom logic for removing liquidity
        uint256 invariantBefore = computeInvariant(balancesScaled18);
        amountsOutScaled18 = minAmountsOutScaled18; // Modify this based on custom logic
        swapFeeAmountsScaled18 = new uint256[](balancesScaled18.length); // Placeholder for swap fees

        // Update balances after removing liquidity
        for (uint256 i = 0; i < balancesScaled18.length; ++i) {
            balancesScaled18[i] -= amountsOutScaled18[i];
        }

        uint256 invariantAfter = computeInvariant(balancesScaled18);
        bptAmountIn = invariantBefore - invariantAfter; // Example calculation

        returnData = userData; // Custom return data
    }
}
