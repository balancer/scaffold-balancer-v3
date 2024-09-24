// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IDiscountCampaign } from "./Interfaces/IDiscountCampaign.sol";
import { ISwapDiscountHook } from "./Interfaces/ISwapDiscountHook.sol";

contract DiscountCampaign is IDiscountCampaign, Ownable {
    uint256 public rewardAmount;
    uint256 public expirationTime;
    uint256 public coolDownPeriod;
    uint256 public discountRate;
    address public rewardToken;

    uint256 public tokenRewardDistributed;

    uint256 private _previousDiscountRate;
    ISwapDiscountHook private _swapHook;

    constructor(
        uint256 _rewardAmount,
        uint256 _expirationTime,
        uint256 _coolDownPeriod,
        uint256 _discountAmount,
        address _rewardToken,
        address _owner,
        address _hook
    ) Ownable(_owner) {
        rewardAmount = _rewardAmount;
        expirationTime = _expirationTime;
        coolDownPeriod = _coolDownPeriod;
        discountRate = _discountAmount;
        rewardToken = _rewardToken;
        _swapHook = ISwapDiscountHook(_hook);
    }

    function claim(uint256 tokenID) public {
        (address user, , , ) = _swapHook.userDiscountMapping(tokenID);
        IERC721(address(_swapHook)).safeTransferFrom(msg.sender, address(this), tokenID);
        uint256 reward = _getClaimableRewards(tokenID);
        IERC20(rewardToken).transferFrom(address(this), user, reward);
        updateDiscount();
    }

    function getClaimableReward(uint256 tokenID) external view returns (uint256) {
        return _getClaimableRewards(tokenID);
    }

    function _getClaimableRewards(uint256 tokenID) internal view returns (uint256 claimableReward) {
        (, address campaignAddress, uint256 swappedAmount, uint256 timeOfSwap) = _swapHook.userDiscountMapping(tokenID);
        claimableReward = 0;
        if (campaignAddress != address(this)) {
            revert InvalidTokenID();
        }

        if (timeOfSwap > expirationTime) {
            revert DiscountExpired();
        }

        claimableReward = (swappedAmount * discountRate) / 100e18;
    }

    function updateDiscount() internal {
        discountRate = discountRate * (1 - tokenRewardDistributed / rewardAmount);
    }
}
