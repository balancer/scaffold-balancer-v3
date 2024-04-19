//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Test, console } from "forge-std/Test.sol";
import { ConstantPricePool } from "../contracts/ConstantPricePool.sol";

/**
 * @title Template Custom Pool Test
 * @author BUIDL GUIDL (placeholder)
 * @notice This test file serves as an example of some areas one needs to focus on when writing their own custom BalancerV3 pool. This is not production ready, and it is the developers responsibility to carry out proper testing and auditing for their pool.
 * @dev This test is written for the Constant Price Custom Pool. Developers may duplicate this as a starting template for their own custom pool test file. 
 * When creating your own custom pool, developers are expected to: create their own custom pool file, test file, script file. They simply can just duplicate or override the files that are here marked as "example" within their title.
 */
contract ConstantPricePoolTest is Test {
	
	/**
	 * Test setup includes:
	 * 1. 
	 */
	function setUp() external {

	}

	function testFoundryTesting() public {
		assertTrue(
			true,
			"Should we build with hardhat or foundry? Por que no los dos!"
		);
	}

	
	
}
