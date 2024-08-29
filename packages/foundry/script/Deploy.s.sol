//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployConstantSumPool } from "./01_DeployConstantSumPool.s.sol";
import { DeployConstantProductPool } from "./02_DeployConstantProductPool.s.sol";
import { DeployWeightedPool8020 } from "./03_DeployWeightedPool8020.s.sol";

/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with nextjs front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is ScaffoldHelpers {
    function run() external scaffoldExport {
        // Deploy mock tokens to be used for pools and hooks contracts
        DeployMockTokens deployMockTokens = new DeployMockTokens();
        (address mockToken1, address mockToken2, address mockVeBAL) = deployMockTokens.run();

        // Deploy, register, and initialize a constant sum pool
        DeployConstantSumPool depoloySumPool = new DeployConstantSumPool();
        depoloySumPool.run(mockToken1, mockToken2);

        // Deploy, register, and initialize a constant product pool
        DeployConstantProductPool deployProductPool = new DeployConstantProductPool();
        deployProductPool.run(mockToken1, mockToken2, mockVeBAL);

        // Deploy, register, and initialize a weighted pool
        DeployWeightedPool8020 deployWeightedPool = new DeployWeightedPool8020();
        deployWeightedPool.run(mockToken1, mockToken2);
    }

    modifier scaffoldExport() {
        _;
        exportDeployments();
    }
}
