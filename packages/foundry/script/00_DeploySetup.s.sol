//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { PoolHelpers } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { ConstantSumFactory } from "../contracts/pools/ConstantSumFactory.sol";
import { ConstantProductFactory } from "../contracts/pools/ConstantProductFactory.sol";
import { ExponentialProductFactory } from "../contracts/pools/ExponentialProductFactory.sol";
import { VeBALFeeDiscountHook } from "../contracts/hooks/VeBALFeeDiscountHook.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import { MockVeBAL } from "../contracts/mocks/MockVeBAL.sol";

/**
 * @title Deploy Setup
 * @notice Deploys mock tokens, factory contracts, and hooks contracts to be used by the pools
 * @dev This script runs as part of `yarn deploy`, but can also be run discretely with `yarn deploy:setup`
 * @dev Set the pauseWindowDuration for the factory contracts below
 */
contract DeploySetup is PoolHelpers, ScaffoldHelpers {
    function run() external virtual {
        uint256 deployerPrivateKey = getDeployerPrivateKey();

        uint32 pauseWindowDuration = 365 days; // The period during which pools can be paused and unpaused ( starting from deployment of the factory )

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the factory contracts
        ConstantSumFactory sumFactory = new ConstantSumFactory(IVault(vault), pauseWindowDuration);
        ConstantProductFactory productFactory = new ConstantProductFactory(IVault(vault), pauseWindowDuration);
        ExponentialProductFactory expProductFactory = new ExponentialProductFactory(IVault(vault), pauseWindowDuration);
        console.log("Constant Sum Factory deployed at: %s", address(sumFactory));
        console.log("Constant Product Factory deployed at: %s", address(productFactory));
        console.log("Exponential Product Factory deployed at: %s", address(expProductFactory));

        // Deploy mock tokens
        IERC20 token1 = new MockToken1("Mock Token 1", "MT1", 1000e18);
        IERC20 token2 = new MockToken2("Mock Token 2", "MT2", 1000e18);
        IERC20 veBAL = new MockVeBAL("Vote-escrow BAL", "veBAL", 1000e18);
        console.log("MockToken1 deployed at: %s", address(token1));
        console.log("MockToken2 deployed at: %s", address(token2));
        console.log("Mock Vote-escrow BAL deployed at: %s", address(veBAL));

        // Deploy a hooks contract for the Constant Product Factory
        VeBALFeeDiscountHook poolHooksContract = new VeBALFeeDiscountHook(
            IVault(vault),
            address(productFactory),
            address(veBAL),
            address(router)
        );
        console.log("VeBALFeeDiscountHook deployed at address: %s", address(poolHooksContract));

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions that are carried from /foundry to /nextjs.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
