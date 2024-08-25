//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { PoolHelpers } from "./PoolHelpers.sol";
import { VeBALFeeDiscountHook } from "../contracts/hooks/VeBALFeeDiscountHook.sol";
import { ConstantProductFactory } from "../contracts/factories/ConstantProductFactory.sol";

/**
 * @dev Deploys pool hooks contracts to be used when registering pools
 * @notice Only pools deployed by the factory specified in hooks constructor are allowed to register with the hook
 */
contract DeployPoolHooks is ScaffoldHelpers, PoolHelpers {
    function run(address constantProductFactory, address mockVeBAL) external returns (address veBalFeeDiscountHook) {
        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy veBAL fee discount hook
        veBalFeeDiscountHook = address(
            new VeBALFeeDiscountHook(vault, constantProductFactory, address(router), mockVeBAL)
        );
        console.log("VeBALFeeDiscountHook deployed at address: %s", veBalFeeDiscountHook);

        vm.stopBroadcast();
    }
}
