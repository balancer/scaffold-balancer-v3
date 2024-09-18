//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { PoolSwapParams, Rounding } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Constant Product Pool
 * @notice This custom pool example is based on the Constant Product Pool from the Balancer v3 Docs
 * https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html
 */
contract ConstantProductPool is BalancerPoolToken, IBasePool {
    using FixedPoint for uint256;

    uint256 private constant _MIN_INVARIANT_RATIO = 70e16; // 70%
    uint256 private constant _MAX_INVARIANT_RATIO = 300e16; // 300%
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.00001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.10e18; // 10%

    constructor(IVault vault, string memory name, string memory symbol) BalancerPoolToken(vault, name, symbol) {}

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters (see above for struct definition)
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(PoolSwapParams calldata params) external pure returns (uint256 amountCalculatedScaled18) {
        uint256 poolBalancetokenOut = params.balancesScaled18[params.indexOut];
        uint256 poolBalancetokenIn = params.balancesScaled18[params.indexIn];
        uint256 amountTokenIn = params.amountGivenScaled18;

        amountCalculatedScaled18 = (poolBalancetokenOut * amountTokenIn) / (poolBalancetokenIn + amountTokenIn);
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances
     * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
     *
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding) public pure returns (uint256 invariant) {
        // scale the invariant to 1e18
        invariant = FixedPoint.ONE;
        invariant = invariant.mulDown(balancesLiveScaled18[0]).mulDown(balancesLiveScaled18[1]);
        invariant = Math.sqrt(invariant) * 1e9; // maintain the 1e18 scale
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
        uint256 newInvariant = computeInvariant(balancesLiveScaled18, Rounding.ROUND_DOWN).mulDown(invariantRatio);
        uint256 otherTokenIndex = tokenInIndex == 0 ? 1 : 0;
        uint256 poolBalanceOtherToken = balancesLiveScaled18[otherTokenIndex];

        newBalance = ((newInvariant * newInvariant) / poolBalanceOtherToken);
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
