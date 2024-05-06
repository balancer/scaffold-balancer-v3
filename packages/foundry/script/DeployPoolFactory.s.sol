// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {IVault} from "../contracts/interfaces/IVault.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployPoolFactory Script
 * @author BuidlGuidl Labs
 * @notice This script uses the PK specified in `.env` to deploy a new pool factory
 * @notice This script can be run directly with `yarn deploy:factory`
 * @dev if running directly, set the pool deployment and initialization configurations in the `run()` function below
 */
contract DeployPoolFactory is HelperConfig, Script {
    function deployPoolFactory(
        uint256 pauseWindowDuration
    ) internal returns (address) {
        CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(
            vault, // from HelperConfig
            pauseWindowDuration
        );

        console.log(
            "Deployed Pool Factory Address: %s",
            address(customPoolFactory)
        );

        return address(customPoolFactory);
    }

    /**
     * @dev Set your factory deployment onfiguration in `HelperConfig.s.sol`
     * @dev Deploy only the factory contract with the CLI command `yarn deploy:factory`
     */
    function run() external virtual {
        // Grab the pause window duration from HelperConfig
        HelperConfig helperConfig = new HelperConfig();
        uint256 pauseWindowDuration = helperConfig.getFactoryConfig();

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployPoolFactory(pauseWindowDuration);

        vm.stopBroadcast();
    }
}
