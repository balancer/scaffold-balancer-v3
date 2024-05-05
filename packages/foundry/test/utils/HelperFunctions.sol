// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

contract HelperFunctions {

function convertNameToBytes32(string memory name) public pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }

}