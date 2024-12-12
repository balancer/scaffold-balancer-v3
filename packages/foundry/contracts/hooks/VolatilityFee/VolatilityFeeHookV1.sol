// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AfterSwapParams,
    LiquidityManagement,
    SwapKind,
    TokenConfig,
    HookFlags,
    PoolSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { EnumerableMap } from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/EnumerableMap.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";

contract VolatilityFeeHookV1 is BaseHooks, Ownable, VaultGuard {
    using FixedPoint for uint256;
    address private immutable _trustedRouter;
    address private immutable _allowedFactory;



    constructor(IVault vault,address allowedFactory, address router) VaultGuard(vault) Ownable(msg.sender) {
        _trustedRouter = router;
        _allowedFactory = allowedFactory;

    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override onlyVault returns (bool) {
        // NOTICE: In real hooks, make sure this function is properly implemented (e.g. check the factory, and check
        // that the given pool is from the factory). Returning true unconditionally allows any pool, with any
        // configuration, to use this hook.
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        return hookFlags;
    }

    // Compute Dynamic Swap Fee Percentage
    // This Hook computes the Dynamic Swap Fee Based on Amount Given and Balance of Token
    // Uses AmountIn if Swap is EXACT_IN
    // USes AmountOut if Swap is EXACT_OUT
    // These parameters can be fine tuned for real deployments
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address, // pool
        uint256 staticSwapFeePercentage
    ) public pure override returns (bool success, uint256 dynamicSwapFeePercentage) {

        // SWAP: EXACT_IN
        if(params.kind == SwapKind.EXACT_IN){
            uint256 amountIn = params.amountGivenScaled18;
            uint256 balanceIn = params.balancesScaled18[params.indexIn];
            // Notice: @dev
            // A more accurate results would be produced if using expected AmountOut by querying the pool
            dynamicSwapFeePercentage = _calculateSwapFee(amountIn, balanceIn, staticSwapFeePercentage);
            return (true, dynamicSwapFeePercentage);

        // SWAP: EXACT_OUT
        } else if (params.kind == SwapKind.EXACT_OUT){
            uint256 amountOut = params.amountGivenScaled18;
            uint256 balanceOut = params.balancesScaled18[params.indexOut];
            dynamicSwapFeePercentage =_calculateSwapFee(amountOut, balanceOut, staticSwapFeePercentage);
            return (true, dynamicSwapFeePercentage);

        }
    }


    // @function: Calculate Swap Fee
    // This is example Function and can be configured by devs based on their Pool Fee.
    // Remember to check boundry conditions! Example: 
    // If Static Swap Fee = 2%
    // Then Swaping more than 40% of the pool balance will result (100% Swap Fee, and user will get nothing for swapping)

    // If Swap Moves too much Balance (in or out Token), charge higher fee
    // Amount is 10% of Pool Balance -> x5 the swap fee
    // Amount is 20% of Pool Balance -> x10 the swap fee
    // Amount is 30% of Pool Balance -> x20 the swap fee
    // Amount is 40% of Pool Balance -> x50 the swap fee
    function _calculateSwapFee(uint256 amount, uint256 balance, uint256 staticSwapFeePercentage) internal pure returns (uint256){
        if(amount > (balance * 40 /100) ){
            return (staticSwapFeePercentage * 50);
        } 
        else if(amount > (balance * 30 / 100) ){
            return (staticSwapFeePercentage * 20);
        } 
        else if (amount > (balance * 20 / 100)){
            return (staticSwapFeePercentage * 10);
        } 
        else if (amount > (balance * 10 / 100)){
            return (staticSwapFeePercentage * 5);
        }
        else {
            return (staticSwapFeePercentage);
        }
    }
    
}



