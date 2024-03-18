// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Script, console } from "forge-std/Script.sol";
import { IVaultExtension, TokenConfig, TokenType, IERC20, IRateProvider } from "../contracts/interfaces/IVaultExtension.sol";

/**
 * Register an already deployed pool on sepolia
 * @dev need to figure out TokenConfig's IRateProvider. Is it a seperate contract that we need to deploy first?
 *
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#registerpool
 * https://github.com/balancer/balancer-v3-monorepo/blob/ad6e2f7ad2fc0b54ff7eb5d704d6635a1ccc093b/pkg/interfaces/contracts/vault/IVaultExtension.sol#L58-L90
 */
contract RegisterPool is Script {
	IVaultExtension constant vaultExtension =
		IVaultExtension(0x718e1176f01dDBb2409A77B2847B749c8dF4457f);

	address sepoliaDAI = 0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613;
	address sepoliaUSDC = 0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A;

	function run() external {
		uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		// args for registerPool()
		address pool = 0x37495BE0Af7B427Ddb9C504cE53617F9F04620aD;
		TokenConfig[] memory tokenConfig = new TokenConfig[](2);
		tokenConfig[0] = TokenConfig({
			token: IERC20(sepoliaDAI),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(0x0000000000000000000000000000),
			yieldFeeExempt: false
		});
		tokenConfig[1] = TokenConfig({
			token: IERC20(sepoliaUSDC),
			tokenType: TokenType.STANDARD,
			rateProvider: IRateProvider(0x0000000000000000000000000000),
			yieldFeeExempt: false
		});

		// register the pool with the vault
		// vaultExtension.registerPool()

		vm.stopBroadcast();
	}
}
