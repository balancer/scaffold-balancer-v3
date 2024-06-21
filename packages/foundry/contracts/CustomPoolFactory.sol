// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import { BasePoolFactory } from "@balancer-labs/v3-vault/contracts/factories/BasePoolFactory.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { ConstantSumPool } from "./ConstantSumPool.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

/**
 * @title Custom Pool Factory
 * @dev Deploying pools via a factory is the preferred pattern as opposed to deploying a pool directly without a factory
 */
contract CustomPoolFactory is BasePoolFactory {
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
        TokenConfig[] memory tokens,
        bytes32 salt
    ) external returns (address pool) {
        // deploy the pool
        pool = _create(abi.encode(getVault(), name, symbol), salt);

        // config for pool registration
        uint256 swapFeePercentage = 0;
        bool protocolFeeExempt = false;
        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: address(0), // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: address(0), // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: address(0) // Account empowered to set the pool creator fee percentage
        });
        address poolHooksContract = address(0); // No hook contract
        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false
        });

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
