// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;


import {Test} from "forge-std/Test.sol";
import {ATestnetConsumer} from "../contracts/hooks/ChainLinkRequestSample.sol";
import {console} from "forge-std/console.sol";
contract ChainLinkRequestSampleTest is Test {
    address ORACLE = 0x10BEBB7b2D4fd70B95af21DF0F5FEc7b551b706a;
    ATestnetConsumer consumer;
    string jobid = "07ae4cffe6794533bcdad0ecec26f039";
    address oracle = 0xD2e4d744c5dECC4Dbb0994bFc220Fe059237A177;
    uint256 forkId;
    address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    function setUp() public{
        string memory rpc = vm.rpcUrl("sepolia");
        forkId = vm.createFork(rpc);
        vm.selectFork(forkId);
        consumer  = ATestnetConsumer(ORACLE);
    }

    function testCall() public {
        vm.selectFork(forkId);
        // vm.startPrank();
        deal(LINK,ORACLE,100*1e18);
        consumer.requestPoolName(
            oracle,
            jobid
        );
        string memory poolName = consumer.poolName();
        assertEq(poolName,"50");
        console.log(poolName);
        // vm.stopPrank();
    }

}