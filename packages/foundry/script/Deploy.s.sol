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
contract DeployScript is
    ScaffoldHelpers,
    DeployMockTokens,
    DeployConstantSumPool,
    DeployConstantProductPool,
    DeployWeightedPool8020
{
    function run() external scaffoldExport {
        // Deploy mock tokens to use for the pools and hooks
        (address mockToken1, address mockToken2, address mockToken3, address mockVeBAL) = deployMockTokens();

        // Deploy existing pools with original token pairs
        deployConstantSumPool(mockToken1, mockToken2, mockVeBAL);
        deployConstantProductPool(mockToken1, mockToken2);
        deployWeightedPool8020(mockToken1, mockToken2);

        // Deploy additional pools with new token combinations
        deployConstantSumPool(mockToken2, mockToken3, mockVeBAL);
        deployConstantProductPool(mockToken1, mockToken3);
        deployWeightedPool8020(mockToken2, mockToken3);
    }

    modifier scaffoldExport() {
        _;
        exportDeployments();
    }
}
