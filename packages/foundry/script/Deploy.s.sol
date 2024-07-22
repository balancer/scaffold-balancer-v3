//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { PoolHelpers } from "./PoolHelpers.sol";
import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { DeployMockTokens } from "./DeployMockTokens.s.sol";
import { DeployConstantSumPool } from "./DeployConstantSumPool.s.sol";
import { DeployConstantProductPool } from "./DeployConstantProductPool.s.sol";

/**
 * @title Deploy Script
 * @notice Deploys mock tokens, a constant sum pool, and a constant product pool
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is DeployMockTokens, DeployConstantSumPool, DeployConstantProductPool {
    function run() external virtual {
        // Deploy the mock tokens
        (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) = deployMockTokens();

        // Deploy a constant sum factory pool
        deployConstantSumPool(mockToken1, mockToken2);

        // Deploy a constant product pool
        deployConstantProductPool(mockToken1, mockToken2, mockVeBAL);

        /**
         * This function generates the file containing the contracts Abi definitions that are carried from /foundry to /nextjs.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
