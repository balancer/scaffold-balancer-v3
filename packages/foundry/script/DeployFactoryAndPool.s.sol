//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { DeployPool } from "./DeployPool.s.sol";
import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { CustomPoolFactory } from "../contracts/CustomPoolFactory.sol";
import { HelperConfig } from "../utils/HelperConfig.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { RegistrationConfig, InitializationConfig } from "../utils/PoolTypes.sol";

import {
    TokenConfig,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/ArrayHelpers.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

/**
 * @title Deploy Factory And Pool Script
 * @notice Contracts deployed by this script will have their info saved into the frontend for hot reload
 * @notice This script deploys a pool factory, deploys a pool using the factory, and then initializes the pool with mock tokens
 * @notice Mock tokens and BPT will be sent to the PK set in the .env file
 * @dev Set the pool factory, pool deployment, and pool initialization configurations in `HelperConfig.sol`
 * @dev Then run this script with `yarn deploy:all`
 */
contract DeployFactoryAndPool is ScaffoldETHDeploy, DeployPool {
    function run() external override {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        // Deploy mock tokens. Remove this if using already deployed tokens
        vm.startBroadcast(deployerPrivateKey);
        (address mockToken1, address mockToken2) = deployMockTokens();
        vm.stopBroadcast();

        // Look up all configuration from `HelperConfig.sol`
        HelperConfig helperConfig = new HelperConfig();
        uint32 pauseWindowDuration = helperConfig.getFactoryConfig();
        RegistrationConfig memory regConfig = helperConfig.getPoolConfig(
            "Scaffold Balancer Constant Price Pool #1", // name for the pool
            "SB-50scUSD-50scDAI", // symbol for the BPT
            mockToken1,
            mockToken2
        );
        InitializationConfig memory initConfig = helperConfig.getInitializationConfig(regConfig.tokenConfig);

        // Deploy the pool factory
        vm.startBroadcast(deployerPrivateKey);
        CustomPoolFactory factory = new CustomPoolFactory(vault, pauseWindowDuration);
        console.log("Deployed Factory Address: %s", address(factory));
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
        // Initialize the pool
        initializePool(
            newPool,
            InputHelpers.sortTokens(initConfig.tokens),
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
