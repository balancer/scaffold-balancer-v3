// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {HelperFunctions} from "../utils/HelperFunctions.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {TokenConfig} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";

/**
 * @title DeployPool Script
 * @author BuidlGuidl Labs
 * @notice This script creates a new pool using the most recently deployed pool factory and then initializes it
 * @notice This script can be run directly, but is also inherited by the `DeployFactoryAndPool.s.sol` script
 */
contract DeployPool is HelperFunctions, HelperConfig, Script {
    error InvalidPrivateKey(string);
    string name = "Scaffold Balancer Constant Price Pool #2"; // name for the pool
    string symbol = "POOL2-SB-50scUSD-50scDAI"; // symbol for the BPT

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

        // Deploy mock tokens to use in the pool
        vm.startBroadcast(deployerPrivateKey);
        (IERC20 token1, IERC20 token2) = (IERC20(DevOpsTools.get_most_recent_deployment(
            "MockToken1", // Must match the pool factory contract name
            block.chainid
        )),IERC20(DevOpsTools.get_most_recent_deployment(
            "MockToken2", // Must match the pool factory contract name
            block.chainid
        ))); // Get the most recently deployed address of the pool factory)

        vm.stopBroadcast();

        // Look up configurations from `HelperConfig.sol`
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            TokenConfig[] memory tokenConfig
        ) = helperConfig.getPoolConfig(token1, token2);
        (
            IERC20[] memory tokens,
            uint256[] memory exactAmountsIn,
            uint256 minBptAmountOut,
            bool wethIsEth,
            bytes memory userData
        ) = helperConfig.getInitializationConfig(tokenConfig);
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "CustomPoolFactoryExample", // Must match the pool factory contract name
            block.chainid
        ); // Get the most recently deployed address of the pool factory

        // Deploy a pool using the factory contract and then initialize it
        vm.startBroadcast(deployerPrivateKey);
        address pool = deployPoolFromFactory(
            poolFactoryAddress,
            name,
            symbol,
            helperConfig.sortTokenConfig(tokenConfig)
        );
        tokens = InputHelpers.sortTokens(tokens);
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

    /**
     * @notice Uses the pool name to generate a salt for the pool deployment
     */
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
        maxApproveTokens(address(vault), tokens);

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
     * @notice Max approving to speed up UX on frontend
     * @param tokens Array of tokens to approve
     * @param spender Address of the spender
     */
    function maxApproveTokens(
        address spender,
        IERC20[] memory tokens
    ) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, type(uint256).max);
        }
    }
}
