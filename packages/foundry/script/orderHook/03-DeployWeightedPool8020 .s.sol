//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TokenConfig, TokenType, LiquidityManagement, PoolRoleAccounts} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {PoolHelpers, InitializationConfig} from "./PoolHelpers.sol";
import {WeightedPoolFactory} from "lib/balancer-v3-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";
import {OrderHook} from "../src/OrderHook.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {Script, console} from "forge-std/Script.sol";

/**
 * @title Deploy Weighted Pool 80/20
 * @notice Deploys, registers, and initializes a 80/20 weighted pool that uses an Exit Fee Hook
 */
contract DeployWeightedPool8020 is PoolHelpers, Script {
    function deployWeightedPool8020(address token1, address token2) public {
        HelperConfig helperConfig = new HelperConfig();

        // Set the pool initialization config
        InitializationConfig memory initConfig = getWeightedPoolInitConfig(
            token1,
            token2
        );

        // Start creating the transactions
        address deployer = helperConfig.getConfig().account;
        vm.startBroadcast(deployer);

        // Deploy a  factory
        WeightedPoolFactory factory = new WeightedPoolFactory(
            vault,
            365 days,
            "Factory v1",
            "Pool v1"
        );
        console.log("Weighted Pool Factory deployed at: %s", address(factory));

        // Deploy a hook
        address orderHook = address(
            new OrderHook(
                IVault(helperConfig.getConfig().vault),
                address(factory),
                helperConfig.getConfig().router,
                IPermit2(helperConfig.getConfig().permit2)
            )
        );
        console.log("ExitFeeHook deployed at address: %s", orderHook);

        // Deploy a pool and register it with the vault
        /// @notice passing args directly to avoid stack too deep error
        address pool = factory.create(
            "80/20 Weighted Pool", // string name
            "80-20-WP", // string symbol
            getTokenConfigs(token1, token2), // TokenConfig[] tokenConfigs
            getNormailzedWeights(), // uint256[] normalizedWeights
            getRoleAccounts(), // PoolRoleAccounts roleAccounts
            0.03e18, // uint256 swapFeePercentage (3%)
            orderHook, // address poolHooksContract
            true, //bool enableDonation
            true, // bool disableUnbalancedLiquidity (must be true for the ExitFee Hook)
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
    function getTokenConfigs(
        address token1,
        address token2
    ) internal pure returns (TokenConfig[] memory tokenConfigs) {
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
    function getNormailzedWeights()
        internal
        pure
        returns (uint256[] memory normalizedWeights)
    {
        normalizedWeights = new uint256[](2);
        normalizedWeights[0] = uint256(80e16);
        normalizedWeights[1] = uint256(20e16);
    }

    /// @dev Set the role accounts for the pool
    function getRoleAccounts()
        internal
        pure
        returns (PoolRoleAccounts memory roleAccounts)
    {
        roleAccounts = PoolRoleAccounts({
            pauseManager: address(0), // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: address(0), // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: address(0) // Account empowered to set the pool creator fee percentage
        });
    }

    /// @dev Set the initialization config for the pool (i.e. the amount of tokens to be added)
    function getWeightedPoolInitConfig(
        address token1,
        address token2
    ) internal pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 80e18; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 20e18; // amount of token2 to send during pool initialization
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
