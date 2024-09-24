// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface ISwapDiscountHook {
    error poolCampaignAlreadyExist();

    /// Event emitted when a discount is granted
    event SwapDiscountGranted(uint256 indexed id, address indexed user, uint256 expiration, uint256 amount);

    /// Struct to store discount data for a user
    struct UserSwapData {
        address userAddress;
        address campaignAddress;
        uint256 swappedAmount;
        uint256 timeOfSwap;
    }

    struct CampaignData {
        address campaignAddress;
        address owner;
        uint256 timeOfCreation;
    }

    /// Mapping from token ID to user swap data
    function userDiscountMapping(
        uint256 tokenId
    ) external view returns (address userAddress, address campaignAddress, uint256 swappedAmount, uint256 timeOfSwap);

    /// Mapping from token ID to user swap data
    function discountCampaigns(
        address campaign
    ) external view returns (address campaignAddress, address owner, uint256 timeOfCreation);
}
