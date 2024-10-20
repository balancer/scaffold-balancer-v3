// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./IDynamicBondHook.sol";

contract DynamicBondMetadata {
    using Counters for Counters.Counter;
    
    // Mapping to store metadata for each tier
    mapping(IDynamicBondHook.BondTier => IDynamicBondHook.TierInfo) public tierInfo;

    constructor() {
        // Initialize tier info with new names and details
        tierInfo[IDynamicBondHook.BondTier.ExplorerBond] = IDynamicBondHook.TierInfo({
            maturityPeriod: 2 weeks,
            swapFeeRefund: 5,
            multiplierBoost: 0, // No multiplier for this tier
            governanceAccess: false,
            rewardRate: 100, // Example value; adjust as needed
            description: "Explorer Bond: 5% refund on swap fees, entry into Balancer’s weekly lotteries."
        });

        tierInfo[IDynamicBondHook.BondTier.StrategistBond] = IDynamicBondHook.TierInfo({
            maturityPeriod: 2 months,
            swapFeeRefund: 15,
            multiplierBoost: 2, // 2x multiplier during low-liquidity phases
            governanceAccess: false,
            rewardRate: 200, // Example value; adjust as needed
            description: "Strategist Bond: 15% fee refund, 2x multiplier boost during low-liquidity phases."
        });

        tierInfo[IDynamicBondHook.BondTier.VeteranBond] = IDynamicBondHook.TierInfo({
            maturityPeriod: 6 months,
            swapFeeRefund: 40,
            multiplierBoost: 0, // No multiplier for this tier
            governanceAccess: true,
            rewardRate: 300, // Example value; adjust as needed
            description: "Veteran Bond: 40% fee refund, seasonal bonuses, governance access boost."
        });
    }

    // Function to get tier info
    function getTierInfo(IDynamicBondHook.BondTier tier) external view returns (IDynamicBondHook.TierInfo memory) {
        return tierInfo[tier];
    }
}
