//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { IBasePool, ISwapFeePercentageBounds } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Exponential Product Pool
 * @notice If pool is out of balance, much more punishing than constant product pools!
 */
contract ExponentialProductPool is IBasePool, BalancerPoolToken {
    using FixedPoint for uint256;

    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 0;
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%

    constructor(IVault vault, string memory name, string memory symbol) BalancerPoolToken(vault, name, symbol) {}

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(PoolSwapParams calldata params) external pure returns (uint256 amountCalculatedScaled18) {
        uint256 poolBalanceTokenOut = params.balancesScaled18[params.indexOut];
        uint256 poolBalanceTokenIn = params.balancesScaled18[params.indexIn];
        uint256 amountTokenIn = params.amountGivenScaled18;

        // How to make swaps in unbalanced pools more punishing than normal constant product AMM?
        amountCalculatedScaled18 = (poolBalanceTokenOut * amountTokenIn) / ((poolBalanceTokenIn + amountTokenIn));
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances
     * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18) public pure returns (uint256 invariant) {
        // expected to work with 2 tokens only
        invariant = FixedPoint.TWO; // double the invariant results in getting more BPT minted per token added
        for (uint256 i = 0; i < balancesLiveScaled18.length; ++i) {
            invariant = invariant.mulDown(balancesLiveScaled18[i]);
        }
        // scale the invariant to 1e18
        invariant = Math.sqrt(invariant) * 1e9;
    }

    /**
     * @dev Computes the new balance of a token after an operation, given the invariant growth ratio and all other
     * balances.
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

        uint256 otherTokenBalance = balancesLiveScaled18[otherTokenIndex];

        newBalance = ((newInvariant * newInvariant) / otherTokenBalance);
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
