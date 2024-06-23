// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LiquidityManagement, PoolRoleAccounts } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { HelperConfig } from "../utils/HelperConfig.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { Script, console } from "forge-std/Script.sol";
import { RegistrationConfig, InitializationConfig } from "../utils/PoolTypes.sol";

/**
 * @title Deploy Pool Script
 * @notice This script deploys a new pool using the most recently deployed pool factory and mock tokens
 * @dev Some of the pool registration/initialization configurations are set in `HelperConfig.sol`, some are set directly in this script
 * @dev Run this script with `yarn deploy:pool`
 */
contract DeployPool is HelperConfig, Script {
    error InvalidPrivateKey(string);

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        // Set the pool registration and initialization configurations in `HelperConfig.sol`
        RegistrationConfig memory regConfig = getPoolConfig();
        InitializationConfig memory initConfig = getInitializationConfig(regConfig.tokenConfig);
        // Grab the most recently deployed address of the pool factory
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "ConstantSumFactory", // Must match the pool factory contract name
            block.chainid
        );
        ConstantSumFactory factory = ConstantSumFactory(poolFactoryAddress);
        /**
         * @notice Altering some of the config for this second pool
         * @dev watch out for "stack too deep" error if you declare too many vars directly in this `run()` function
         */
        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: msg.sender, // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: msg.sender, // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: msg.sender // Account empowered to set the pool creator fee percentage
        });
        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: true,
            enableRemoveLiquidityCustom: true
        });
        // Send the transactions
        vm.startBroadcast(deployerPrivateKey);
        // Deploy the pool (and register it with the vault)
        address newPool = factory.create(
            "Constant Sum Pool #2", // name
            "CS2-50scUSD-50scDAI", // symbol
            keccak256(abi.encode("Constant Sum Pool #2")), // salt
            regConfig.tokenConfig, // tokenConfigs
            33e12, // swapFeePercentage of 0.000033%
            regConfig.protocolFeeExempt,
            roleAccounts,
            regConfig.poolHooksContract,
            liquidityManagement
        );
        console.log("Deployed pool at address: %s", newPool);
        // Initialize the pool
        initializePool(
            newPool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Pool initialized successfully!");
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
