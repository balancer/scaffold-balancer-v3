// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {TokenConfig, LiquidityManagement, PoolRoleAccounts} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";

/**
 * @title Pool Helpers
 * @notice Helpful types, interface instances, and functions for deploying pools on Balancer v3
 */
contract PoolHelpers {
    // BalancerV3 Sepolia addresses (7th testnet release)
    IVault internal vault = IVault(0x7966FE92C59295EcE7FB5D9EfDB271967BFe2fbA);
    IRouter internal router =
        IRouter(0xDd10aDF05379D7C0Ee4bC9c72ecc5C01c40E25b8);
    IPermit2 internal permit2 =
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /**
     * Sorts the tokenConfig array into alphanumeric order
     */
    function sortTokenConfig(
        TokenConfig[] memory tokenConfig
    ) internal pure returns (TokenConfig[] memory) {
        for (uint256 i = 0; i < tokenConfig.length - 1; i++) {
            for (uint256 j = 0; j < tokenConfig.length - i - 1; j++) {
                if (tokenConfig[j].token > tokenConfig[j + 1].token) {
                    // Swap if they're out of order.
                    (tokenConfig[j], tokenConfig[j + 1]) = (
                        tokenConfig[j + 1],
                        tokenConfig[j]
                    );
                }
            }
        }
        return tokenConfig;
    }

    /**
     * @notice Approve permit2 on the token contract, then approve the router on the Permit2 contract
     * @param tokens Array of tokens to approve the router to spend using Permit2
     */
    function approveRouterWithPermit2(IERC20[] memory tokens) internal {
        approveSpenderOnToken(address(permit2), tokens);
        approveSpenderOnPermit2(address(router), tokens);
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param spender Address of the spender
     * @param tokens Array of tokens to approve
     */
    function approveSpenderOnToken(
        address spender,
        IERC20[] memory tokens
    ) internal {
        uint256 maxAmount = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, maxAmount);
        }
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param spender Address of the spender
     * @param tokens Array of tokens to approve
     */
    function approveSpenderOnPermit2(
        address spender,
        IERC20[] memory tokens
    ) internal {
        uint160 maxAmount = type(uint160).max;
        uint48 maxExpiration = type(uint48).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            permit2.approve(
                address(tokens[i]),
                spender,
                maxAmount,
                maxExpiration
            );
        }
    }
}

struct CustomPoolConfig {
    string name;
    string symbol;
    bytes32 salt;
    TokenConfig[] tokenConfigs;
    uint256 swapFeePercentage;
    bool protocolFeeExempt;
    PoolRoleAccounts roleAccounts;
    address poolHooksContract;
    LiquidityManagement liquidityManagement;
}

struct WeightedPoolConfig {
    string name;
    string symbol;
    TokenConfig[] tokenConfigs;
    uint256[] normalizedWeights;
    PoolRoleAccounts roleAccounts;
    uint256 swapFeePercentage;
    address poolHooksContract;
    bool enableDonation;
    bool disableUnbalancedLiquidity;
    bytes32 salt;
}

struct InitializationConfig {
    IERC20[] tokens;
    uint256[] exactAmountsIn;
    uint256 minBptAmountOut;
    bool wethIsEth;
    bytes userData;
}
