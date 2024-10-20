// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags,
    AddLiquidityKind,
    RemoveLiquidityKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

// Interface to MockLPReward Token
interface LPRewardToken {
    function mint(address sender, uint256 amount) external;
}

/**
 * @notice Hook that gives a swap fee discount to lpRWD holders.
 * @dev Uses to reward Liquidity Providers (LPs) based on multiple factors
 */
contract LPIncentivizedHook is BaseHooks, VaultGuard, Ownable {
    // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;
    // Only trusted routers are allowed to call this hook, because the hook relies on the `getSender` implementation
    // implementation to work properly.
    address private immutable _trustedRouter;

    // Struct to store LP information
    struct LPInfo {
        uint256 totalLiquidity;
        uint256 liquidityStartTime;
        uint256 rewards;
    }

    // Struct to store LP Incentive Factors
    struct LPIncentiveFactor {
        bool amountBaseLiquidity;
        bool timeBaseLiquidity;
    }

    // Struct to store Amount Base Liquidity Parameters
    struct AmountBaseLiquidityParameters {
        uint256 mediumLiquidityAmountTrigger;
        uint256 higherLiquidityAmountTrigger;
        uint256 mediumLiquidityAmountRewardFee;
        uint256 higherLiquidityAmountRewardFee;
    }

    // Struct to store Time Base Liquidity Parameters (Time Trigger should be in seconds)
    struct TimeBaseLiquidityParameters {
        uint256 mediumLiquidityTimeTrigger;
        uint256 higherLiquidityTimeTrigger;
        uint256 mediumLiquidityTimeRewardFee;
        uint256 higherLiquidityTimeRewardFee;
    }

    // Active Rewards Factor for the hook
    LPIncentiveFactor public activeIncentiveFactor;

    // Active Amount parameter for the hook
    AmountBaseLiquidityParameters public activeAmountBaseLiquidityParameters;

    // Active Time parameter for the hook
    TimeBaseLiquidityParameters public activeTimeBaseLiquidityParameters;

    // Mapping from LP address to LPInfo
    mapping(address => mapping(IERC20 => LPInfo)) public lpInfos;

    // LP Reward token
    LPRewardToken private _lpRWD;

    /**
     * @notice A new `LPIncentivizedHook` contract has been registered successfully.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param factory The factory (must be the allowed factory, or the call will revert)
     * @param pool The pool on which the hook was registered
     */
    event LPIncentivizedHookRegistered(address indexed hooksContract, address indexed factory, address indexed pool);

    /**
     * @dev Event if rewards distributed successfully.
     * @param LPAddress Liquidity provider address
     * @param reward Earn rewards
     */
    event RewardDistributed(address indexed LPAddress, uint256 reward);

    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        address lpRewardToken,
        LPIncentiveFactor memory _lpIncentiveFactor
    ) VaultGuard(vault) Ownable(msg.sender) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        activeIncentiveFactor = _lpIncentiveFactor;
        _lpRWD = LPRewardToken(lpRewardToken);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        // This hook implements a restrictive approach, where we check if the factory is an allowed factory and if
        // the pool was created by the allowed factory. Since we only use onComputeDynamicSwapFeePercentage, this
        // might be an overkill in real applications because the pool math doesn't play a role in the discount
        // calculation.

        emit LPIncentivizedHookRegistered(address(this), factory, pool);

        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function onAfterAddLiquidity(
        address router,
        address pool,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool success, uint256[] memory hookAdjustedAmountsInRaw) {
        if (router != _trustedRouter) {
            // Returning false will make the transaction revert, so the second argument does not matter.
            return (false, amountsInRaw);
        }

        address sender = IRouterCommon(router).getSender();
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256 totalReward = 0;

        for (uint256 i = 0; i < amountsInRaw.length; i++) {
            LPInfo storage info = lpInfos[sender][tokens[i]];
            // If this is the first time adding liquidity, set the start time
            if (info.totalLiquidity == 0) {
                info.liquidityStartTime = block.timestamp;
            }

            info.totalLiquidity += uint256(amountsInRaw[i]);
            uint256 _rewards = 0;
            _rewards += _calculateAmountBaseRewards(amountsInRaw[i]);
            _rewards += _calculateTimeBaseRewards(sender, tokens[i]);
            info.rewards += _rewards;
            totalReward += _rewards;
            _lpRWD.mint(sender,_rewards);
        }
        emit RewardDistributed(sender, totalReward);
        return (true, amountsInRaw);
    }
    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw) {
        if (router != _trustedRouter) {
            // Returning false will make the transaction revert, so the second argument does not matter.
            return (false, amountsOutRaw);
        }

        address sender = IRouterCommon(router).getSender();
        IERC20[] memory tokens = _vault.getPoolTokens(pool);

        for (uint256 i = 0; i < amountsOutRaw.length; i++) {
            LPInfo storage info = lpInfos[sender][tokens[i]];

            info.totalLiquidity -= uint256(amountsOutRaw[i]);
        }
        return (true, amountsOutRaw);
    }

    /**
     * @dev Sets the Amount based liquidity rewards parameters for the hook
     * This function must be permissioned.
     *
     * @param _amountBaseLiquidityParameters The amount base liquidity parameters
     */
    function setAmountBaseLiquidityParameters(
        AmountBaseLiquidityParameters memory _amountBaseLiquidityParameters
    ) external onlyOwner {
        require(activeIncentiveFactor.amountBaseLiquidity, "Amount Base Rewards is not configured for this Hook.");
        activeAmountBaseLiquidityParameters = _amountBaseLiquidityParameters;
    }

    /**
     * @dev Sets the Time based liquidity rewards parameters for the hook
     * This function must be permissioned.
     *
     * @param _timeBaseLiquidityParameters The time base liquidity parameters
     */
    function setTimeBaseLiquidityParameters(
        TimeBaseLiquidityParameters memory _timeBaseLiquidityParameters
    ) external onlyOwner {
        require(activeIncentiveFactor.timeBaseLiquidity, "Time Base Rewards is not configured for this Hook.");
        activeTimeBaseLiquidityParameters = _timeBaseLiquidityParameters;
    }

    function _calculateAmountBaseRewards(
        uint256 amountIn
    ) private view returns (uint256) {
        if (!activeIncentiveFactor.amountBaseLiquidity) {
            return 0;
        }

        if (amountIn > activeAmountBaseLiquidityParameters.higherLiquidityAmountTrigger) {
            return activeAmountBaseLiquidityParameters.higherLiquidityAmountRewardFee;
        } else if (amountIn > activeAmountBaseLiquidityParameters.mediumLiquidityAmountTrigger) {
            return activeAmountBaseLiquidityParameters.mediumLiquidityAmountRewardFee;
        } else {
            return 0;
        }
    }

    function _calculateTimeBaseRewards(address sender, IERC20 token) private view returns (uint256) {
        if (!activeIncentiveFactor.timeBaseLiquidity) {
            return 0;
        }

        LPInfo memory info = lpInfos[sender][token];

        uint256 duration = block.timestamp - info.liquidityStartTime;

        if (duration > activeTimeBaseLiquidityParameters.higherLiquidityTimeTrigger) {
            return activeTimeBaseLiquidityParameters.higherLiquidityTimeRewardFee;
        } else if (duration > activeTimeBaseLiquidityParameters.mediumLiquidityTimeTrigger) {
            return activeTimeBaseLiquidityParameters.mediumLiquidityTimeRewardFee;
        } else {
            return 0;
        }
    }
}
