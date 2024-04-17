// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
// import {TestAddresses} from  "packages/hardhat/test/utils/TestAddresses.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {ScaffoldBalancerToken} from "packages/hardhat/contracts/ScaffoldBalancerToken.sol";
import {HelperFunctions} from "packages/hardhat/test/utils/HelperFunctions.sol";


/**
 * TODO - this was copied from register pool script, needs to be rewritten to create a pool from a factory address.
 * @title CreatePoolFromFactoryExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script deploys a custom pool (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool.
 * @dev Make sure to get the address of the CustomPoolFactoryExample after having had run `DeployCustomPoolFactoryExample.s.sol` before running this script.
 */
contract CreatePoolFromFactoryExample is TestAddresses, HelperFunctions, Script {

	function run() external {

		CustomPoolFactoryExample customPoolFactory = CustomPoolFactoryExample(address(1)); // TODO - replace with actual custom pool factory address

		/// Vars specific to local mainnet fork deployment (mainnet deployment)

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

		vm.startBroadcast(deployerPrivateKey);
		
		/// setup the params needed to create the first pool from the factory.

		/// Vars specific to creating a pool from your custom pool factory on testnet. 

		ScaffoldBalancerToken scbalToken = new ScaffoldBalancerToken("Scaffold Balancer Test Token #1","scBAL"); // the ScaffoldBalancer ($scBAL) ERC20 token used for these examples. NOTE - 1000 $scBAL is minted to the msg.sender deploying the contract. 

		ScaffoldBalancerToken scETHToken = new ScaffoldBalancerToken("Scaffold Balancer Test Token #2","scETH"); // the ScaffoldBalancer ($scETH) ERC20 token used for these examples. NOTE - 1000 $scETH is minted to the msg.sender deploying the contract. 

		// // TODO - delete if you don't need these as ERC20s explicitly.
		// ERC20 scBAL = ERC20(address(scbalToken));
		// ERC20 scETH = ERC20(address(scETH));

		TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

		// make sure to have proper token order (alphanumeric)
		tokenConfig[0] = TokenConfig({
			token: IERC20(address(scbalToken)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(scETHToken),
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

		string name = "Example Custom Balancer Constant Price Pool #1";
		string symbol = "cBPT1";
		bytes32 salt = converNamesToBytes32(name);
		
		address newPool = customPoolFactory.createPool(name, symbol, tokenConfig, salt);

		/// send register tx 
		vault.registerPool(
			newPool,
			tokenConfig,
			pauseWindowEndTime,
			pauseManager,
			hookConfig,
			liquidityManagement
		);

		/// initialize pool tx - TODO - STEVE THIS IS WHERE YOU LEFT OFF, check vault contract again if you need to initialize, and also check first that you even need to register still if you have created a factory and pools are created through that. 

		vm.stopBroadcast();
	}
}
