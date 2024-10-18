// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IRouterCommon {
    /**
     * @notice Get the first sender which initialized the call to Router.
     * @return address The sender address
     */
    function getSender() external view returns (address);
}
