// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IVaultExtension, IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";

/**
 * Register an already deployed pool on sepolia
 *
 * balancer docs
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#registerpool
 *
 * registerPool function
 * https://github.com/balancer/balancer-v3-monorepo/blob/2ad8501c85e8afb2f25d970344af700a571b1d0b/pkg/vault/contracts/VaultExtension.sol#L130-L149
 *
 * VaultTypes (TokenType, TokenConfig, IRateProvider)
 * https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/interfaces/contracts/vault/VaultTypes.sol
 */
contract RegisterPool is Script {
	IVaultExtension constant vaultExtension =
		IVaultExtension(0x718e1176f01dDBb2409A77B2847B749c8dF4457f);

	address sepoliaDAI = 0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613;
	address sepoliaUSDC = 0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A;

	function run() external {
		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		/////////////////////////////
		// args for registerPool  //
		//////////////////////////
		// 1. Address of pool to register
		address pool = 0x37495BE0Af7B427Ddb9C504cE53617F9F04620aD;
		// 2. An array of descriptors for the tokens the pool will manage.
		TokenConfig[] memory tokenConfig = new TokenConfig[](2);
		tokenConfig[0] = TokenConfig({
			token: IERC20(sepoliaDAI),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(sepoliaUSDC),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(address(0)),
			yieldFeeExempt: false
		});
		// 3. The timestamp after which it is no longer possible to pause the pool
		uint256 pauseWindowEndTime = 0;
		// 4. Optional contract the Vault will allow to pause the pool
		address pauseManager = address(0);
		// 5. Flags indicating which hooks the pool supports
		PoolHooks memory hookConfig = PoolHooks({
			shouldCallBeforeInitialize: false,
			shouldCallAfterInitialize: false,
			shouldCallBeforeSwap: false,
			shouldCallAfterSwap: false,
			shouldCallBeforeAddLiquidity: false,
			shouldCallAfterAddLiquidity: false,
			shouldCallBeforeRemoveLiquidity: false,
			shouldCallAfterRemoveLiquidity: false
		});
		// 6. Liquidity management flags with implemented methods
		LiquidityManagement memory liquidityManagement = LiquidityManagement({
			supportsAddLiquidityCustom: false,
			supportsRemoveLiquidityCustom: false
		});

		////////////////////////
		// send register tx  //
		//////////////////////
		vaultExtension.registerPool(
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
