// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    RemoveLiquidityKind,
    AfterSwapParams,
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags,
    PoolData,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IDynamicFeeHook } from "../interfaces/IDynamicFeeHook.sol";
import { ILendingPoolV3 } from "../interfaces/ILendingPoolV3.sol";
import { IRouterCommon } from "../interfaces/IRouterCommon.sol";

contract DynamicFeeHook is IDynamicFeeHook, BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    // Only stable pools from the allowed factory are able to register and use this hook.
    address private immutable allowedPoolFactory;

    // The address of the lending pool contract
    ILendingPoolV3 public immutable LENDING;

    uint256 private constant ALPHA = 0.5e18; // smoothing parameter

    // Allow to remove liquidity early and receive rewards without `minLockDuration` restrictions
    bool public isEarlyUnlockAllowed;
    // Minimum duration of locking liquidity (without removing it) to be eligible for rewards
    uint256 public minLockDuration;
    // Fee parameters in 18-decimal fixed-point format
    uint256 public minFee; // e.g. 0.001e18 (0.1%)
    uint256 public maxFee; // e.g. 0.01e18 (1%)
    // Higher sensitivity values will make the fee more sensitive to changes
    uint256 public volatilitySensitivity; // e.g. 0.0001e18 (0.01%)
    uint256 public liquiditySensitivity; // e.g. 0.00005e18 (0.005%)

    // Fee that hook will take from swap
    // Calculated by calculatedSwapFeePercentage - staticSwapFeePercentage
    // NOTE: will update every time when swap invokes (find solution)
    uint256 public deductibleHookFeePercentage;

    // State per each registered pool
    mapping(address => uint256) public lastSwapTime;
    mapping(address => uint256) public volatility;
    mapping(address => uint256) public liquidity;
    mapping(address => PoolInfo) public poolInfo;
    mapping(address => mapping(address user => LockInfo)) public userLockInfo;

    constructor(
        IVault vault,
        address _allowedPoolFactory,
        uint256 _minFee,
        uint256 _maxFee,
        uint256 _volatilitySensitivity,
        uint256 _liquiditySensitivity,
        uint256 _minLockDuration,
        address lendingPool
    ) VaultGuard(vault) Ownable(msg.sender) {
        // Although the hook allows any factory to be registered during deployment, it should be a stable pool factory.
        allowedPoolFactory = _allowedPoolFactory;

        minFee = _minFee;
        maxFee = _maxFee;
        volatilitySensitivity = _volatilitySensitivity;
        liquiditySensitivity = _liquiditySensitivity;

        minLockDuration = _minLockDuration;
        LENDING = ILendingPoolV3(lendingPool);
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        emit DynamicFeeHookRegistered(address(this), factory, pool);

        // This hook only allows pools deployed by `_allowedStablePoolFactory` to register it.
        return factory == allowedPoolFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallAfterSwap = true;
        hookFlags.shouldCallBeforeSwap = true;
    }

    function onBeforeSwap(PoolSwapParams calldata, address pool) public override returns (bool success) {
        (, , , uint256[] memory lastBalancesLiveScaled18) = _vault.getPoolTokenInfo(pool);

        // Simulate updating of volatility and liquidity
        (uint256 simulatedVolatility, uint256 simulatedLiquidity) = _calculateVolatilityAndLiquidity(
            pool,
            lastBalancesLiveScaled18
        );

        // Calculate fee
        uint256 staticSwapFeePercentage = _vault.getStaticSwapFeePercentage(pool);
        uint256 calculatedSwapFeePercentage = _calculateDynamicFee(simulatedVolatility, simulatedLiquidity);

        if (calculatedSwapFeePercentage > staticSwapFeePercentage) {
            deductibleHookFeePercentage = calculatedSwapFeePercentage - staticSwapFeePercentage;
        } else {
            deductibleHookFeePercentage = 0;
        }
        return true;
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        uint256 calculatedSwapFeePercentage = deductibleHookFeePercentage + staticSwapFeePercentage;
        // Charge the static or calculated fee, whichever is greater.
        return (
            true,
            calculatedSwapFeePercentage > staticSwapFeePercentage
                ? calculatedSwapFeePercentage
                : staticSwapFeePercentage
        );
    }

    /// @inheritdoc IHooks
    function onAfterSwap(AfterSwapParams calldata params) public override onlyVault returns (bool, uint256) {
        // Get pool balances
        (, , , uint256[] memory lastBalancesLiveScaled18) = _vault.getPoolTokenInfo(params.pool);

        // Calculate volatility and liquidity
        (uint256 newVolatility, uint256 newLiquidity) = _calculateVolatilityAndLiquidity(
            params.pool,
            lastBalancesLiveScaled18
        );

        volatility[params.pool] = newVolatility;
        liquidity[params.pool] = newLiquidity;
        lastSwapTime[params.pool] = block.timestamp;

        // Returning value for after swap hook
        uint256 hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;
        // Check if fee is present
        if (deductibleHookFeePercentage > 0) {
            uint256 hookFee = params.amountCalculatedRaw.mulDown(deductibleHookFeePercentage);

            if (hookFee > 0) {
                IERC20 feeToken;

                if (params.kind == SwapKind.EXACT_IN) {
                    // For EXACT_IN swaps, the `amountCalculated` is the amount of `tokenOut`. The fee must be taken
                    // from `amountCalculated`, so we decrease the amount of tokens the Vault will send to the caller.
                    //
                    // The preceding swap operation has already credited the original `amountCalculated`. Since we're
                    // returning `amountCalculated - hookFee` here, it will only register debt for that reduced amount
                    // on settlement. This call to `sendTo` pulls `hookFee` tokens of `tokenOut` from the Vault to this
                    // contract, and registers the additional debt, so that the total debts match the credits and
                    // settlement succeeds.
                    feeToken = params.tokenOut;
                    hookAdjustedAmountCalculatedRaw -= hookFee;
                } else {
                    // For EXACT_OUT swaps, the `amountCalculated` is the amount of `tokenIn`. The fee must be taken
                    // from `amountCalculated`, so we increase the amount of tokens the Vault will ask from the user.
                    //
                    // The preceding swap operation has already registered debt for the original `amountCalculated`.
                    // Since we're returning `amountCalculated + hookFee` here, it will supply credit for that increased
                    // amount on settlement. This call to `sendTo` pulls `hookFee` tokens of `tokenIn` from the Vault to
                    // this contract, and registers the additional debt, so that the total debts match the credits and
                    // settlement succeeds.
                    feeToken = params.tokenIn;
                    hookAdjustedAmountCalculatedRaw += hookFee;
                }

                // hookFee = calculated amount from dynamic fee

                if (poolInfo[params.pool].feeToken == address(feeToken)) {
                    _vault.sendTo(feeToken, address(this), hookFee);

                    // Invest the collected fee
                    _invest(params.pool, address(feeToken), hookFee);

                    emit HookFeeInvested(address(this), feeToken, hookFee);
                }
            }
        }
        return (true, hookAdjustedAmountCalculatedRaw);
    }

    /// @notice This function calculates update to a pool volatility and liquidity without changing state
    function _calculateVolatilityAndLiquidity(
        address pool,
        uint256[] memory poolBalances
    ) internal view returns (uint256 newVolatility, uint256 newLiquidity) {
        uint256 previousSwapTime = lastSwapTime[pool];
        uint256 currentVolatility = volatility[pool];

        // Calculate time since the last swap
        uint256 timeSinceLastSwap = previousSwapTime == 0 ? 0 : block.timestamp - previousSwapTime;

        // Convert time to fixed-point format
        uint256 timeSinceLastSwapFixed = timeSinceLastSwap * FixedPoint.ONE;

        // Calculate volatility using exponential smoothing based on the time between swaps
        // updatedVolatility = currentVolatility * (1 - alpha) + timeSinceLastSwapFixed * alpha
        newVolatility = currentVolatility.mulDown(FixedPoint.ONE - ALPHA) + timeSinceLastSwapFixed.mulDown(ALPHA);

        // Calculate current liquidity (sum of all token balances in the pool)
        uint256 totalLiquidity = 0;
        for (uint256 i = 0; i < poolBalances.length; i++) {
            totalLiquidity += poolBalances[i];
        }
        newLiquidity = totalLiquidity;
    }

    function _calculateDynamicFee(uint256 _volatility, uint256 _liquidity) internal view returns (uint256) {
        // Avoid division by zero
        if (_liquidity == 0) {
            _liquidity = 1;
        }

        // Calculate the fee component from volatility
        uint256 feeFromVolatility = _volatility.mulDown(volatilitySensitivity);

        // Calculate the fee component inversely proportional to liquidity
        // Lower liquidity leads to a higher fee
        uint256 feeFromLiquidity = liquiditySensitivity.mulDown(FixedPoint.ONE.divDown(_liquidity));

        // Sum the fee components and add the minimum fee
        uint256 dynamicFee = minFee + feeFromVolatility + feeFromLiquidity;

        // Check fee boundaries
        if (dynamicFee > maxFee) {
            dynamicFee = maxFee;
        }
        if (dynamicFee < minFee) {
            dynamicFee = minFee;
        }

        return dynamicFee;
    }

    /// @dev Handles investing of collected fees into Lending market
    function _invest(address _pool, address _asset, uint256 _amount) internal {
        _updatePoolInfo(_pool, _amount);

        // invest fees
        IERC20(_asset).forceApprove(address(LENDING), _amount);
        LENDING.supply(_asset, _amount, address(this), 0);
    }

    /// @dev Updates poolInfo according to new balance + _amount
    /// @param _pool pool address
    /// @param _amount The new received amount to be distributed among liquidity providers
    function _updatePoolInfo(address _pool, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pool];

        uint256 lastAssetBalance = pool.lastRewardBalance;
        uint256 currentRewardBalance = IERC20(pool.rewardToken).balanceOf(address(this));

        // since the balance of the rewardToken is nominated in feeToken we can safely perform the calculation
        _amount = _amount + (currentRewardBalance - lastAssetBalance);
        if (_amount == 0) return;

        // update poolInfo according to new balance + _amount
        pool.accRewardsPerShare = pool.accRewardsPerShare + uint128(((_amount * 1e18) / pool.bptLocked));
        pool.lastRewardBalance = uint128(currentRewardBalance + _amount);
    }

    function onAfterAddLiquidity(
        address router,
        address _pool,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256 bptAmountOut,
        uint256[] memory,
        bytes memory
    ) public override returns (bool success, uint256[] memory hookAdjustedAmountsInRaw) {
        if (poolInfo[_pool].feeToken == address(0)) return (false, amountsInRaw);

        address userAddress = IRouterCommon(router).getSender();

        PoolInfo storage pool = poolInfo[_pool];
        LockInfo storage lock = userLockInfo[_pool][userAddress];
        _updatePoolInfo(_pool, 0);

        if (lock.lockStart == 0) {
            lock.lockStart = uint128(block.timestamp);
        }

        if (lock.bptLocked > 0) {
            uint256 newRewards = (lock.bptLocked * pool.accRewardsPerShare) / 1e18 - lock.rewardDebt;
            lock.accruedRewards += uint128(newRewards);
        }

        pool.bptLocked += uint128(bptAmountOut);

        lock.bptLocked += uint128(bptAmountOut);
        lock.rewardDebt = (lock.bptLocked * pool.accRewardsPerShare) / 1e18;

        return (true, amountsInRaw);
    }

    function onAfterRemoveLiquidity(
        address router,
        address _pool,
        RemoveLiquidityKind,
        uint256 bptAmountIn,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        bytes memory userData
    ) public override returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw) {
        if (poolInfo[_pool].feeToken == address(0)) return (false, hookAdjustedAmountsOutRaw);

        address userAddress = IRouterCommon(router).getSender();

        PoolInfo storage pool = poolInfo[_pool];
        LockInfo storage lock = userLockInfo[_pool][userAddress];
        _updatePoolInfo(_pool, 0);

        uint256 newRewards = (lock.bptLocked * pool.accRewardsPerShare) / 1e18 - lock.rewardDebt;
        lock.accruedRewards += uint128(newRewards);

        lock.bptLocked -= uint128(bptAmountIn);
        lock.rewardDebt = (lock.bptLocked * pool.accRewardsPerShare) / 1e18;

        uint256 userRewards = lock.accruedRewards;
        lock.accruedRewards = 0;

        uint256 userLockStart = lock.lockStart;
        lock.lockStart = 0; // reset timer on any remove liquidity

        // rewards payment
        // in case user didn't lock for minLockDuration he looses rewards
        if (userLockStart + minLockDuration > block.timestamp || isEarlyUnlockAllowed) {
            if (userData.length > 0 && abi.decode(userData, (bool))) {
                // transfer underlying token
                LENDING.withdraw(pool.feeToken, userRewards, userAddress);
            } else {
                // transfer aToken (can be useful in case low liquidity in the lending pool)
                IERC20(pool.rewardToken).safeTransfer(userAddress, lock.accruedRewards);
            }

            pool.lastRewardBalance -= uint128(userRewards);
        } else {
            // penalty: distribute rewards among current users
            _updatePoolInfo(_pool, userRewards);
        }

        return (true, hookAdjustedAmountsOutRaw);
    }

    /* OWNER FUNCTIONS */

    function addInvestPool(address _pool, address _asset) external onlyOwner {
        if (poolInfo[_pool].feeToken != address(0)) revert AlreadyExist();

        poolInfo[_pool].feeToken = _asset;

        // this call also checks if there is exist aToken for the asset
        ILendingPoolV3.ReserveDataLegacy memory reserveData = ILendingPoolV3(LENDING).getReserveData(_asset);
        poolInfo[_pool].rewardToken = reserveData.aTokenAddress;

        emit InvestPoolAdded(_pool, _asset);
    }

    function setEarlyUnlock(bool _allowedEarlyUnlock) external onlyOwner {
        isEarlyUnlockAllowed = _allowedEarlyUnlock;

        emit EarlyUnlockSet(_allowedEarlyUnlock);
    }

    function setMinLockDuration(uint256 _minLockDuration) external onlyOwner {
        minLockDuration = _minLockDuration;

        emit MinLockDurationSet(_minLockDuration);
    }
}
