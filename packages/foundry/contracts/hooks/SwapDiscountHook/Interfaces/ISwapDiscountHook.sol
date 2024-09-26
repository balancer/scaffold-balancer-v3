// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface ISwapDiscountHook {
    error poolCampaignAlreadyExist();
    error InvalidRewardToken();
    error NOT_AUTHORIZED();

    /// Event emitted when a discount is granted
    event SwapDiscountGranted(uint256 indexed id, address indexed user, uint256 expiration, uint256 amount);
}
