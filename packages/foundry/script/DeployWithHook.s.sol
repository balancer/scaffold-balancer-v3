//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployConstantProductPool } from "./02_DeployConstantProductPool.s.sol";
import { DeployCPPWithVolatilityFeeHook } from "./04_DeployCPPWithVolatilityFeeHook.s.sol";
/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with nextjs front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is
    ScaffoldHelpers,
    DeployMockTokens,
    DeployConstantProductPool,
    DeployCPPWithVolatilityFeeHook
{
    function run() external scaffoldExport {
        // Deploy mock tokens to use for the pools and hooks
        (address mockToken1, address mockToken2, address mockVeBAL) = deployMockTokens();

        // Deploy, register, and initialize a constant product pool with a lottery hook
        deployConstantProductPool(mockToken1, mockToken2);

        // Deploy, Register, and Initialize a CPP Pool with Volatility Fee Hook V1 and V2
        deployCPPWithVolatilityFeeHook(mockToken1, mockToken2);

    }

    modifier scaffoldExport() {
        _;
        exportDeployments();
    }
}
