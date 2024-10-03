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

contract VolatilityFeeHookV2 is BaseHooks, Ownable, VaultGuard {
    using FixedPoint for uint256;
    address private immutable _trustedRouter;
    address private immutable _allowedFactory;


    // Constructor
    // Add Trusted Roter and Allowed Factory for the Hook at Deployment
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

    // @Dev
    // This function computes Balance Out by a rough Constant Product Method
    // A more accurate approach would be to query expected Amount Out from the pool
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address, // pool
        uint256 staticSwapFeePercentage
    ) public pure override returns (bool success, uint256 dynamicSwapFeePercentage) {

        // Calcculate AmountOUT is SWAP METHOD: EXACT_IN
        if(params.kind == SwapKind.EXACT_IN){

            // Extract AmountIn, Balance of AssetIn and AssetOut
            uint256 amountIn = params.amountGivenScaled18;
            uint256 balanceIn = params.balancesScaled18[params.indexIn];
            uint256 balanceOut = params.balancesScaled18[params.indexOut];

            // ROUGH AMOUNT OUT: Calculate using Constant Product formula
            uint256 roughAmountOut = amountIn * balanceOut / (balanceIn + amountIn);

            // Calculate Swap Fee Based on AmountOut, and Balance of AssetOut
            uint256 calculatedDynamicSwapFeePercentage = _calculateSwapFee(roughAmountOut, balanceOut, staticSwapFeePercentage);
            return (true, calculatedDynamicSwapFeePercentage);

        } else if (params.kind == SwapKind.EXACT_OUT){
            // Extract Amount Out and Balance of Asset Out
            uint256 amountOut = params.amountGivenScaled18;
            uint256 balanceOut = params.balancesScaled18[params.indexOut];

            // Calculate Swap Fee Based on Amount Out and Balance Out
            uint256 calculatedDynamicSwapFeePercentage =_calculateSwapFee(amountOut, balanceOut, staticSwapFeePercentage);
            return (true, calculatedDynamicSwapFeePercentage);

        }
    }


    // @function
    // Calculates the Swap Fee based on utilization ratio 
    // If Utilization Ratio increases, it impacts swap fee in a quardratic curve
    // @dev
    // Other Curves can be explored for optimised usage
    function _calculateSwapFee(uint256 amount, uint256 balance, uint256 staticSwapFeePercentage) internal pure returns (uint256){
        // Ensure we don't divide by zero
        if (balance == 0) {
            return staticSwapFeePercentage * 100; // Max fee if no balance exists
        }

        // Calculate utilization ratio as amount / balance, scaled to 1e18 for precision
        uint256 utilizationRatio = (amount * 1e18) / balance;

        // We use a quadratic curve for the fee multiplier: utilizationRatio^2
        // This increases the fee more steeply as utilization approaches 100%
        uint256 quadraticMultiplier = (utilizationRatio * utilizationRatio) / 1e18; 

        // Scale the multiplier into the desired range: 1x base fee at low utilization, higher at high utilization
        // For example, multiplying by 99 ensures that at max utilization the fee multiplier reaches 100x
        uint256 feeMultiplier = 1 + (quadraticMultiplier * 99 / 1e18);

        // Return the final fee, multiplying the base fee by the calculated multiplier
        return staticSwapFeePercentage * feeMultiplier;
    }
    
}

