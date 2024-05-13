// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title HelperFunctions
 * @author BuidlGuidl Labs
 * @dev This contract contains helper functions for the deployment scripts
 */
contract HelperFunctions {
    function convertNameToBytes32(
        string memory name
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }
}
