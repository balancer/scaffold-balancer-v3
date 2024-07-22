//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { DeployMockTokens } from "./DeployMockTokens.s.sol";
import { DeployConstantSum } from "./DeployConstantSum.s.sol";
import { DeployConstantProduct } from "./DeployConstantProduct.s.sol";

/**
 * @title Deploy Script
 * @notice Import all deploy scripts here so that scaffold can exportDeployments()
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is DeployMockTokens, DeployConstantSum, DeployConstantProduct {
    function run() external virtual {
        // Deploy mock tokens to be used for pools and hooks contracts
        (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) = deployMockTokens();

        // Deploy a constant sum factory and a pool
        deployConstantSum(mockToken1, mockToken2);

        // Deploy a constant product factory, a hooks contract, and a pool
        deployConstantProduct(mockToken1, mockToken2, mockVeBAL);

        /**
         * This function generates the file containing the contracts Abi definitions that are carried from /foundry to /nextjs.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
