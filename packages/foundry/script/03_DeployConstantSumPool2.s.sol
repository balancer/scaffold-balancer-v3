// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LiquidityManagement, PoolRoleAccounts } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { HelperFunctions } from "../utils/HelperFunctions.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { Script, console } from "forge-std/Script.sol";
import { RegistrationConfig, InitializationConfig } from "../utils/PoolTypes.sol";

/**
 * @title Deploy Constant Sum Pool #2
 * @notice This script deploys a new pool using the most recently deployed pool factory and mock tokens
 * @notice Some of the pool registration/initialization configurations are set in `HelperConfig.sol`
 * @notice Some config is set directly in this script including the pool hooks contract
 * @dev Run this script with `yarn deploy:pool2`
 */
contract DeployConstantSumPool2 is HelperFunctions, Script {
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
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "ConstantSumFactory", // Must match the pool factory contract name
            block.chainid
        );
        ConstantSumFactory factory = ConstantSumFactory(poolFactoryAddress);
        /**
         * @notice Altering some of the config for this second pool
         * @dev Watch out for "stack too deep" error if you declare too many vars directly in this `run()` function
         */
        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: msg.sender, // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: msg.sender, // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: msg.sender // Account empowered to set the pool creator fee percentage
        });
        address veBalFeeDiscountHook = DevOpsTools.get_most_recent_deployment(
            "VeBALFeeDiscountHook", // Must match the mock token contract name
            block.chainid
        );
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
            veBalFeeDiscountHook, // poolHooksContract
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
}
