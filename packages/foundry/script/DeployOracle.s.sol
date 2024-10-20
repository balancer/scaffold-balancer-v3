// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ScaffoldHelpers} from "./ScaffoldHelpers.sol";
import {Oracle} from "../contracts/oracle/oracle.sol";

contract DeployChainLinkOr is ScaffoldHelpers {
    function run() public returns (address) {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);
        Oracle consumer = new Oracle();
        vm.stopBroadcast();

        return address(consumer);
    }
}