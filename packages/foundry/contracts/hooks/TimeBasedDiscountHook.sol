// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

/**
 * @title TimeBasedDiscountHook
 * @notice Implements a hook that provides a time-based discount on swap fees.
 */
contract TimeBasedDiscountHook is BaseHooks, VaultGuard {
    address private immutable _allowedFactory;
    address private immutable _trustedRouter;
    IERC20 private immutable _veBAL;

    // Timezone offset in hours (e.g., 0 for UTC, -5 for EST, 8 for China Standard Time)
    // Set to Indian Standard Time (IST) offset
    int256 private constant TIMEZONE_OFFSET = 5; // Adjustable parameter

    uint256 public peakHourStart;
    uint256 public peakHourEnd;

    uint256 public discountPercentage;

    /**
     * @notice Emitted when the TimeBasedDiscountHook is registered.
     * @param hooksContract The address of the hooks contract.
     * @param factory The address of the factory.
     * @param pool The address of the pool.
     */
    event TimeBasedDiscountHookRegistered(address indexed hooksContract, address indexed factory, address indexed pool);

    /**
     * @notice Emitted when the TimeBasedDiscountHook is executed.
     */
    event TimeBasedDiscountHookExecuted();

    /**
     * @notice Constructs the TimeBasedDiscountHook contract.
     * @param vault The address of the vault.
     * @param allowedFactory The address of the allowed factory.
     * @param veBAL The address of the veBAL token.
     * @param trustedRouter The address of the trusted router.
     * @param _peakHourStart The start of the peak hour.
     * @param _peakHourEnd The end of the peak hour.
     * @param _discountPercentage The discount percentage for off-peak hours.
     */
    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        address veBAL,
        uint256 _peakHourStart,
        uint256 _peakHourEnd,
        uint256 _discountPercentage
    ) VaultGuard(vault) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        _veBAL = IERC20(veBAL);
        peakHourStart = _peakHourStart;
        peakHourEnd = _peakHourEnd;
        discountPercentage = _discountPercentage;
    }

    /**
     * @notice Returns the hook flags indicating which hooks should be called.
     * @return hookFlags The hook flags.
     */
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    /**
     * @notice Called when the hook is registered.
     * @param factory The address of the factory.
     * @param pool The address of the pool.
     * @param tokenConfigs The token configurations.
     * @param liquidityManagement The liquidity management settings.
     * @return success True if the registration is successful.
     */
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory tokenConfigs,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool success) {
        emit TimeBasedDiscountHookRegistered(address(this), factory, pool);
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /**
     * @notice Computes the dynamic swap fee percentage.
     * @param params The pool swap parameters.
     * @param staticSwapFeePercentage The static swap fee percentage.
     * @return success True if the computation is successful.
     * @return dynamicFee The dynamic swap fee percentage.
     */
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // Get the current hour (0-23) adjusted for timezone
        int256 currentHour = getCurrentTimeStampWithOffset();

        // Define peak hours based on the configured start and end hours
        bool isPeakHour = getIfPeakHour(currentHour);

        uint256 dynamicFee;
        if (isPeakHour) {
            // During peak hours, keep the fee as the staticSwapFeePercentage
            dynamicFee = staticSwapFeePercentage;
        } else {
            // During off-peak hours, decrease the fee by the configured discount percentage
            dynamicFee = (staticSwapFeePercentage * (100 - discountPercentage)) / 100;
        }

        return (true, dynamicFee);
    }

    function getCurrentTimeStampWithOffset() public view returns (int256) {
        int256 currentHour = (int256(block.timestamp / 3600) + TIMEZONE_OFFSET) % 24;
        if (currentHour < 0) currentHour += 24; // Ensure positive hour
        return currentHour;
    }

    function getIfPeakHour(int256 currentHour) public view returns (bool) {
        bool isPeakHour = uint256(currentHour) >= peakHourStart && uint256(currentHour) <= peakHourEnd;
        return isPeakHour;
    }

    // the following three setters should be restricted to be used by the owner

    /**
     * @notice Sets the start of the peak hour.
     * @param newPeakHourStart The new start of the peak hour.
     */
    function setPeakHourStart(uint256 newPeakHourStart) public {
        peakHourStart = newPeakHourStart;
    }

    /**
     * @notice Sets the end of the peak hour.
     * @param newPeakHourEnd The new end of the peak hour.
     */
    function setPeakHourEnd(uint256 newPeakHourEnd) public {
        peakHourEnd = newPeakHourEnd;
    }

    /**
     * @notice Sets the discount percentage for off-peak hours.
     * @param newDiscountPercentage The new discount percentage.
     */
    function setDiscountPercentage(uint256 newDiscountPercentage) public {
        discountPercentage = newDiscountPercentage;
    }
}
