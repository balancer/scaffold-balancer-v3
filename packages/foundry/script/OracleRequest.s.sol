// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Oracle} from "../contracts/oracle/oracle.sol";

contract ChainLinkRequestSampleTest is Script {
    address CONSUMER = 0x881b5B0a3cCf156C891F324d7cd32C941eB61F84;
    Oracle oracle;
    string jobid = "1ae448079f7547cb8f3c46892f9276f6";
    address operator = 0xF74D7Ff8ba3358aAA53Ec868E2F5340E9737cbe2;
    address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    function run() public{
        vm.startBroadcast();
        oracle = Oracle(CONSUMER);

        oracle.requestDynamicFee(
            operator,
            jobid
        );
        vm.stopBroadcast();
    }
}