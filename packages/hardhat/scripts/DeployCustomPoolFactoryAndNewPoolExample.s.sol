// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";
import {HelperFunctions} from "../test/utils/HelperFunctions.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";

/**
 * @title CreatePoolFromFactoryExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool.
 * @dev TODO - See issue #26 Questions specific to this solidity file.
 * @dev See TODO below; make sure to rename and edit the `CustomPoolFactoryExample.sol` with your own pool type, respectively.
 * @dev This script uses testERC20 contracts to instantly mint 1000 of each test token to deployer wallet.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFactoryAndNewPoolExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 */
contract DeployCustomPoolFactoryAndNewPoolExample is TestAddresses, HelperFunctions, Script {

	address devFrontEndAddress = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045; // TODO - dev, input your connected dev wallet address here. This address receives the BPT. The deployer wallet (default the `.env` DEPLOYER wallet you specify), sets everything up and sends its BPTs to this address.

	uint256 pauseWindowDuration = 365 days; // NOTE: placeholder pauseWindowDuration var

	// Vars
	address newPool;
	IERC20[] tokens = new IERC20[](2); // Tokens used to seed the pool (must match the registered tokens)
	uint256[] exactAmountsIn = new uint256[](2); // Tokens used to seed the pool (must match the registered tokens)
	uint256 internal minBptAmountOut;
	bytes userData;

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
		
		newPool = customPoolFactory.create(name, symbol, tokenConfig, salt);

		/// initialize pool tx - TODO - see issue #26 requesting clarification from blabs on factory pools rqing registeration or not. BUT until then, you need to write up the appropriate params to get this script to compile.
		
		tokens[0] = tokenConfig[0].token;
		tokens[1] = tokenConfig[1].token;
		
		exactAmountsIn[0] = 1 ether; // assume that scUSD and scDAI are pegged / same price (1 USD).
		exactAmountsIn[1] = 1 ether;
        minBptAmountOut = 1 ether; // TODO - debug this based on sim
		userData = bytes("");  // TODO - Additional (optional) data required for adding initial liquidity

		{
		/// Initialize Pool via Router
		// NOTE: Referencing the WeightedPool.t.sol setup with BaseVaultTest.sol, we can see that initialize() is called from the Router, enacting vault initialize() call. There are certain approvals that are required though, and this raises general questions about what dependencies we will need, and how this repo should support the public repo of dependencies once it is out. For now, it will just work with cherry-picked dependencies, but general reformatting will be needed to carry this the rest of the way to a final product after milestone 1.

		/// approvals: NOTE that balancer uses permit2, but their dependency doesn't work so I need to investigate this.

		approveForSender();// approve for sender
		approveForPool(IERC20(newPool));// approve for pool

		// // TODO - STEVE This is where you left off: look at BaseVaultTest.sol for approveForSender(), and approveForPool(). Then delete BaseVaultTest.sol
		uint256 bptOut = router.initialize(newPool, tokens, exactAmountsIn, minBptAmountOut, false, userData ); // Initializes a registered pool by adding liquidity; mints BPT tokens for the first time in exchange.

		console.log("BPTOut: %s", bptOut); // TODO - delete temporary console checking how much BPT was returned once we know it works.
		}

		vm.stopBroadcast();
	}

	function approveForSender() internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
			tokens[i].approve(address(router), type(uint256).max);
			tokens[i].approve(address(vault), type(uint256).max);
			// permit2.approve(address(tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
        }
    }

	function approveForPool(IERC20 bpt) internal {
		bpt.approve(address(router), type(uint256).max);
		bpt.approve(address(vault), type(uint256).max);
        // bpt.approve(address(batchRouter), type(uint256).max);
    }
}
