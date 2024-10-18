// // SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { GovernedLotteryHook } from "../contracts/hooks/GovernedLotteryHook.sol";

contract DeployGovernedLotteryHook is Script {
    function run() external {
        IVault vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        address trustedRouter = 0x886A3Ec7bcC508B8795990B60Fa21f85F9dB7948;
        vm.startBroadcast();
        GovernedLotteryHook lotteryHook = new GovernedLotteryHook(vault, trustedRouter);
        console.log("Governed Lottery Hook deployed at:", address(lotteryHook));

        vm.stopBroadcast();
    }
}
