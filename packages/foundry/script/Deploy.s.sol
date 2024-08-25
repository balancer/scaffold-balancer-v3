//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployPoolFactories } from "./01_DeployPoolFactories.s.sol";
import { DeployPoolHooks } from "./02_DeployPoolHooks.s.sol";
import { DeployConstantSumPool } from "./03_DeployConstantSumPool.s.sol";
import { DeployConstantProductPool } from "./04_DeployConstantProductPool.s.sol";
import { DeployWeightedPool } from "./05_DeployWeightedPool.s.sol";

/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is ScaffoldHelpers {
    function run() external export {
        // Deploy mock tokens to be used for pools and hooks contracts
        DeployMockTokens deployMockTokens = new DeployMockTokens();
        (address mockToken1, address mockToken2, address mockVeBAL) = deployMockTokens.run();

        // Deploy factories that will be used to create & register pools
        DeployPoolFactories deployFactories = new DeployPoolFactories();
        (address constantSumFactory, address constantProductFactory, address weightedFactory) = deployFactories.run();

        // Deploy pool hooks
        DeployPoolHooks deployPoolHooks = new DeployPoolHooks();
        address veBalFeeDiscountHook = deployPoolHooks.run(constantProductFactory, mockVeBAL);

        // Deploy, register, and initialize a constant sum pool
        DeployConstantSumPool depoloySumPool = new DeployConstantSumPool();
        depoloySumPool.run(constantSumFactory, address(mockToken1), address(mockToken2));

        // Deploy, register, and initialize a constant product pool
        DeployConstantProductPool deployProductPool = new DeployConstantProductPool();
        deployProductPool.run(constantProductFactory, veBalFeeDiscountHook, mockToken1, mockToken2);

        // Deploy, register, and initialize a weighted pool
        DeployWeightedPool deployWeightedPool = new DeployWeightedPool();
        deployWeightedPool.run(weightedFactory, address(mockToken1), address(mockToken2));
    }

    modifier export() {
        _;
        exportDeployments();
    }
}
