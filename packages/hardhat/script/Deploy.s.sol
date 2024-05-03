//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployCustomPoolFactoryAndNewPoolExample} from "./DeployCustomPoolFactoryAndNewPoolExample.s.sol";
import "./DeployHelpers.s.sol";

contract DeployScript is
    ScaffoldETHDeploy,
    DeployCustomPoolFactoryAndNewPoolExample
{
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);

        runDeployCustomPoolFactoryAndNewPoolExample();

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
