//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { DeployMockTokens } from "./DeployMockTokens.s.sol";
import { DeployConstantSum } from "./DeployConstantSum.s.sol";
import { DeployConstantProduct } from "./DeployConstantProduct.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Deploy Script
 * @notice Import all deploy scripts here so that scaffold can exportDeployments()
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is ScaffoldHelpers {
    function run() external virtual {
        // Deploy mock tokens to be used for pools and hooks contracts
        DeployMockTokens deployMockTokens = new DeployMockTokens();
        (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) = deployMockTokens.run();

        // Deploy a constant sum factory and a pool
        DeployConstantSum deployConstantSum = new DeployConstantSum();
        deployConstantSum.run(mockToken1, mockToken2);

        // Deploy a constant product factory, a hooks contract, and a pool
        DeployConstantProduct deployConstantProduct = new DeployConstantProduct();
        deployConstantProduct.run(mockToken1, mockToken2, mockVeBAL);

        /**
         * This function generates the file containing the contracts Abi definitions that are carried from /foundry to /nextjs.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
