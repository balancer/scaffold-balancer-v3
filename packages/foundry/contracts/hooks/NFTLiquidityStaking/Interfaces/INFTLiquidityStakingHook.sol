// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INFTLiquidityStakingHook {
    struct StakingInfo {
        uint256 stakedAmount;
        uint256 stakingStartTime;
        uint256 lastMilestoneTime;
        uint256 currentTier;
        uint256 lastRewardClaim;
    }

    event NFTMinted(address indexed user, address indexed pool, uint256 tokenId, uint256 tier);
    event LiquidityRemoved(address indexed user, address indexed pool, uint256 amount);

    function stakingInfo(address user, address pool) external view returns (
        uint256 stakedAmount,
        uint256 stakingStartTime,
        uint256 lastMilestoneTime,
        uint256 currentTier,
        uint256 lastRewardClaim
    );

    function getRemainingCooldownTime(address user, address pool) external view returns (uint256);
    function getFeeDiscount(address user, address pool) external view returns (uint256);
    function getVotingPower(address user, address pool) external view returns (uint256);
    function getYieldBoost(address user, address pool) external view returns (uint256);
}