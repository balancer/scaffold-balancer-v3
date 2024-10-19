// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { Position } from '../Types.sol';

library PositionStorage { 

    error InsufficentPositionBalance(bytes32 market, address user, uint256 balance, int256 delta);

    function applyPositionDelta(
        mapping(bytes32 => mapping(address => Position)) storage self,
        bytes32 marketId,
        address account,
        int256 bullDelta,
        int256 bearDelta
    ) internal returns (Position memory) {
        Position memory position = self[marketId][msg.sender];
        
        position.bullAmount = _getPositionBalance(marketId, account, position.bullAmount, bullDelta);
        position.bearAmount = _getPositionBalance(marketId, account, position.bearAmount, bearDelta);

        self[marketId][msg.sender] = position;

        return position;
    }

    function _getPositionBalance(
        bytes32 marketId,
        address account,
        uint256 currentBalance,
        int256 delta
    ) private pure returns (uint256) {
        if(delta >= 0){
            return currentBalance + uint256(delta);
        }

        uint256 subAmount = uint256(delta * -1);

        if(currentBalance < subAmount){
            revert InsufficentPositionBalance(marketId, account, currentBalance, delta);
        }

        return currentBalance - subAmount;
    }
}