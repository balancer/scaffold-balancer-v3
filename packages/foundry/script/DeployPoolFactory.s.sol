// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployPoolFactory Script
 * @author BuidlGuidl Labs
 * @notice This script uses the PK specified in `.env` to deploy a new pool factory
 * @notice This script is inhereted by Deploy.s.sol but can also be run directly with `yarn deploy:factory`
 * @dev if running directly, set the pool deployment and initialization configurations in the `run()` function below
 */
contract DeployPoolFactory is HelperConfig, Script {
    /**
     * All Pools created by this factory will share the same Pause Window end time, after which both old and new Pools will not be pausable.
     * All pools are reversibly pausable until the pause window expires. Afterward, there is an additional buffer period, set to the same duration as the Vault's buffer period.
     * If a pool was paused, it will remain paused through this buffer period, and cannot be unpaused.
     * When the buffer period expires, it will unpause automatically, and remain permissionless forever after.
     * @param pauseWindowDuration the duration of the pause window
     */
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

    /**
     * @dev Deploy only the pool factory with CLI command `yarn deploy:pool`
     * @dev Set the pauseWindowDuration for your pool factory below
     */
    function run() external virtual {
        // Factory deployment configurations
        uint256 pauseWindowDuration = 365 days; // replace with new value if needed

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployPoolFactory(pauseWindowDuration);

        vm.stopBroadcast();
    }
}
