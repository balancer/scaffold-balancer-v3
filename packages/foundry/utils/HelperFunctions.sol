// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { HelperConfig } from "./HelperConfig.sol";

contract HelperFunctions is HelperConfig {
    /**
     * @notice Approves the vault to spend tokens and then initializes the pool
     */
    function initializePool(
        address pool,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) internal {
        // Approve Permit2 to spend account tokens
        approveSpenderOnToken(address(permit2), tokens);
        // Approve Router to spend account tokens using Permit2
        approveSpenderOnPermit2(address(router), tokens);
        // Initialize pool with the tokens that have been permitted
        router.initialize(pool, tokens, exactAmountsIn, minBptAmountOut, wethIsEth, userData);
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param tokens Array of tokens to approve
     * @param spender Address of the spender
     */
    function approveSpenderOnToken(address spender, IERC20[] memory tokens) internal {
        uint256 maxAmount = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, maxAmount);
        }
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param tokens Array of tokens to approve
     * @param spender Address of the spender
     */
    function approveSpenderOnPermit2(address spender, IERC20[] memory tokens) internal {
        uint160 maxAmount = type(uint160).max;
        uint48 maxExpiration = type(uint48).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            permit2.approve(address(tokens[i]), spender, maxAmount, maxExpiration);
        }
    }
}
