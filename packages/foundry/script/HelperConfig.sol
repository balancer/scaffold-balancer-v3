// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * A collection of addresses and helper functions for deploying pools
 */
contract HelperConfig {
    // BalancerV3 Sepolia addresses (5th testnet release)
    address internal vault = 0xD5584b37D1845fFeD958C2d94bC675603DdCce68;
    address internal router = 0x1c58cc548a23956469c7C528Bb3a846c842dfaF9;
    address internal permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    struct RegistrationConfig {
        string name;
        string symbol;
        bytes32 salt;
        TokenConfig[] tokenConfig;
        uint256 swapFeePercentage;
        bool protocolFeeExempt;
        PoolRoleAccounts roleAccounts;
        address poolHooksContract;
        LiquidityManagement liquidityManagement;
    }

    struct InitializationConfig {
        IERC20[] tokens;
        uint256[] exactAmountsIn;
        uint256 minBptAmountOut;
        bool wethIsEth;
        bytes userData;
    }

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
        IRouter(router).initialize(pool, tokens, exactAmountsIn, minBptAmountOut, wethIsEth, userData);
    }

    /**
     * Sorts the tokenConfig array into alphanumeric order
     */
    function sortTokenConfig(TokenConfig[] memory tokenConfig) internal pure returns (TokenConfig[] memory) {
        for (uint256 i = 0; i < tokenConfig.length - 1; i++) {
            for (uint256 j = 0; j < tokenConfig.length - i - 1; j++) {
                if (tokenConfig[j].token > tokenConfig[j + 1].token) {
                    // Swap if they're out of order.
                    (tokenConfig[j], tokenConfig[j + 1]) = (tokenConfig[j + 1], tokenConfig[j]);
                }
            }
        }
        return tokenConfig;
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
            IPermit2(permit2).approve(address(tokens[i]), spender, maxAmount, maxExpiration);
        }
    }
}
