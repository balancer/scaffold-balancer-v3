//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { PoolHelpers } from "./PoolHelpers.sol";

import { ConstantSumFactory } from "../contracts/factories/ConstantSumFactory.sol";
import { ConstantProductFactory } from "../contracts/factories/ConstantProductFactory.sol";
import { WeightedPoolFactory } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";

/**
 * @dev Deploys pool factories to be used for deploying & registering pools
 * @notice Pool factories are also used by pool hooks contracts to determine which pools are allowed to use a hook
 */
contract DeployPoolFactories is ScaffoldHelpers, PoolHelpers {
    function run()
        external
        returns (address constantSumFactory, address constantProductFactory, address weightedFactory)
    {
        // Set the deployment configurations
        uint32 pauseWindowDuration = 365 days;
        string memory factoryVersion = "Factory v1";
        string memory poolVersion = " Pool v1";

        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a constant sum factory
        constantSumFactory = address(new ConstantSumFactory(vault, pauseWindowDuration));
        console.log("Constant Product Factory deployed at: %s", constantSumFactory);

        // Deploy a constant product factory
        constantProductFactory = address(new ConstantProductFactory(vault, pauseWindowDuration));
        console.log("Constant Product Factory deployed at: %s", constantProductFactory);

        // Deploy a weighted pool factory contract
        weightedFactory = address(new WeightedPoolFactory(vault, pauseWindowDuration, factoryVersion, poolVersion));
        console.log("Weighted Pool Factory deployed at: %s", weightedFactory);

        vm.stopBroadcast();
    }
}
