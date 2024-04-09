// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Script, console } from "forge-std/Script.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";

/**
 * @title Example Factory Deployment Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script deploys the custom pool factory.
 * @dev This is in the early WIP stage, so we are working with already deployed pools for now. See issue #21 & #23.
 * @dev See TODO below; make sure to rename and edit the `CustomPoolFactoryExample.sol` with your own pool type, respectively.
 */
contract DeployCustomPoolFactoryExample is TestAddresses, Script {

	function run() external {

		/// args for factory deployment
		uint256 pauseWindowDuration = 365 days; // NOTE: placeholder pauseWindowDuration var

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		/// Deploy CustomPoolFactory
		CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(vault, pauseWindowDuration); // TODO - replace with your own custom pool factory and respective constructor params.

		vm.stopBroadcast();
	}
}
