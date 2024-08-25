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
        (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) = deployMockTokens.run();

        // Deploy factories that will be used to create & register pools
        DeployPoolFactories deployPoolFactories = new DeployPoolFactories();
        (address constantSumFactory, address constantProductFactory, address weightedFactory) = deployPoolFactories
            .run();

        // Deploy pool hooks
        DeployPoolHooks deployPoolHooks = new DeployPoolHooks();
        address veBalFeeDiscountHook = deployPoolHooks.run(constantProductFactory, mockVeBAL);

        // Deploy, register, and initialize a constant sum pool
        DeployConstantSumPool deployConstantSum = new DeployConstantSumPool();
        deployConstantSum.run(constantSumFactory, address(mockToken1), address(mockToken2));

        // Deploy, register, and initialize a constant product pool
        DeployConstantProductPool deployConstantProduct = new DeployConstantProductPool();
        deployConstantProduct.run(
            constantProductFactory,
            veBalFeeDiscountHook,
            address(mockToken1),
            address(mockToken2)
        );

        // Deploy, register, and initialize a weighted pool
        DeployWeightedPool deployWeighted = new DeployWeightedPool();
        deployWeighted.run(weightedFactory, address(mockToken1), address(mockToken2));
    }

    modifier export() {
        _;
        exportDeployments();
    }
}
