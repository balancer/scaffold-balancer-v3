// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
// import {TestAddresses} from  "packages/hardhat/test/utils/TestAddresses.sol";

/**
 * @title RegisterPool Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script registers a pool with the BalancerV3 Vault on sepolia 
 * @dev This is in the early WIP stage, so we are working with already deployed pools for now. See PR#13 for context on related docs, code blobs, etc.
 */
contract RegisterPool is TestAddresses, Script {

	/// @dev See TODO below; make sure to populate `address pool` below with your custom pool address.
	function run() external {

		/// args for registerPool
		address pool = address(0); // TODO - dev, populate with your custom pool address!

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

		// make sure to have proper token order (alphanumeric)
		tokenConfig[0] = TokenConfig({
			token: IERC20(sepoliaUSDC),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(sepoliaDAI),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		uint256 pauseWindowEndTime = 0; // The timestamp after which it is no longer possible to pause the pool

		address pauseManager = address(0); // Optional contract the Vault will allow to pause the pool

		PoolHooks memory hookConfig = PoolHooks({
			shouldCallBeforeInitialize: false,
			shouldCallAfterInitialize: false,
			shouldCallBeforeSwap: false,
			shouldCallAfterSwap: false,
			shouldCallBeforeAddLiquidity: false,
			shouldCallAfterAddLiquidity: false,
			shouldCallBeforeRemoveLiquidity: false,
			shouldCallAfterRemoveLiquidity: false
		}); // Flags indicating which hooks the pool supports

		LiquidityManagement memory liquidityManagement = LiquidityManagement({
			supportsAddLiquidityCustom: false,
			supportsRemoveLiquidityCustom: false
		}); // Liquidity management flags with implemented methods

		/// send register tx 
		vault.registerPool(
			pool,
			tokenConfig,
			pauseWindowEndTime,
			pauseManager,
			hookConfig,
			liquidityManagement
		);

		vm.stopBroadcast();
	}
}
