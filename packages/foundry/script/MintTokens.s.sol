// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import {ScaffoldHelpers} from "./ScaffoldHelpers.sol";

// scipt to mint tokens 
contract MintToken1 is Script, ScaffoldHelpers {
    function run() external {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        MockToken1 token1 = MockToken1(0x239e733ff339495Df5d28730b5cAd2f77fE27407);
        vm.startBroadcast(deployerPrivateKey);
        token1.mint(100000*1e18);
        vm.stopBroadcast();

    }
}

contract MintToken2 is Script, ScaffoldHelpers {
    function run() external {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        MockToken2 token2 =  MockToken2(0x40d514790c1c0528e7143def9104AeBbf54fF1ce);
        vm.startBroadcast(deployerPrivateKey);
        token2.mint(10000*1e18);
        vm.stopBroadcast();
    }
}