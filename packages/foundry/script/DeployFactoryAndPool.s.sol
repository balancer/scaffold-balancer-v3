//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {DeployPool} from "./DeployPool.s.sol";
import "./ScaffoldETHDeploy.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {TokenConfig} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ArrayHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

/**
 * @title DeployFactoryAndPool
 * @author BuidlGuidl Labs
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

        // Look up configuration options from `HelperConfig.sol`
        HelperConfig helperConfig = new HelperConfig();
        uint256 pauseWindowDuration = helperConfig.getFactoryConfig();
        (
            string memory name,
            string memory symbol,
            TokenConfig[] memory tokenConfig
        ) = helperConfig.getPoolConfig(mockToken1, mockToken2);
        (
            IERC20[] memory tokens,
            uint256[] memory exactAmountsIn,
            uint256 minBptAmountOut,
            bool wethIsEth,
            bytes memory userData
        ) = helperConfig.getInitializationConfig(tokenConfig);

        // Deploy the pool factory and then deploy a pool using the factory and then initialize the pool
        vm.startBroadcast(deployerPrivateKey);
        CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(
                vault,
                pauseWindowDuration
            );
        console.log("Deployed Factory Address: %s", address(customPoolFactory));
        address pool = deployPoolFromFactory(
            address(customPoolFactory),
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

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
