//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { HelperConfig } from "../utils/HelperConfig.sol";

/**
 * @title Deploy Factory
 * @dev Set the factory pauseWindowDuration in `HelperConfig.sol`
 * @dev Run this script with `yarn deploy:factory`
 */
contract DeployFactory is HelperConfig, ScaffoldETHDeploy {
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        uint32 pauseWindowDuration = getFactoryConfig();
        vm.startBroadcast(deployerPrivateKey);
        ConstantSumFactory factory = new ConstantSumFactory(vault, pauseWindowDuration);
        console.log("Deployed Factory Address: %s", address(factory));
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
