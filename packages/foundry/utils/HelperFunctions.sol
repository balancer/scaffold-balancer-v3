// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract HelperFunctions {
    function convertNameToBytes32(
        string memory name
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param tokens Array of tokens to approve
     * @param spender Address of the spender
     */
    function maxApproveTokens(
        address spender,
        IERC20[] memory tokens
    ) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, type(uint256).max);
        }
    }
}
