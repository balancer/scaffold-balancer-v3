//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { MockToken1 } from "../contracts/MockToken1.sol";
import { MockToken2 } from "../contracts/MockToken2.sol";

/**
 * @title Deploy Mock Tokens
 * @dev run this script with `yarn deploy:tokens`
 */
contract DeployMockTokens is ScaffoldETHDeploy {
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        vm.startBroadcast(deployerPrivateKey);
        MockToken1 scUSD = new MockToken1("Scaffold USD", "scUSD");
        MockToken2 scDAI = new MockToken2("Scaffold DAI", "scDAI");
        console.log("Deployed MockToken1 Address: %s", address(scUSD));
        console.log("Deployed MockToken2 Address: %s", address(scDAI));
        vm.stopBroadcast();

        // TODO: figure out how to carry contract info from foundry to nextjs for more than a single deploy script
        // /**
        //  * This function generates the file containing the contracts Abi definitions.
        //  * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
        //  * This function should be called last.
        //  */
        // exportDeployments();
    }
}
