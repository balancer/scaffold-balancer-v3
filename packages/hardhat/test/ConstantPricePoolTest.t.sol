//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Test, console } from "forge-std/Test.sol";
import { ConstantPricePool } from "../contracts/ConstantPricePool.sol";

contract ConstantPricePoolTest is Test {
	function setUp() external {}

	function testFoundryTesting() public pure {
		assertTrue(
			true,
			"Should we build with hardhat or foundry? Por que no los dos!"
		);
	}
}
