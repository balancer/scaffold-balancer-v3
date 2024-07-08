//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { ConstantSumFactory } from "../contracts/ConstantSumFactory.sol";
import { VeBALFeeDiscountHook } from "../contracts/VeBALFeeDiscountHook.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import { MockVeBAL } from "../contracts/mocks/MockVeBAL.sol";

/**
 * @title Deploy Constant Sum Factory
 * @notice Deploys mock tokens, a factory contract and a hook contract
 * @dev Set the factory pauseWindowDuration in `HelperConfig.sol`
 * @dev Run this script with `yarn deploy:factory`
 */
contract DeployConstantSumFactory is HelperConfig, ScaffoldETHDeploy {
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        uint32 pauseWindowDuration = getFactoryConfig();

        vm.startBroadcast(deployerPrivateKey);

        // Deploy factory contract
        ConstantSumFactory factory = new ConstantSumFactory(vault, pauseWindowDuration);
        console.log("Deployed Factory Address: %s", address(factory));

        // Deploy mock tokens
        MockToken1 token1 = new MockToken1("Mock Token 1", "MT1", 1000e18);
        MockToken2 token2 = new MockToken2("Mock Token 2", "MT2", 1000e18);
        MockVeBAL veBAL = new MockVeBAL("Vote-escrow BAL", "veBAL", 1000e18);
        console.log("Deployed MockToken1 Address: %s", address(token1));
        console.log("Deployed MockToken2 Address: %s", address(token2));
        console.log("Deployed Vote-escrow BAL Address: %s", address(veBAL));

        // Deploy hooks contract
        new VeBALFeeDiscountHook(vault, address(factory), address(veBAL), address(router));

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
