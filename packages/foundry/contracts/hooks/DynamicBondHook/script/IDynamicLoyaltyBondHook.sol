pragma solidity ^0.8.24;

interface IDynamicBondHook {
    enum BondTier {
    ExplorerBond,
    StrategistBond,
    VeteranBond
    }

    struct TierInfo {
        uint256 maturityPeriod;
        uint256 swapFeeRefund;
        uint256 multiplierBoost;
        bool governanceAccess;
        uint256 rewardRate;
        string description; // A description for the tier
    }

    // Function to register a bond
    function registerBond(address user, BondTier tier, uint256 amount) external;

    // Function to get bond perks
    function getBondPerks(address user) external view returns (TierInfo memory);

    // Function to check governance eligibility
    function isGovernanceEligible(address user) external view returns (bool, string memory);

    // Function to adjust tier parameters
    function setTierInfo(
        BondTier tier,
        uint256 maturityPeriod,
        uint256 swapFeeRefund,
        uint256 multiplierBoost,
        bool governanceAccess,
        uint256 rewardRate
    ) external;
    
    // Additional functionality as per your DynamicBondHook requirements
}
