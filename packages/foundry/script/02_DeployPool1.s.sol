// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { HelperFunctions } from "../utils/HelperFunctions.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { Script, console } from "forge-std/Script.sol";
import { RegistrationConfig, InitializationConfig } from "../utils/PoolTypes.sol";

/**
 * @title Deploy Pool Script
 * @notice This script deploys a new pool using the most recently deployed pool factory and mock tokens
 * @dev Set the pool registration and initialization configurations in `HelperConfig.sol`
 * @dev Run this script with `yarn deploy:pool`
 */
contract DeployPool is HelperFunctions, Script {
    error InvalidPrivateKey(string);

    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        /**
         * @dev Set the pool registration and initialization configurations in `HelperConfig.sol`
         */
        RegistrationConfig memory regConfig = getPoolConfig();
        InitializationConfig memory initConfig = getInitializationConfig(regConfig.tokenConfig);
        // Grab the most recently deployed address of the pool factory
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "ConstantSumFactory", // Must match the pool factory contract name
            block.chainid
        );
        ConstantSumFactory factory = ConstantSumFactory(poolFactoryAddress);
        // Send the transactions
        vm.startBroadcast(deployerPrivateKey);
        // Deploy the pool (and register it with the vault)
        address newPool = factory.create(
            regConfig.name,
            regConfig.symbol,
            regConfig.salt,
            regConfig.tokenConfig,
            regConfig.swapFeePercentage,
            regConfig.protocolFeeExempt,
            regConfig.roleAccounts,
            regConfig.poolHooksContract,
            regConfig.liquidityManagement
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
}
