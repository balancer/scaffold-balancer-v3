// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { HelperConfig } from "./HelperConfig.sol";

/**
 * @title InitializePool Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script initializes a pool with the BalancerV3 Vault on sepolia
 */
contract InitializePool is HelperConfig, Script {
	function run() external {
		/// @dev adjust the args for registerPool before running this script
		address pool = address(0); // TODO - dev, populate with your custom pool address!
		IERC20[] memory tokens = new IERC20[](2); // Pool tokens (must be in same order as registration)
		tokens[0] = IERC20(sepoliaUSDC);
		tokens[1] = IERC20(sepoliaDAI);
		uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token registration order
		exactAmountsIn[0] = 11111;
		exactAmountsIn[1] = 22222;
		uint256 minBptAmountOut = 0; // Minimum amount of pool tokens to be received
		bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
		bytes memory userData = ""; // Additional (optional) data required for adding initial liquidity

		// initialize the pool
		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		router.initialize(
			pool,
			tokens,
			exactAmountsIn,
			minBptAmountOut,
			wethIsEth,
			userData
		);

		vm.stopBroadcast();
	}
}
