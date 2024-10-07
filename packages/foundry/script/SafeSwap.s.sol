// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "../lib/forge-std/src/Script.sol";
import { ConstantProductPool } from "../src/ConstantProductPool.sol";
import { IVault } from "../balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVault.sol";

contract SafeSwap is Script {
    ConstantProductPool public constantProductPool;

    address public vaultAddress = "0x7966FE92C59295EcE7FB5D9EfDB271967BFe2fbA";
    string public poolName = "MyConstantProductPool";
    string public poolSymbol = "MCP";

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        constantProductPool = new ConstantProductPool(IVault(vaultAddress), poolName, poolSymbol);

        vm.stopBroadcast();
    }
}

//forge script script/ConstantProductPool.s.sol --rpc-url https://sepolia.infura.io/v3/2de477c3b1b74816ae5475da6d289208 --private-key f46e7f0936b479bba879c9f764259d1e5838aa015232f0018a1c07214e491812
