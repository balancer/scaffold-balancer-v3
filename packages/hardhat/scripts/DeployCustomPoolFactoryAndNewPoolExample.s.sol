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
 * @title CreatePoolFromFactoryExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool.
 * @dev TODO - See issue #26 Questions specific to this solidity file.
 * @dev See TODO below; make sure to rename and edit the `CustomPoolFactoryExample.sol` with your own pool type, respectively.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFactoryAndNewPoolExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 */
contract DeployCustomPoolFactoryAndNewPoolExample is TestAddresses, HelperFunctions, Script {

	function run() external {

		CustomPoolFactoryExample customPoolFactory = CustomPoolFactoryExample(address(1)); // TODO - replace with actual custom pool factory address
		
		address frontEndAddress; // TODO - dev, input your connected dev wallet address here. This address, as long as it lines up with your .env setup, will be the wallet that receives BPT. The deployer address will have the seed liquidity but the BPT will be sent to this wallet.
		
		/// args for factory deployment
		uint256 pauseWindowDuration = 365 days; // NOTE: placeholder pauseWindowDuration var

		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		/// Deploy CustomPoolFactory
		CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(vault, pauseWindowDuration); // TODO - replace with your own custom pool factory and respective constructor params.
		
		/// Vars specific to creating a pool from your custom pool factory on testnet. 

		ScaffoldBalancerToken scbalToken = new ScaffoldBalancerToken("Scaffold Balancer Test Token #1","scBAL"); // the ScaffoldBalancer ($scBAL) ERC20 token used for these examples. NOTE - 1000 $scBAL is minted to the msg.sender deploying the contract. 

		ScaffoldBalancerToken scETHToken = new ScaffoldBalancerToken("Scaffold Balancer Test Token #2","scETH"); // the ScaffoldBalancer ($scETH) ERC20 token used for these examples. NOTE - 1000 $scETH is minted to the msg.sender deploying the contract. 

		TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

		// make sure to have proper token order (alphanumeric)
		tokenConfig[0] = TokenConfig({
			token: IERC20(address(scbalToken)),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(address(scETHToken)),
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

		/// initialize pool tx - TODO - see issue #26 requesting clarification from blabs on factory pools rqing registeration or not. BUT until then, you need to write up the appropriate params to get this script to compile.
		
        IERC20[] memory tokens; // Tokens used to seed the pool (must match the registered tokens)
		tokens[0] = IERC20(address(scbalToken));
		tokens[1] = IERC20(address(scETHToken));

		uint256[] exactAmountsIn; 
		exactAmountsIn(0) = 1 ether; // assume that scBAL and scETH are the same price. Bullish on BAL!
		exactAmountsIn(1) = 1 ether;
        uint256 minBptAmountOut = 1 ether; // TODO - debug this based on sim
		bytes memory userData = bytes("");  // TODO - Additional (optional) data required for adding initial liquidity
		
		uint256 bptOut = vault.initialize(newPool, frontEndAddress, tokens, exactAmountsIn, minBptAmountOut, userData); // Initializes a registered pool by adding liquidity; mints BPT tokens for the first time in exchange.

		console.log("BPTOut: %s", bptOut); // TODO - delete temporary console checking how much BPT was returned once we know it works.

		vm.stopBroadcast();
	}
}
