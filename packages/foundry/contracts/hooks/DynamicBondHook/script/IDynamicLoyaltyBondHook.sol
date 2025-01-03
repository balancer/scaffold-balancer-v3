pragma solidity ^0.8.24;

interface IDynamicBondHook {
    struct BondInfo {
        uint256 bondAmount;          // Amount of bond staked by the user
        uint256 bondStartTime;       // Timestamp when the bond was started
        uint256 lastRewardClaimed;   // Last time the user claimed rewards
        uint256 currentTier;         // Current bond tier of the user
        uint256 maturityTime;        // Time until the bond matures
    }

    struct TierInfo {
        uint256 maturityPeriod;      // Duration for maturity
        uint256 swapFeeRefund;       // Percentage of swap fee refunded
        uint256 multiplierBoost;      // Multiplier for rewards during specific phases
        bool governanceAccess;       // Eligibility for governance
        uint256 rewardRate;          // Rate at which rewards are accumulated
        string description;          // Description of the tier benefits
    }

    event BondCreated(address indexed user, uint256 amount, uint256 tier);
    event BondClaimed(address indexed user, uint256 rewards);

    function bondInfo(address user) external view returns (
        uint256 bondAmount,
        uint256 bondStartTime,
        uint256 lastRewardClaimed,
        uint256 currentTier,
        uint256 maturityTime
    );

    function getTierInfo(uint256 tier) external view returns (TierInfo memory);
    function calculateRewards(address user) external view returns (uint256);
    function claimRewards(address user) external returns (uint256);
    function getCurrentBondTier(address user) external view returns (uint256);
    function getFeeDiscount(address user) external view returns (uint256);
}
