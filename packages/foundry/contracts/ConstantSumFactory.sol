// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { BasePoolFactory } from "@balancer-labs/v3-vault/contracts/factories/BasePoolFactory.sol";

import { ConstantSumPool } from "./ConstantSumPool.sol";

/**
 * @title Custom Pool Factory
 * @dev Deploying pools via a factory is the preferred pattern as opposed to deploying a pool directly without a factory
 */
contract ConstantSumFactory is BasePoolFactory {
    constructor(
        IVault vault,
        uint32 pauseWindowDuration
    ) BasePoolFactory(vault, pauseWindowDuration, type(ConstantSumPool).creationCode) {}

    /**
     * @notice Deploys a new `CustomPool`
     * @param name The name of the pool
     * @param symbol The symbol of the pool
     * @param tokens An array of descriptors for the tokens the pool will manage
     * @param salt The salt value that will be passed to create3 deployment
     */
    function create(
        string memory name,
        string memory symbol,
        bytes32 salt,
        TokenConfig[] memory tokens,
        uint256 swapFeePercentage,
        bool protocolFeeExempt,
        PoolRoleAccounts memory roleAccounts,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) external returns (address pool) {
        // Deploy the pool
        pool = _create(abi.encode(getVault(), name, symbol), salt);
        // Register the pool
        _registerPoolWithVault(
            pool,
            tokens,
            swapFeePercentage,
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
