//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { console } from "forge-std/Test.sol";
import { BaseVaultTest } from "@test/vault/test/foundry/utils/BaseVaultTest.sol";
import { ConstantPricePool } from "../contracts/ConstantPricePool.sol";
import { CustomPoolFactoryExample } from "../contracts/CustomPoolFactoryExample.sol";
import { LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType } from "../contracts/interfaces/VaultTypes.sol";
import { IERC20 } from "../contracts/interfaces/IVaultExtension.sol";
// import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol"; TODO We can use these imports now?
import { IVault } from "../contracts/interfaces/IVault.sol";

/**
 * @title Template Custom Pool Test
 * @author BUIDL GUIDL (placeholder)
 * @notice This test file serves as an example of some areas one needs to focus on when writing their own custom BalancerV3 pool. This is not production ready, and it is the developers responsibility to carry out proper testing and auditing for their pool.
 * @dev This test is written for the Constant Price Custom Pool. Developers may duplicate this as a starting template for their own custom pool test file. 
 * When creating your own custom pool, developers are expected to: create their own custom pool file, test file, script file. They simply can just duplicate or override the files that are here marked as "example" within their title.
 */
contract ConstantPricePoolTest is  BaseVaultTest {
	uint256 constant DEFAULT_SWAP_FEE = 1e16; // 1%
	CustomPoolFactoryExample factory;
	ConstantPricePool internal constantPricePool;
	/**
	 * Test setup includes:
	 * 1. 
	 */
	function setUp() public virtual override {
        BaseVaultTest.setUp();
    }

	function createPool() internal override returns (address) {
		console.log("Bonjour");
        factory = new CustomPoolFactoryExample(IVault(address(vault)), 365 days);
        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[1].token = IERC20(dai);
        tokens[0].token = IERC20(usdc);

        constantPricePool = ConstantPricePool(
            factory.create(
                "ERC20 Pool",
                "ERC20POOL",
                tokens,
                keccak256(abi.encode("TEST"))
            )
        );
        return address(constantPricePool);
    }

	function testFoundryTesting() public {
		assertTrue(
			true,
			"Should we build with hardhat or foundry? Por que no los dos!"
		);
	}
}
