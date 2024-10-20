// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24; 

import { OrderBook } from "../CustomRouter.sol";
import { MinimalRouter } from "../MinimalRouter.sol";

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";

import {console} from "forge-std/console.sol";


import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
contract SetAndForgetSwapHook is MinimalRouter, BaseHooks {
    // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;

    address private _assignedPool;

    OrderBook public immutable orderBook;

    
 
    event SetAndForgetSwapHooksRegistered(
        address indexed hooksContract,
        address indexed factory,
        address indexed pool
    );

    constructor(
        address allowedFactory, 
        IVault vault,
        IWETH weth, 
        IPermit2 permit2,
        string memory executoorTokenName,
        string memory executoorTokenSymbol,
        string memory orderPositionTokenName,
        string memory orderPositionTokenSymbol
    ) 
        MinimalRouter(vault, weth, permit2)
    {
        _allowedFactory = allowedFactory;
       console.log(address(vault));
        orderBook = new OrderBook(address(vault), payable(this), executoorTokenName, executoorTokenSymbol, orderPositionTokenName, orderPositionTokenSymbol);
    }

        /// @inheritdoc BaseHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        emit SetAndForgetSwapHooksRegistered(address(this), factory,  pool);
        _assignedPool = pool;
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc BaseHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        // hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallBeforeSwap = true;
        // hookFlags.shouldCallAfterSwap = true;
    }

// perform check and swap 
    function onBeforeSwap(
        PoolSwapParams calldata params, 
        address
        ) public override returns (bool) {
            // If the router is not trusted, do not proceed.
            if (params.router != address(this)) {
                return false;
            }
            
    // console.log(84848484);
            address user = IRouterCommon(params.router).getSender();
    //         console.log(user);

        
    //         (bool success, ) = address(orderBook).delegatecall(data);
    //         // require(success, "Delegatecall failed");
        
        orderBook.executeOrder(_assignedPool, user);

        return true;
    }

    // the hooks perform the checks on the router
}