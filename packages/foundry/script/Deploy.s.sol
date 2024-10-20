//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployConstantSumPool } from "./01_DeployConstantSumPool.s.sol";
import { DeployConstantProductPool } from "./02_DeployConstantProductPool.s.sol";
import { DeployWeightedPool8020 } from "./03_DeployWeightedPool8020.s.sol";
import { DeployWeightedPool5050 } from "./04_DeployWeightedPool5050.s.sol";

/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with nextjs front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is
    ScaffoldHelpers,
    DeployMockTokens,
    DeployWeightedPool5050
{
    function run() external scaffoldExport {
        // Deploy mock tokens to use for the pools and hooks
        (address mockToken1, address mockToken2) = deployMockTokens();

        // Deploy, register, and initialize a 50/50 weighted pool
        deployWeightedPool5050(mockToken1, mockToken2);
    }

    modifier scaffoldExport() {
        _;
        exportDeployments();
    }
}
