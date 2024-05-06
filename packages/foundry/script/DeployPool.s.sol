// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {HelperFunctions} from "../utils/HelperFunctions.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {TokenConfig} from "../contracts/interfaces/VaultTypes.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployPool Script
 * @author BuidlGuidl Labs
 * @notice This script uses the PK specified in the .env file to create a new pool using the most recently deployed pool factory
 * @notice This script is inhereted by Deploy.s.sol but can be run directly with `yarn deploy:pool`
 * @dev if running directly, set the pool deployment and initialization configurations in the `run()` function below
 */
contract DeployPool is HelperFunctions, HelperConfig, Script {
    function deployPoolFromFactory(
        address poolFactoryAddress,
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokenConfig
    ) internal returns (address) {
        CustomPoolFactoryExample poolFactory = CustomPoolFactoryExample(
            poolFactoryAddress
        );

        bytes32 salt = convertNameToBytes32(name);
        address newPool = poolFactory.create(name, symbol, tokenConfig, salt);
        console.log("Deployed Pool Address: %s", newPool);
        return newPool;
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
        maxApproveVault(tokens);

        router.initialize(
            pool,
            tokens,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
        );
    }

    /**
     * @notice Max approving vault to speed up UX on frontend
     * @param tokens Array of tokens to approve the vault to spend
     */
    function maxApproveVault(IERC20[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(vault), type(uint256).max);
        }
    }

    /**
     * @dev Set your pool deployment and initialization configurations in `HelperConfig.s.sol`
     * @dev Deploy only the pool with the CLI command `yarn deploy:pool`
     */
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Tokens for pool (also requires attention to TokenConfig in `getPoolConfig` function of HelperConfig.s.sol)
        IERC20 token1; // Make sure to have proper token order (alphanumeric)
        IERC20 token2; // Make sure to have proper token order (alphanumeric)

        // Deploy mock tokens to use in the pool
        vm.startBroadcast(deployerPrivateKey);
        (token1, token2) = deployMockTokens();
        vm.stopBroadcast();

        HelperConfig helperConfig = new HelperConfig();
        (
            string memory name,
            string memory symbol,
            TokenConfig[] memory tokenConfig
        ) = helperConfig.getPoolConfig(token1, token2);
        (
            IERC20[] memory tokens,
            uint256[] memory exactAmountsIn,
            uint256 minBptAmountOut,
            bool wethIsEth,
            bytes memory userData
        ) = helperConfig.getInitializationConfig();
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "CustomPoolFactoryExample", // Must match the pool factory contract name
            block.chainid
        ); // Get the most recently deployed address of the pool factory

        vm.startBroadcast(deployerPrivateKey);

        address pool = deployPoolFromFactory(
            poolFactoryAddress,
            name,
            symbol,
            tokenConfig
        );

        initializePool(
            pool,
            tokens,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
        );

        vm.stopBroadcast();
    }
}
