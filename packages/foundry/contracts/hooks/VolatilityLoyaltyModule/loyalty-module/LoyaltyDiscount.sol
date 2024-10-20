// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILoyaltyDiscount.sol";

import "forge-std/console.sol";

contract LoyaltyDiscount is ILoyaltyDiscount {
    using FixedPoint for uint256;

    uint256 private constant _LOYALTY_REFRESH_WINDOW = 30 days;
    uint256 private constant _LOYALTY_FEE_CAP = 0.01e18; // 1 %

    mapping(address => LoyaltyData) public userLoyaltyData;

    struct LoyaltyData {
        uint256 firstTransactionTimestamp; // first transaction in the _LOYALTY_INDEX_REFRESH_TIME window, the _LOYALTY_REFRESH_WINDOW value is same, but the start and end timestamps of the window is different for each user
        uint256 cumulativeLoyalty; // change name to loyalty index, its dimension/unit it token * seconds
        uint256 tokens;
        uint256 lastTimestamp; // make it lastTransactionTImestamp
    }

    function getSwapFeeWithLoyaltyDiscount(
        address user,
        uint256 staticSwapFeePercentage
    ) public view returns (uint256) {
        uint256 loyaltyIndex = getCurrentLoyaltyIndex(userLoyaltyData[user]);
        bool isStaticFeeGreaterThanLoyaltyFeeCap = staticSwapFeePercentage > 0.01e18;

        uint256 fixedFee = staticSwapFeePercentage;
        uint256 loyaltyFee = 0;
        uint256 variableFee = 0;

        uint256 loyaltyDiscount = getLoyaltyDiscount(uint256(loyaltyIndex));
        console.log("(getSwapFeeWithLoyaltyDiscount) loyaltyIndex, loyaltyDiscount", loyaltyIndex, loyaltyDiscount);

        // idea is to first apply a flat fee of 1%, over and above that apply any loyalty discount but have a limit on it
        // fixedFee will be minimum 1%, anything extra goes into loyalty fee unless it reaches the cap of _LOYALTY_FEE_CAP, anything above goes into variable fee
        // so if staticSwapFeePercentage = 5 and _LOYALTY_FEE_CAP = 2, then fixedFee = 1%, loyaltyFee = 2% and variableFee = 3%, loyalty discount will be applied only on the 2% loyalty fee
        // so maximum loyalty discount anyone can achieve is 2%, at the same time no one is paying less than 1%, maybe more (in this case, 1 + 3 = 4%)

        if (isStaticFeeGreaterThanLoyaltyFeeCap) {
            fixedFee = 0.01e18; // 1% will be applied
            variableFee = staticSwapFeePercentage > fixedFee + _LOYALTY_FEE_CAP
                ? staticSwapFeePercentage - (fixedFee + _LOYALTY_FEE_CAP)
                : 0;

            loyaltyFee =
                ((staticSwapFeePercentage - (fixedFee + variableFee)) * (FixedPoint.ONE - loyaltyDiscount)) /
                FixedPoint.ONE;
        }

        uint256 totalFee = fixedFee + loyaltyFee + variableFee;

        console.log(
            "(getSwapFeeWithLoyaltyDiscount) fixedFee + loyaltyFee + variableFee",
            fixedFee,
            loyaltyFee,
            variableFee
        );

        console.log("(getSwapFeeWithLoyaltyDiscount) totalFee", totalFee);

        return totalFee;
    }

    function updateLoyaltyDataForUser(
        address user,
        address tokenAddress,
        IERC20 tokenIn,
        uint256 amountInScaled18,
        uint256 amountOutScaled18
    ) public {
        LoyaltyData memory loyaltyData = userLoyaltyData[user];

        uint256 currentTimestamp = block.timestamp;

        console.log("(onAfterSwap) currentTimestamp", currentTimestamp);

        uint256 oldFirstTransactionTimestamp = loyaltyData.firstTransactionTimestamp;

        bool isLoyaltyWindowRefreshed = (currentTimestamp - oldFirstTransactionTimestamp) >= _LOYALTY_REFRESH_WINDOW;

        console.log(
            "(onAfterSwap) isLoyaltyWindowRefreshed, loyaltyData.tokens",
            isLoyaltyWindowRefreshed,
            uint256(loyaltyData.tokens)
        );

        // instead of old make it current
        uint256 oldTimestamp = loyaltyData.lastTimestamp;
        uint256 oldCumulativeLoyalty = isLoyaltyWindowRefreshed ? 0 : loyaltyData.cumulativeLoyalty;
        uint256 oldTokens = isLoyaltyWindowRefreshed ? 0 : loyaltyData.tokens;

        console.log("(onAfterSwap) userLoyaltyData[user] oldFirstTransactionTimestamp", oldFirstTransactionTimestamp);

        console.log(
            "(onAfterSwap) oldCumulativeLoyalty, oldTokens, oldTimestamp",
            uint256(oldCumulativeLoyalty),
            uint256(oldTokens),
            oldTimestamp
        );

        // cumulative loyalty and tokens should always be positive
        uint256 newCumulativeLoyalty = oldCumulativeLoyalty + (oldTokens * (currentTimestamp - oldTimestamp)); // remove this comment before submission, y = mx + c, y-> new cumulative loyalty, m -> tokens held, x -> time passed, c -> cumulative loyalty so far
        int256 additionalTokens = (address(tokenIn) == tokenAddress)
            ? -1 * int256(amountInScaled18)
            : int256(amountOutScaled18);
        uint256 newTimestamp = currentTimestamp;
        uint256 newFirstTransactionTimestamp = isLoyaltyWindowRefreshed
            ? currentTimestamp
            : oldFirstTransactionTimestamp;

        uint256 newTokens = (additionalTokens + int256(oldTokens)) > 0
            ? uint256(additionalTokens + int256(oldTokens))
            : 0; // loyalty and tokens can never be zero

        userLoyaltyData[user] = LoyaltyData(
            newFirstTransactionTimestamp,
            newCumulativeLoyalty,
            newTokens,
            newTimestamp
        );

        console.log(
            "(onAfterSwap) userLoyaltyData[user] firstTransactionTimestamp",
            userLoyaltyData[user].firstTransactionTimestamp
        );

        console.log(
            "(onAfterSwap) userLoyaltyData[user] newCumulativeLoyalty, newTokens, newTimestamp",
            uint256(userLoyaltyData[user].cumulativeLoyalty),
            uint256(userLoyaltyData[user].tokens),
            userLoyaltyData[user].lastTimestamp
        );
    }

    // a rough estimation of tiers
    // the thought behind the tiers is that how many tokens were bought at the beginning of the _LOYALTY_REFRESH_WINDOW and held till the end of the window
    // so 1000 tokens are minted initially and can be bought and held for _LOYALTY_REFRESH_WINDOW days, so max loyalty index is 1000 * _LOYALTY_REFRESH_WINDOW
    // so tier it in a way so that if someone has generated loyaltyIndex equivalent to buying at least 1% tokens and held it for the entire _LOYALTY_REFRESH_WINDOW  duration gets full discount
    function getLoyaltyDiscount(uint256 loyaltyIndex) internal pure returns (uint256) {
        if (loyaltyIndex > 0 && loyaltyIndex <= 2 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE) {
            return 0.1e18; // 10% discount
        } else if (
            loyaltyIndex > 2 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE &&
            loyaltyIndex <= 5 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE
        ) {
            return 0.3e18; // 30% discount
        } else if (
            loyaltyIndex > 5 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE &&
            loyaltyIndex <= 10 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE
        ) {
            return 0.5e18; // 50% discount
        } else if (loyaltyIndex > 10 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE) {
            return 1e18; // 100% discount -> does not mean there won't be any fee, refer to onComputeDynamicSwapFeePercentage
        } else {
            return 0; // Default return value if loyaltyIndex does not fit any of the above conditions
        }
    }

    function getCurrentLoyaltyIndex(LoyaltyData memory loyaltyData) internal view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 oldFirstTransactionTimestamp = loyaltyData.firstTransactionTimestamp;
        bool isLoyaltyWindowRefreshed = (currentTimestamp - oldFirstTransactionTimestamp) >= _LOYALTY_REFRESH_WINDOW;
        uint256 oldTimestamp = loyaltyData.lastTimestamp;
        uint256 oldCumulativeLoyalty = isLoyaltyWindowRefreshed ? 0 : loyaltyData.cumulativeLoyalty;
        uint256 oldTokens = isLoyaltyWindowRefreshed ? 0 : loyaltyData.tokens;
        uint256 newCumulativeLoyalty = oldCumulativeLoyalty + (oldTokens * (currentTimestamp - oldTimestamp));

        return newCumulativeLoyalty;
    }
}
