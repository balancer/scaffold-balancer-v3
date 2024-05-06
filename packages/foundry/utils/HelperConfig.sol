// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {IVault} from "../contracts/interfaces/IVault.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";

/**
 * A useful place to store addresses and other configuration data used in multiple places
 */
contract HelperConfig {
    // BalancerV3 Sepolia addresses
    IVault public vault = IVault(0x1FC7F1F84CFE61a04224AC8D3F87f56214FeC08c);
    IRouter public router = IRouter(0xA0De078cd5cFa7088821B83e0bD7545ccfb7c883);
}
