// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { HelperConfig } from "../utils/HelperConfig.sol";
import { CustomPoolFactory } from "../contracts/CustomPoolFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { Script, console } from "forge-std/Script.sol";
import { RegistrationConfig, InitializationConfig } from "../utils/PoolTypes.sol";

import {
    TokenConfig,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

/**
 * @title Deploy Pool Script
 * @notice This script creates a new pool using the most recently deployed pool factory and then initializes it
 * @notice This script can be run directly with `yarn deploy:pool`, but is also inherited by the `DeployFactoryAndPool.s.sol` script
 */
contract DeployPool is HelperConfig, Script {
    error InvalidPrivateKey(string);

    /**
     * @dev Set your pool deployment and initialization configurations in `HelperConfig.sol`
     * @dev Deploy only the pool with the CLI command `yarn deploy:pool`
     */
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        address mockToken1 = DevOpsTools.get_most_recent_deployment(
            "MockToken1", // Must match the mock token contract name
            block.chainid
        );
        address mockToken2 = DevOpsTools.get_most_recent_deployment(
            "MockToken2", // Must match the mock token contract name
            block.chainid
        );

        // Generate all configurations from `HelperConfig.sol`
        HelperConfig helperConfig = new HelperConfig();
        RegistrationConfig memory regConfig = helperConfig.getPoolConfig(
            "Scaffold Balancer Constant Price Pool #2", // name for the pool
            "POOL2-SB-50scUSD-50scDAI", // symbol for the BPT
            mockToken1,
            mockToken2
        );
        InitializationConfig memory poolInitConfig = helperConfig.getInitializationConfig(regConfig.tokenConfig);
        // Get the most recently deployed address of the pool factory
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "CustomPoolFactory", // Must match the pool factory contract name
            block.chainid
        );
        CustomPoolFactory factory = CustomPoolFactory(poolFactoryAddress);
        // Deploy the pool (and register it with the vault)
        address newPool = factory.create(
            regConfig.name,
            regConfig.symbol,
            regConfig.salt,
            helperConfig.sortTokenConfig(regConfig.tokenConfig),
            regConfig.swapFeePercentage,
            regConfig.protocolFeeExempt,
            regConfig.roleAccounts,
            regConfig.poolHooksContract,
            regConfig.liquidityManagement
        );
        console.log("Deployed pool at address: %s", newPool);
        IERC20[] memory tokens = InputHelpers.sortTokens(poolInitConfig.tokens);
        initializePool(
            newPool,
            tokens,
            poolInitConfig.exactAmountsIn,
            poolInitConfig.minBptAmountOut,
            poolInitConfig.wethIsEth,
            poolInitConfig.userData
        );
        vm.stopBroadcast();
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
