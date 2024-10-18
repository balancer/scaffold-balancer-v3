//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockToken1} from "../src/mocks/MockToken1.sol";
import {MockToken2} from "../src/mocks/MockToken2.sol";
import {MockVeBAL} from "../src/mocks/MockVeBAL.sol";

import {HelperConfig} from "./HelperConfig.s.sol";

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title Deploy Mock Tokens
 * @notice Deploys mock tokens for use with pools and hooks
 */
contract DeployMockTokens is Script {
    HelperConfig helperConfig;

    function run() external {
        deployMockTokens();
    }

    function deployMockTokens()
        public
        returns (address mockToken1, address mockToken2, address mockVeBAL)
    {
        helperConfig = new HelperConfig();
        // Start creating the transactions
        address deployer = helperConfig.getConfig().account;
        console.log("Deployer: ", deployer);
        vm.startBroadcast(deployer);

        // Used to register & initialize pool contracts
        mockToken1 = address(new MockToken1("Test Token 1", "AI", 1000e18));
        mockToken2 = address(new MockToken2("Test Token 2", "AIS", 1000e18));
        console.log("MockToken1 deployed at: %s", mockToken1);
        console.log("MockToken2 deployed at: %s", mockToken2);

        // Used for the VeBALFeeDiscountHook
        mockVeBAL = address(new MockVeBAL("Vote-escrow BAL", "veBAL", 1000e18));
        console.log("Mock Vote-escrow BAL deployed at: %s", mockVeBAL);

        vm.stopBroadcast();
    }
}
