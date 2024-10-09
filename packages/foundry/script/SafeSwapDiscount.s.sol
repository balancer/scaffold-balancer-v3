// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { SwapDiscountHook } from "../contracts/hooks/SwapDiscountHook.sol";

contract DeploySwapDiscountHook is Script {
    IVault internal vault;
    address internal allowedFactory;
    address internal trustedRouter;
    address internal discountToken;
    uint64 internal hookSwapDiscountPercentage; // Discount percentage
    uint256 internal requiredBalance; // Required balance for discount eligibility

    function run() external {
        // Set the addresses and parameters
        vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8); // Replace with actual vault address
        allowedFactory = 0xed52D8E202401645eDAD1c0AA21e872498ce47D0; // Replace with actual factory address
        trustedRouter = 0x886A3Ec7bcC508B8795990B60Fa21f85F9dB7948; // Replace with actual router address
        discountToken = 0xba100000625a3754423978a60c9317c58a424e3D; // Replace with actual discount token address
        hookSwapDiscountPercentage = 50e16; // 50% discount
        requiredBalance = 100e18; // 100 of the discount token required for eligibility

        // Start the deployment process
        vm.startBroadcast();

        // Deploy the SwapDiscountHook contract
        SwapDiscountHook swapDiscountHook = new SwapDiscountHook(
            vault,
            allowedFactory,
            trustedRouter,
            discountToken,
            hookSwapDiscountPercentage,
            requiredBalance
        );

        // Label the deployed contract for easier identification
        vm.label(address(swapDiscountHook), "Swap Discount Hook");

        // End the deployment process
        vm.stopBroadcast();

        // Output the deployed contract address
        console.log("SwapDiscountHook deployed at:", address(swapDiscountHook));
    }
}
