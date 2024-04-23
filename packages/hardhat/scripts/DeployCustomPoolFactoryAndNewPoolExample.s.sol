// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";
import {HelperFunctions} from "../test/utils/HelperFunctions.sol";

/**
 * @title CreatePoolFromFactoryExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool.
 * @dev TODO - See issue #26 Questions specific to this solidity file.
 * @dev See TODO below; make sure to rename and edit the `CustomPoolFactoryExample.sol` with your own pool type, respectively.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFactoryAndNewPoolExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 * @dev This script uses testERC20 contracts to instantly mint 1000 of each test token to deployer wallet.
 */
contract DeployCustomPoolFactoryAndNewPoolExample is TestAddresses, HelperFunctions, Script {

	address devFrontEndAddress = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045; // TODO - dev, input your connected dev wallet address here. This address receives the BPT. The deployer wallet (default the `.env` DEPLOYER wallet you specify), sets everything up and sends its BPTs to this address.

	uint256 pauseWindowDuration = 365 days; // NOTE: placeholder pauseWindowDuration var

	function run() external {
		
		/// args for factory deployment

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		/// Deploy CustomPoolFactory
		CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(vault, pauseWindowDuration); // TODO - replace with your own custom pool factory and respective constructor params.
		
		/// Vars specific to creating a pool from your custom pool factory on testnet. 

		FakeTestERC20 scUSD = new FakeTestERC20("Scaffold Balancer Test Token #1","scUSD");
		FakeTestERC20 scDAI = new FakeTestERC20("Scaffold Balancer Test Token #2","scDAI");

		TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

		// make sure to have proper token order (alphanumeric)
		tokenConfig[0] = TokenConfig({
			token: IERC20(address(scDAI)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(address(scUSD)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});

		string memory name = "Example Custom Balancer Constant Price Pool #1";
		string memory symbol = "cBPT1";
		bytes32 salt = convertNameToBytes32(name);
		
		address newPool = customPoolFactory.create(name, symbol, tokenConfig, salt);

		// /// initialize pool tx - TODO - see issue #26 requesting clarification from blabs on factory pools rqing registeration or not. BUT until then, you need to write up the appropriate params to get this script to compile.
		
        // IERC20[] memory tokens; // Tokens used to seed the pool (must match the registered tokens)
		// tokens[0] = IERC20(address(scUSD));
		// tokens[1] = IERC20(address(scDAIToken));

		// uint256[] memory exactAmountsIn; 
		// exactAmountsIn[0] = 1 ether; // assume that scUSD and scDAI are pegged / same price (1 USD).
		// exactAmountsIn[1] = 1 ether;
        // uint256 minBptAmountOut = 1 ether; // TODO - debug this based on sim
		// bytes memory userData = bytes("");  // TODO - Additional (optional) data required for adding initial liquidity

		// {
		// uint256 bptOut = vault.initialize(newPool, devFrontEndAddress, tokens, exactAmountsIn, minBptAmountOut, userData); // Initializes a registered pool by adding liquidity; mints BPT tokens for the first time in exchange.

		// console.log("BPTOut: %s", bptOut); // TODO - delete temporary console checking how much BPT was returned once we know it works.
		// }

		vm.stopBroadcast();
	}
}
