//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { PoolSwapParams, Rounding } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/**
 * @title Constant Sum Pool
 * @notice This custom pool example is based on the Constant Sum Pool from the Balancer v3 Docs
 * https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html
 */
contract ConstantSumPool is IBasePool, BalancerPoolToken {
    uint256 private constant _MIN_INVARIANT_RATIO = 70e16; // 70%
    uint256 private constant _MAX_INVARIANT_RATIO = 300e16; // 300%
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 0.001e18; // 0.001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.10e18; // 10%

    constructor(IVault vault, string memory name, string memory symbol) BalancerPoolToken(vault, name, symbol) {}

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(PoolSwapParams calldata params) external pure returns (uint256 amountCalculatedScaled18) {
        amountCalculatedScaled18 = params.amountGivenScaled18;
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances
     * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding) public pure returns (uint256 invariant) {
        invariant = balancesLiveScaled18[0] + balancesLiveScaled18[1];
    }

    /**
     * @dev Computes the new balance of a token after an operation, given the invariant growth ratio and all other balances
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
        uint256 invariant = computeInvariant(balancesLiveScaled18, Rounding.ROUND_DOWN);

        newBalance = (balancesLiveScaled18[tokenInIndex] + invariant * (invariantRatio)) - invariant;
    }

    // Invariant shrink limit: non-proportional remove cannot cause the invariant to decrease by less than this ratio.
    /// @return minimumInvariantRatio The minimum invariant ratio for a pool during unbalanced remove liquidity
    function getMinimumInvariantRatio() external pure returns (uint256) {
        return _MIN_INVARIANT_RATIO;
    }

    // Invariant growth limit: non-proportional add cannot cause the invariant to increase by more than this ratio.
    /// @return maximumInvariantRatio The maximum invariant ratio for a pool during unbalanced add liquidity
    function getMaximumInvariantRatio() external pure returns (uint256) {
        return _MAX_INVARIANT_RATIO;
    }

    /// @return minimumSwapFeePercentage The minimum swap fee percentage for a pool
    function getMinimumSwapFeePercentage() external pure returns (uint256) {
        return _MIN_SWAP_FEE_PERCENTAGE;
    }

    /// @return maximumSwapFeePercentage The maximum swap fee percentage for a pool
    function getMaximumSwapFeePercentage() external pure returns (uint256) {
        return _MAX_SWAP_FEE_PERCENTAGE;
    }
}
