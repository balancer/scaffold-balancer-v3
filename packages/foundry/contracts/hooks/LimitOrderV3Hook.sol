// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24; 

import { LimitOrderBook } from "../LimitOrderBook.sol";
import { MinimalRouter } from "../MinimalRouter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
contract LimitOrderV3Hook is LimitOrderBook, MinimalRouter, BaseHooks {
    // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;

    address private _assignedPool;

    mapping(uint256 => address) public _address2Idx;
 
    event SetAndForgetSwapHooksRegistered(
        address indexed hooksContract,
        address indexed factory,
        address indexed pool
    );

    constructor(
        address allowedFactory,
        address tokenX, 
        address tokenY,  
        IVault vault,
        IWETH weth, 
        IPermit2 permit2,
        string memory executoorTokenName,
        string memory executoorTokenSymbol,
        string memory orderPositionTokenName,
        string memory orderPositionTokenSymbol
    ) 
        LimitOrderBook(address(vault), payable(this), executoorTokenName, executoorTokenSymbol, orderPositionTokenName, orderPositionTokenSymbol)
        MinimalRouter(vault, weth, permit2)
    {
        _allowedFactory = allowedFactory;
        _address2Idx[0] = tokenX;
        _address2Idx[1] = tokenY;
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

            address user = IRouterCommon(params.router).getSender();

            if (executoorBadge.balanceOf(user) == 0) {
                return true;
            }

            (
                uint256 tokenRateXY, 
                uint256 tokenRateYX
            ) = queryTokenRateXYYX(params.balancesScaled18[0], params.balancesScaled18[1]);

            (
                bool success,
                ExecutionData memory executionData,
                uint256 executionTimestamp
            ) = tryInitiateOrderExecution(user, _address2Idx[0], _address2Idx[1], tokenRateXY, tokenRateYX);

            if (!success) {
              return false;
            }

            if (executionData.totalAmountInTokenX > 0) {
                uint256 amountCalculated = tryCompleteOrderExecution(
                    _assignedPool,
                    IERC20(_address2Idx[0]),
                    IERC20(_address2Idx[1]),
                    executionData.totalAmountInTokenX
                ); 
                console.log("AmountCalculated ", amountCalculated);
            }
            
            if (executionData.totalAmountInTokenY > 0) {}
                console.log("Hello World");
                console.log(executionTimestamp);
       

    // console.log(84848484);
            
    //         console.log(user);

//         struct PoolSwapParams {
//     SwapKind kind;
//     uint256 amountGivenScaled18;
//     uint256[] balancesScaled18;
//     uint256 indexIn;
//     uint256 indexOut;
//     address router;
//     bytes userData;
// }
    //         (bool success, ) = address(orderBook).delegatecall(data);
    //         // require(success, "Delegatecall failed");
        
        // if (orderBook.executeOrder(_assignedPool, user)) {
        //     _takeTokenIn(0x866D42D8f75700768694B7b0bF7Fd1348663B102, IERC20(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9), params.amountGivenScaled18 * 5, true);

        // }


        return true;
    }

    function tryCompleteOrderExecution(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn
    ) private returns (uint256 amountCalculated) {
        SwapSingleTokenHookParams memory params = _buildSwapSingleTokenHookParams(
            pool,
            address(this), 
            tokenIn,
            tokenOut,
            exactAmountIn
        ); 

        (amountCalculated,) = _vault.swap(
            VaultSwapParams({
                kind: params.kind,
                pool: params.pool,
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                amountGivenRaw: params.amountGiven,
                limitRaw: params.limit,
                userData: params.userData
            })
        );
    }
}