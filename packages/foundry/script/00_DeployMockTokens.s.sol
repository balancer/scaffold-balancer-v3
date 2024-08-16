//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import { MockVeBAL } from "../contracts/mocks/MockVeBAL.sol";

/**
 * @title Deploy Mock Tokens
 * @notice Deploys mock tokens for use with pools and hooks
 */
contract DeployMockTokens is ScaffoldHelpers {
    function run() external returns (IERC20 mockToken1, IERC20 mockToken2, IERC20 mockVeBAL) {
        uint256 deployerPrivateKey = getDeployerPrivateKey();

        vm.startBroadcast(deployerPrivateKey);

        // For use with pool contracts
        mockToken1 = new MockToken1("Mock Token 1", "MT1", 1000e18);
        mockToken2 = new MockToken2("Mock Token 2", "MT2", 1000e18);
        console.log("MockToken1 deployed at: %s", address(mockToken1));
        console.log("MockToken2 deployed at: %s", address(mockToken2));

        // For use with VeBALFeeDiscountHook
        mockVeBAL = new MockVeBAL("Vote-escrow BAL", "veBAL", 1000e18);
        console.log("Mock Vote-escrow BAL deployed at: %s", address(mockVeBAL));

        vm.stopBroadcast();
    }
}
