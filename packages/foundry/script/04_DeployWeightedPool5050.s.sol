//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import { PoolHelpers, InitializationConfig } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { WeightedPoolFactory } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";
import { MevTaxHook } from "../contracts/hooks/MevTaxHook.sol";

/**
 * @title Deploy Weighted Pool 50/50
 * @notice Deploys, registers, and initializes a 50/50 weighted pool that uses an Mev Tax Hook
 */

contract DeployWeightedPool5050 is PoolHelpers, ScaffoldHelpers {
    
    uint256 private constant MEV_TAX_MULTIPLIER = 50e18;
    
    function deployWeightedPool5050(address token1, address token2) internal {
        // Set the pool initialization config
        InitializationConfig memory initConfig = getWeightedPoolInitConfig5050(token1, token2);

        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a  factory
        WeightedPoolFactory factory = new WeightedPoolFactory(vault, 365 days, "Factory v1", "Pool v1");
        console.log("Weighted Pool Factory deployed at: %s", address(factory));

        // Deploy a hook
        address mevTaxHook = address(new MevTaxHook(vault, address(factory), MEV_TAX_MULTIPLIER));
        console.log("MevTaxHook deployed at address: %s", mevTaxHook);

        // Deploy a pool and register it with the vault
        /// @notice passing args directly to avoid stack too deep error
        address pool = factory.create(
            "50/50 Weighted Pool", // string name
            "50-50-WP", // string symbol
            getTokenConfigs5050(token1, token2), // TokenConfig[] tokenConfigs
            getNormalizedWeights5050(), // uint256[] normalizedWeights
            getRoleAccounts5050(), // PoolRoleAccounts roleAccounts
            0.1e18, // uint256 swapFeePercentage (1%)
            mevTaxHook, // address poolHooksContract
            false, //bool enableDonation
            true, // bool disableUnbalancedLiquidity
            keccak256(abi.encode(block.number)) // bytes32 salt
        );
        console.log("Weighted Pool deployed at: %s", pool);

        // Approve the router to spend tokens for pool initialization
        approveRouterWithPermit2(initConfig.tokens);

        // Seed the pool with initial liquidity using Router as entrypoint
        router.initialize(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Weighted Pool initialized successfully!");
        vm.stopBroadcast();
    }

    /**
     * @dev Set the token configs for the pool
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getTokenConfigs5050(address token1, address token2) internal pure returns (TokenConfig[] memory tokenConfigs) {
        tokenConfigs = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage
        tokenConfigs[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(token1),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        tokenConfigs[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(token2),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        sortTokenConfig(tokenConfigs);
    }

    /// @dev Set the weights for each token in the pool
    function getNormalizedWeights5050() private pure returns (uint256[] memory normalizedWeights) {
        normalizedWeights = new uint256[](2);
        normalizedWeights[0] = uint256(50e16);
        normalizedWeights[1] = uint256(50e16);
    }

    /// @dev Set the role accounts for the pool
    function getRoleAccounts5050() private pure returns (PoolRoleAccounts memory roleAccounts) {
        roleAccounts = PoolRoleAccounts({
            pauseManager: address(0), // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: address(0), // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: address(0) // Account empowered to set the pool creator fee percentage
        });
    }

    /// @dev Set the initialization config for the pool (i.e. the amount of tokens to be added)
    function getWeightedPoolInitConfig5050(
        address token1,
        address token2
    ) private pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 50e18; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 50e18; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 49e18; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        config = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }
}
