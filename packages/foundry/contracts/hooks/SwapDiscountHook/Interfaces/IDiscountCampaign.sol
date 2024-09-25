// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

interface IDiscountCampaign {
    error InvalidTokenID();
    error DiscountExpired();
    error RewardAlreadyClaimed();
    error RewardAmountExpired();
}
