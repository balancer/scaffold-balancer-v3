// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ATestnetConsumer} from "../contracts/hooks/ChainLinkRequestSample.sol";
import {ScaffoldHelpers} from "./ScaffoldHelpers.sol";
contract DeployChainLinkOr is ScaffoldHelpers {
    function run() public returns (address) {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);
        ATestnetConsumer consumer = new ATestnetConsumer();
        vm.stopBroadcast();

        return address(consumer);
    }
}