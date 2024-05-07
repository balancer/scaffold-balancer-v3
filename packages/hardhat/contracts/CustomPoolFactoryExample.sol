// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { IVault } from "./interfaces/IVault.sol";
// import { IRateProvider } from "./interfaces/IRateProvider.sol";
// import "./interfaces/VaultTypes.sol";
// import { BasePoolFactory } from "./BasePoolFactory.sol";
import {ConstantPricePool} from "./ConstantPricePool.sol";
// import { TokenConfig } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
// import { TokenConfig } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { BasePoolFactory } from "@balancer-labs/v3-vault/contracts/factories/BasePoolFactory.sol";

/**
 * @title Example Custom Pool Factory Using Constant Price Invariant
 * @author BUIDL GUIDL
 * @notice This is an example Custom Pool Factory Implementation, is not ready for production, and should not be used in production. It is simply an example for developers to reference when creating their own custom pool, custom pool factory, etc. with BalancerV3.
 */
contract CustomPoolFactoryExample is BasePoolFactory {
    // solhint-disable not-rely-on-time

    constructor(
        IVault vault,
        uint256 pauseWindowDuration
    ) BasePoolFactory(vault, pauseWindowDuration, type(ConstantPricePool).creationCode) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Deploys a new `ConstantPricePool`.
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
        pool = _create(
            abi.encode(
                getVault(),
                name,
                symbol
            ),
            salt
        );

        // Call registerPool from the vault. See `IVaultExtension.sol` for details on `registerPool()`
        getVault().registerPool(
            pool,
            tokens,
            getNewPoolPauseWindowEndTime(),
            address(0), // no pause manager
            PoolHooks({
                shouldCallBeforeInitialize: false,
                shouldCallAfterInitialize: false,
                shouldCallBeforeAddLiquidity: false,
                shouldCallAfterAddLiquidity: false,
                shouldCallBeforeRemoveLiquidity: false,
                shouldCallAfterRemoveLiquidity: false,
                shouldCallBeforeSwap: false,
                shouldCallAfterSwap: false
            }),
            LiquidityManagement({ supportsAddLiquidityCustom: false, supportsRemoveLiquidityCustom: false })
        );

        _registerPoolWithFactory(pool); // register pool with respective factory (example facotry that was created in a previous tx, if using this repo it would've likely been from `DeployCustomPoolFactoryAndNewPoolExample.s.sol` script being ran).
    }
}
