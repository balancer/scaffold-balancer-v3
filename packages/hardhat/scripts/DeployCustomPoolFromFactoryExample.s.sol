// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
// import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
// import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import { TestAddresses } from "../test/utils/TestAddresses.sol";
import { CustomPoolFactoryExample } from "../contracts/CustomPoolFactoryExample.sol";
import { FakeTestERC20 } from "../contracts/FakeTestERC20.sol";
import { HelperFunctions } from "../test/utils/HelperFunctions.sol";
// import { IRouter } from "../contracts/interfaces/IRouter.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";


/**
 * @title DeployCustomPoolFromFactoryExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script, using the `.env` specified deployer wallet, creates new pools from a pre-existing custom pool factory (adhering to the Constant Price Pool example by default). 
 * @dev You need to assign the appropriate custom pool factory address (and associated dependencies / params requirements). This script is to be used after DeployCustomPoolFactoryAndNewPoolExample.s.sol.  It does all of this so the new pool is ready to use with the ScaffoldBalancer front end tool.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFromFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 */
contract DeployCustomPoolFromFactoryExample is
	TestAddresses,
	HelperFunctions,
	Script
{
	// Vars
	address newPool;
	IERC20[] tokens = new IERC20[](2); // Tokens used to seed the pool (must match the registered tokens)
	uint256[] exactAmountsIn = new uint256[](2); // Tokens used to seed the pool (must match the registered tokens)
	uint256 internal minBptAmountOut;
	bytes userData;

	CustomPoolFactoryExample customPoolFactory = CustomPoolFactoryExample(0x9253c02B41b7e858726A9450ec3251CD55ea2bDA); // TODO - assign the customPoolFactory address. By default, with this repo & README, you can get the example customPoolFactory address by running the `DeployCustomPoolFactoryAndNewPoolExample.s.sol` script and reading the logs.

	function run() external {
		/// args for factory deployment

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		/// Vars specific to creating a pool from your custom pool factory on testnet.
		FakeTestERC20 scUSD = new FakeTestERC20(
			"Scaffold Balancer Test Token #1",
			"scUSD"
		); // This script uses FakeTestERC20 contracts to instantly mint 1000 of each test token to deployer wallet. 
		FakeTestERC20 scDAI = new FakeTestERC20(
			"Scaffold Balancer Test Token #2",
			"scDAI"
		);

		TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

		// make sure to have proper token order (alphanumeric)
		tokenConfig[1] = TokenConfig({
			token: IERC20(address(scDAI)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[0] = TokenConfig({
			token: IERC20(address(scUSD)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});

		string memory name = "Example Custom Balancer Constant Price Pool #2"; // TODO - Make sure to change the name to avoid collisions, this will occur if you run this script more than once without changing the name here.

		string memory symbol = "cBPT1";
		bytes32 salt = convertNameToBytes32(name);

		newPool = customPoolFactory.create(name, symbol, tokenConfig, salt);

		tokens[0] = tokenConfig[0].token;
		tokens[1] = tokenConfig[1].token;
		exactAmountsIn[0] = 1 ether; // assume that scUSD and scDAI are pegged / same price (1 USD).
		exactAmountsIn[1] = 1 ether;
		minBptAmountOut = 1 ether; // TODO - debug this based on sim
		userData = bytes(""); // TODO - Additional (optional) data required for adding initial liquidity

		{
			/// Initialize Pool via Router
			approveForSender(); 
			approveForPool(IERC20(newPool));

			router.initialize(
				newPool,
				tokens,
				exactAmountsIn,
				minBptAmountOut,
				false,
				userData
			); // Initializes a registered pool by adding liquidity; mints BPT tokens for the first time in exchange.
		}

		vm.stopBroadcast();
	}

	function approveForSender() internal {
		for (uint256 i = 0; i < tokens.length; ++i) {
			tokens[i].approve(address(router), type(uint256).max);
			tokens[i].approve(address(vault), type(uint256).max);
		}
	}

	function approveForPool(IERC20 bpt) internal {
		bpt.approve(address(router), type(uint256).max);
		bpt.approve(address(vault), type(uint256).max);
	}
}
