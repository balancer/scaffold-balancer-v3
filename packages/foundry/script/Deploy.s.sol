//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployConstantSum } from "./01_DeployConstantSum.s.sol";
import { DeployConstantProduct } from "./02_DeployConstantProduct.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Deploy Script
 * @dev Import & run deploy scripts here so that contract Abis are carried to /nextjs
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is ScaffoldHelpers {
    function run() external export {
        // Deploy mock tokens to be used for pools and hooks contracts
        DeployMockTokens deployMockTokens = new DeployMockTokens();
        (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) = deployMockTokens.run();

        // Deploy a constant sum factory and a pool
        DeployConstantSum deployConstantSum = new DeployConstantSum();
        deployConstantSum.run(address(mockToken1), address(mockToken2));

        // Deploy a constant product factory, a hooks contract, and a pool
        DeployConstantProduct deployConstantProduct = new DeployConstantProduct();
        deployConstantProduct.run(address(mockToken1), address(mockToken2), address(mockVeBAL));
    }

    modifier export() {
        _;
        exportDeployments();
    }
}
