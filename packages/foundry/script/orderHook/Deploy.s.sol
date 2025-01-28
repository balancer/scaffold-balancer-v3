//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DeployMockTokens} from "./00-DeployMockTokens.s.sol";
import {DeployConstantSumPool} from "./01-DeployConstantSumPool.s.sol";
import {DeployConstantProductPool} from "./02-DeployConstantProductPool.s.sol";
import {DeployWeightedPool8020} from "./03-DeployWeightedPool8020 .s.sol";

import {Script} from "forge-std/Script.sol";

/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with nextjs front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is Script {
    function run() external {
        DeployMockTokens deployTokens = new DeployMockTokens();
        DeployConstantSumPool deployConstantSumPool = new DeployConstantSumPool();
        DeployConstantProductPool deployConstantProductPool = new DeployConstantProductPool();
        //DeployWeightedPool8020 deployWeightedPool8020 = new DeployWeightedPool8020();

        // Deploy mock tokens to use for the pools and hooks
        (address mockToken1, address mockToken2, ) = deployTokens
            .deployMockTokens();

        // Deploy, register, and initialize a constant sum pool with a swap fee discount hook
        deployConstantSumPool.deployConstantSumPool(mockToken1, mockToken2);

        // Deploy, register, and initialize a constant product pool with a lottery hook
        deployConstantProductPool.deployConstantProductPool(
            mockToken1,
            mockToken2
        );

        // Deploy, register, and initialize a weighted pool with an exit fee hook
        //deployWeightedPool8020.deployWeightedPool8020(mockToken1, mockToken2);
    }
}
