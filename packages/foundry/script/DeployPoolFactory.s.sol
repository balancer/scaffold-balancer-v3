// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
import "./DeployHelpers.s.sol";

/**
 * All Pools created by this factory will share the same Pause Window end time, after which both old and new Pools will not be pausable.
 * All pools are reversibly pausable until the pause window expires. Afterward, there is an additional buffer period, set to the same duration as the Vault's buffer period.
 * If a pool was paused, it will remain paused through this buffer period, and cannot be unpaused.
 * When the buffer period expires, it will unpause automatically, and remain permissionless forever after.
 *
 * @title DeployPoolFactory Script
 * @author BuidlGuidl Labs
 * @notice This script uses the PK specified in `.env`
 * @dev Deploys a new pool factory with the specified pause window duration
 */
contract DeployPoolFactory is HelperConfig, ScaffoldETHDeploy {
    function deployPoolFactory(
        uint256 pauseWindowDuration
    ) internal returns (address) {
        CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(
            vault, // address from HelperConfig.sol
            pauseWindowDuration
        );

        console.log(
            "Deployed Pool Factory Address: %s",
            address(customPoolFactory)
        );

        return address(customPoolFactory);
    }

    // Deploy only the pool factory with CLI command `yarn deploy:factory`
    function run() external virtual {
        // Factory deployment configurations
        uint256 pauseWindowDuration = 365 days; // replace with new value if needed

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployPoolFactory(pauseWindowDuration);

        vm.stopBroadcast();
    }
}
