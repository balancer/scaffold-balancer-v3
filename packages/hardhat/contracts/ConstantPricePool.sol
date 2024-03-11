//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IVault.sol";
import "./interfaces/IBasePool.sol";
import "./vault/BalancerPoolToken.sol";

contract ConstantPricePool is IBasePool, BalancerPoolToken {
	constructor(
		IVault vault,
		string name,
		string symbol
	) BalancerPoolToken(vault, name, symbol) {}

	/**
	 * @notice Execute a swap in the pool.
	 * @param params Swap parameters
	 * @return amountCalculatedScaled18 Calculated amount for the swap
	 */
	function onSwap(
		SwapParams calldata params
	) external returns (uint256 amountCalculatedScaled18) {
		amountCalculatedScaled18 = request.amountGivenScaled18;
	}

	/**
	 * @notice Computes and returns the pool's invariant.
	 * @dev This function computes the invariant based on current balances
	 * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
	 * @return invariant The calculated invariant of the pool, represented as a uint256
	 */
	function computeInvariant(
		uint256[] memory balancesLiveScaled18
	) external view returns (uint256 invariant) {
		invariant = balancesLiveScaled18[0] + balancesLiveScaled18[1];
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
		uint256 invariant = computeInvariant(balancesLiveScaled18);

		newBalance =
			(balancesLiveScaled18[tokenInIndex] +
				invariant.mulDown(invariantRatio)) -
			invariant;
	}
}
