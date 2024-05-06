//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployPoolFactory} from "./DeployPoolFactory.s.sol";
import {DeployPool} from "./DeployPool.s.sol";
import "./DeployHelpers.s.sol";

/**
 * @title DeployScript
 * @author BuidlGuidl Labs
 * @notice Contracts deployed by this script will have their info saved into the frontend for hot reload
 * @notice This script deploys a new pool factory, deploys a new pool from that factory, and initializes the pool with mock tokens
 * @notice Mock tokens and BPT will be sent to the PK set in the .env file
 */
contract DeployScript is ScaffoldETHDeploy, DeployPoolFactory, DeployPool {
    error InvalidPrivateKey(string);

    // Pool Factory Congig
    uint256 pauseWindowDuration = 365 days; // All Pools created by this factory will share the same Pause Window end time, after which both old and new Pools will not be pausable.

    // Pool Deployment Config
    string name = "Scaffold Balancer Pool #1"; // Pool name
    string symbol = "SB-50scUSD-50scDAI"; // BPT symbol
    address token1; // Make sure to have proper token order (alphanumeric)
    address token2; // Make sure to have proper token order (alphanumeric)

    // Pool Initialization Config
    uint256[] exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
    uint256 minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
    bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
    bytes userData = bytes("");

    constructor() {
        exactAmountsIn[0] = 10 ether; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 10 ether; // amount of token2 to send during pool initialization
    }

    function run() external override(DeployPool, DeployPoolFactory) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Pool Factory
        address poolFactoryAddress = deployPoolFactory(pauseWindowDuration);

        // Create mock tokens (remove this if using real tokens and set token addresses above in "Pool Deployment Configurations")
        (token1, token2) = deployMockTokens();

        // Deploy pool from factory using values set above in "Pool Deployment Config" section
        address pool = deployPoolFromFactory(
            poolFactoryAddress,
            name,
            symbol,
            token1,
            token2
        );

        // Initialize pool using values set above in "Pool Initialization Configurations" section
        initializePool(
            pool,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
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
