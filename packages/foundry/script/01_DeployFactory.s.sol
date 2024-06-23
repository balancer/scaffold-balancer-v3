//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { HelperConfig } from "../utils/HelperConfig.sol";
import { MockToken1 } from "../contracts/MockToken1.sol";
import { MockToken2 } from "../contracts/MockToken2.sol";

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
        /**
         * @notice Deploy mock tokens to be used for initializing pools
         * @dev remove this if you plan to use already deployed tokens
         */
        MockToken1 scUSD = new MockToken1("Scaffold USD", "scUSD");
        MockToken2 scDAI = new MockToken2("Scaffold DAI", "scDAI");
        console.log("Deployed MockToken1 Address: %s", address(scUSD));
        console.log("Deployed MockToken2 Address: %s", address(scDAI));

        /**
         * @notice Deploys the factory contract using the pauseWindowDuration set in `HelperConfig.sol`
         */
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
