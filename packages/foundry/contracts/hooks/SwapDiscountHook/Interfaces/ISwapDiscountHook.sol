// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface ISwapDiscountHook {
    /// Event emitted when a discount is granted
    event SwapDiscountGranted(uint256 indexed id, address indexed user, uint256 expiration, uint256 amount);

    /// Struct to store discount data for a user
    struct UserSwapData {
        address userAddress;
        uint256 discountedTokenAmount;
        uint256 expirationTime;
    }

    /// Mapping from token ID to user swap data
    function userDiscountMapping(
        uint256 tokenId
    ) external view returns (address userAddress, uint256 discountedTokenAmount, uint256 expirationTime);
}
