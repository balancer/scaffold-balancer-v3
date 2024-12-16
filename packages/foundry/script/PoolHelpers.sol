// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    TokenConfig,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IBatchRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { console } from "forge-std/Script.sol";

/**
 * @title Pool Helpers
 * @notice Helpful addresses,functions, and types for deploying pools on Balancer v3
 * @dev Since the block.chainid will always be 31337 when deploying to local anvil fork,
 * if you wish to fork another network, uncomment the relevant addresses below
 */
contract PoolHelpers {
    // Same address on all chains
    IPermit2 internal permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IVault internal vault = IVault(0xbA1333333333a1BA1108E8412f11850A5C319bA9);

    // Mainnet
    IRouter internal router = IRouter(0x5C6fb490BDFD3246EB0bB062c168DeCAF4bD9FDd);
    IBatchRouter internal batchRouter = IBatchRouter(0x136f1EFcC3f8f88516B9E94110D56FDBfB1778d1);

    // Gnosis
    //  IRouter internal router =  IRouter(0x84813aA3e079A665C0B80F944427eE83cBA63617);
    // IBatchRouter internal batchRouter = IBatchRouter(0xe2fa4e1d17725e72dcdAfe943Ecf45dF4B9E285b);

    // Sepolia
    // IRouter internal router = IRouter(0x0BF61f706105EA44694f2e92986bD01C39930280);
    // IBatchRouter internal batchRouter IBatchRouter(0xC85b652685567C1B074e8c0D4389f83a2E458b1C);

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
    function approveSpenderOnToken(address spender, IERC20[] memory tokens) internal {
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
    function approveSpenderOnPermit2(address spender, IERC20[] memory tokens) internal {
        uint160 maxAmount = type(uint160).max;
        uint48 maxExpiration = type(uint48).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            permit2.approve(address(tokens[i]), spender, maxAmount, maxExpiration);
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
