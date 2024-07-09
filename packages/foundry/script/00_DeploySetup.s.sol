//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { ConstantSumFactory } from "../contracts/pools/ConstantSumFactory.sol";
import { ConstantProductFactory } from "../contracts/pools/ConstantProductFactory.sol";
import { VeBALFeeDiscountHook } from "../contracts/hooks/VeBALFeeDiscountHook.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import { MockVeBAL } from "../contracts/mocks/MockVeBAL.sol";

/**
 * @title Deploy Setup
 * @notice Deploys mock tokens, factory contracts, and hooks contracts to be used by the pools
 * @dev Set the pauseWindowDuration for the factories below
 * @dev Run this script with `yarn deploy`
 */
contract DeploySetup is HelperConfig, ScaffoldETHDeploy {
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        uint32 pauseWindowDuration = 365 days;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the factory contracts
        ConstantSumFactory sumFactory = new ConstantSumFactory(IVault(vault), pauseWindowDuration);
        ConstantProductFactory productFactory = new ConstantProductFactory(IVault(vault), pauseWindowDuration);
        console.log("Constant Sum Factory deployed at: %s", address(sumFactory));
        console.log("Constant Product Factory deployed at: %s", address(productFactory));

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
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
