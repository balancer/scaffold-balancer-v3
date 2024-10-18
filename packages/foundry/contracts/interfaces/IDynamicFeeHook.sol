// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDynamicFeeHook {
    struct LockInfo {
        uint128 bptLocked;
        uint128 accruedRewards;
        uint128 rewardDebt;
        uint128 lockStart;
    }

    struct PoolInfo {
        uint128 bptLocked;
        uint128 lastRewardBalance;
        uint128 accRewardsPerShare;
        address feeToken;
        address rewardToken; // an aToken of the AAVE lending
    }

    // Events

    event DynamicFeeHookRegistered(address indexed hooksContract, address indexed factory, address indexed pool);
    event HookFeeInvested(address indexed hooksContract, IERC20 indexed token, uint256 feeAmount);
    event InvestPoolAdded(address _pool, address _asset);
    event EarlyUnlockSet(bool _allowedEarlyUnlock);
    event MinLockDurationSet(uint256 _minLockDuration);

    // Errors

    error AlreadyExist();
}
