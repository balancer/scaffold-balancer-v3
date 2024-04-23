// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVault } from "./interfaces/IVault.sol";
import { IRateProvider } from "./interfaces/IRateProvider.sol";
import "./interfaces/VaultTypes.sol";

import { BasePoolFactory } from "./BasePoolFactory.sol";

import {ConstantPricePool} from "./ConstantPricePool.sol";

/**
 * @notice General Stable Pool factory
 * @dev This is the most general factory, which allows up to four tokens.
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


        /// TODO - STEVE THIS IS WHERE YOU LEFT OFF. TRYING TO FIGURE OUT WHY THE NEW ERROR (SEE TRACE) OCCURS WITHIN REGISTERPOOL(). IT SHOWS AS AN EVM ERROR
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

        _registerPoolWithFactory(pool);
    }
}
