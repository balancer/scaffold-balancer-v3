// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { BasePoolFactory } from "@balancer-labs/v3-pool-utils/contracts/BasePoolFactory.sol";

import { ConstantProductPool } from "../pools/ConstantProductPool.sol";

/**
 * @title Constant Product Factory
 * @notice This custom pool factory is based on the example from the Balancer v3 docs
 * https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/deploy-custom-amm-using-factory.html
 */
contract ConstantProductFactory is BasePoolFactory {
    /**
     * @dev The pool's creationCode is used to deploy pools via CREATE3
     * @notice The pool creationCode cannot be changed after the factory has been deployed
     * @param vault The contract instance of the Vault
     * @param pauseWindowDuration The period ( starting from deployment of this factory ) during which pools can be paused and unpaused
     */
    constructor(
        IVault vault,
        uint32 pauseWindowDuration
    ) BasePoolFactory(vault, pauseWindowDuration, type(ConstantProductPool).creationCode) {}

    /**
     * @notice Deploys a new pool and registers it with the vault
     * @param name The name of the pool
     * @param symbol The symbol of the pool
     * @param salt The salt value that will be passed to create3 deployment
     * @param tokens An array of descriptors for the tokens the pool will manage
     * @param swapFeePercentage Initial swap fee percentage
     * @param protocolFeeExempt true, the pool's initial aggregate fees will be set to 0
     * @param roleAccounts Addresses the Vault will allow to change certain pool settings
     * @param poolHooksContract Contract that implements the hooks for the pool
     * @param liquidityManagement Liquidity management flags with implemented methods
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
        // First deploy a new pool
        pool = _create(abi.encode(getVault(), name, symbol), salt);
        // Then register the pool
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
