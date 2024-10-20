// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoyaltyDiscount {
    function getSwapFeeWithLoyaltyDiscount(
        address user,
        uint256 staticSwapFeePercentage
    ) external view returns (uint256);

    function updateLoyaltyDataForUser(
        address user,
        address tokenAddress,
        IERC20 tokenIn,
        uint256 amountInScaled18,
        uint256 amountOutScaled18
    ) external;
}
