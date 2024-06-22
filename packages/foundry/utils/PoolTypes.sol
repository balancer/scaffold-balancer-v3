// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {
    TokenConfig,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

struct RegistrationConfig {
    string name;
    string symbol;
    bytes32 salt;
    TokenConfig[] tokenConfig;
    uint256 swapFeePercentage;
    bool protocolFeeExempt;
    PoolRoleAccounts roleAccounts;
    address poolHooksContract;
    LiquidityManagement liquidityManagement;
}

struct InitializationConfig {
    IERC20[] tokens;
    uint256[] exactAmountsIn;
    uint256 minBptAmountOut;
    bool wethIsEth;
    bytes userData;
}
