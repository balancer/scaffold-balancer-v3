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
import { MockToken1 } from "../contracts/MockToken1.sol";
import { MockToken2 } from "../contracts/MockToken2.sol";
import { RegistrationConfig, InitializationConfig } from "./PoolTypes.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @dev This is where all configurations are set for mock token deployment, factory deployment, pool deployment, and pool initialization
 * @dev Each pool deployed must have a unique name
 * @dev If using this and the associated deployment scripts to help troubleshoot your own custom pool type, then it is advised to use this HelperConfig to outline the appropriate details of your custom pool to use the already written example scripts within this repo.
 */
contract HelperConfig {
    // BalancerV3 Sepolia addresses (5th testnet release)
    IVault internal vault = IVault(0xD5584b37D1845fFeD958C2d94bC675603DdCce68);
    IRouter internal router = IRouter(0x1c58cc548a23956469c7C528Bb3a846c842dfaF9);
    // Canonical permit2 Sepolia address
    IPermit2 internal permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /**
     * @dev Set the pool factory configurations here
     */
    function getFactoryConfig() internal pure returns (uint32 pauseWindowDuration) {
        pauseWindowDuration = 365 days;
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     */
    function getPoolConfig() internal view returns (RegistrationConfig memory regConfig) {
        string memory name = "Constant Sum Pool #1"; // name for the pool
        string memory symbol = "CS1-50scUSD-50scDAI"; // symbol for the BPT
        bytes32 salt = keccak256(abi.encode(name)); // salt for the pool deployment via factory
        // Grab the most recently deployed addresses of mock tokens
        address mockToken1 = DevOpsTools.get_most_recent_deployment(
            "MockToken1", // Must match the mock token contract name
            block.chainid
        );
        address mockToken2 = DevOpsTools.get_most_recent_deployment(
            "MockToken2", // Must match the mock token contract name
            block.chainid
        );
        /** TokenConfig encapsulates the data required for the Vault to support a token of the given type. For STANDARD tokens,
         * the rate provider address must be 0, and paysYieldFees must be false. All WITH_RATE tokens need a rate provider,
         * and may or may not be yield-bearing.
         */
        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
        tokenConfig[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(mockToken1),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        tokenConfig[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(mockToken2),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        uint256 swapFeePercentage = 1e12; // 0.00001%
        bool protocolFeeExempt = false;
        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: address(0), // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: address(0), // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: address(0) // Account empowered to set the pool creator fee percentage
        });
        address poolHooksContract = address(0); // No hook contract
        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false
        });

        regConfig = RegistrationConfig({
            name: name,
            symbol: symbol,
            salt: salt,
            tokenConfig: sortTokenConfig(tokenConfig),
            swapFeePercentage: swapFeePercentage,
            protocolFeeExempt: protocolFeeExempt,
            roleAccounts: roleAccounts,
            poolHooksContract: poolHooksContract,
            liquidityManagement: liquidityManagement
        });
    }

    /**
     * @dev Set the pool initialization configurations here
     * @notice this is where the amounts of tokens to be initially added to the pool are set
     */
    function getInitializationConfig(
        TokenConfig[] memory tokenConfig
    ) internal pure returns (InitializationConfig memory poolInitConfig) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = tokenConfig[0].token;
        tokens[1] = tokenConfig[1].token;
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 10 ether; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 10 ether; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        poolInitConfig = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }

    /**
     * Helper function to sort the tokenConfig array
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
}
