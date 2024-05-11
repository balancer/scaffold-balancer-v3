//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/**
 * @title Example Custom Pool Implementation Using Constant Price Invariant
 * @author BUIDL GUIDL
 * @notice This is an example Custom Pool Implementation, is not ready for production, and should not be used in production. It is simply an example for developers to reference when creating their own custom pool, custom pool factory, etc. with BalancerV3.
 */
contract ConstantPricePool is IBasePool, BalancerPoolToken {
    constructor(
        IVault vault,
        string memory name,
        string memory symbol
    ) BalancerPoolToken(vault, name, symbol) {}

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(
        SwapParams calldata params
    ) external pure returns (uint256 amountCalculatedScaled18) {
        amountCalculatedScaled18 = params.amountGivenScaled18;
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances
     * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(
        uint256[] memory balancesLiveScaled18
    ) public pure returns (uint256 invariant) {
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
                invariant *
                (invariantRatio)) -
            invariant;
    }

    /**
     * @notice Gets the tokens registered to a pool.
     * @dev Delegated to the Vault; added here as a convenience, mainly for off-chain processes.
     * @dev TODO - left blank for now, but for finished example w/ scaffoldBalancer we need to implement this correctly.
     * @return tokens List of tokens in the pool
     */
    function getPoolTokens() external view returns (IERC20[] memory tokens) {}
}
