// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import {ConstantSumPool} from "./ConstantSumPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ConstantSumPool} from "./ConstantSumPool.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {BasePoolFactory} from "@balancer-labs/v3-vault/contracts/factories/BasePoolFactory.sol";

/**
 * @title Pool Factory
 * @dev Deploying pools via a factory is the preferred pattern
 */
contract CustomPoolFactoryExample is BasePoolFactory {
    uint256 swapFeePercentage = 0;
    bool protocolFeeExempt = false;

    constructor(
        IVault vault,
        uint32 pauseWindowDuration
    )
        BasePoolFactory(
            vault,
            pauseWindowDuration,
            type(ConstantSumPool).creationCode
        )
    {}

    /**
     * @notice Deploys a new pool and then immediately registers it with the vault
     * @param name The name of the pool
     * @param symbol The symbol of the pool
     * @param tokenConfig An array of descriptors for the tokens the pool will manage
     * @param salt The salt value that will be passed to create3 deployment
     */
    function create(
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokenConfig,
        bytes32 salt
    ) external returns (address pool) {
        pool = _create(abi.encode(getVault(), name, symbol), salt);

        PoolRoleAccounts memory roleAccounts;
        // LiquidityManagement memory liquidityManagement; // can i do this if all false?
        address poolHooksContract = address(0); // No hook contract

        getVault().registerPool(
            pool,
            tokenConfig,
            swapFeePercentage,
            getNewPoolPauseWindowEndTime(),
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            LiquidityManagement({
                disableUnbalancedLiquidity: false,
                enableAddLiquidityCustom: false,
                enableRemoveLiquidityCustom: false
            })
        );

        // _registerPoolWithFactory(pool); // i think this is redundant and can be removed since _create from BasePoolFactory already calls _registerPoolWithFactory
    }
}
