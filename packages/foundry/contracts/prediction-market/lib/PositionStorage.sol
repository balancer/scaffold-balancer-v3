// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { 
    Position,
    PredictionMarket 
} from '../Types.sol';

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library PositionStorage { 

    /// @notice the user position does not have enough balance to apply the given delta
    error InsufficentPositionBalance(bytes32 market, address user, uint256 balance, int256 delta);

    /**
     * @notice get the claimable token balance from the market
     * @dev technically we can pass markets that are not closed here and be okay since the closing values
     * for the bull/bear sides would not have been set.
     * @param self The user position
     * @param market the closed market
     */
    function getClaimableBalance(
        Position memory self,
        PredictionMarket memory market
    ) internal returns (uint256 claimAmount) {
        uint256 claimTokenMultiplier = 10**IERC20Metadata(market.token0).decimals();

        uint256 bullValue = Math.mulDiv(self.bullAmount, market.closingBullValue, claimTokenMultiplier);
        uint256 bearValue = Math.mulDiv(self.bearAmount, market.closingBearValue, claimTokenMultiplier);

        return bullValue + bearValue;
    }

    /**
     * @notice update a user position with the given delta amounts
     * @dev reverts if the operation would end with the user having a negative balance
     * @param self the mapping from marketId to user position
     * @param marketId the market to modify
     * @param account the account to modify
     * @param bullDelta change in the bull balance
     * @param bearDelta change in the bear balance
     * @return position the updated position
     */
    function applyPositionDelta(
        mapping(bytes32 => mapping(address => Position)) storage self,
        bytes32 marketId,
        address account,
        int256 bullDelta,
        int256 bearDelta
    ) internal returns (Position memory position) {
        position = self[marketId][msg.sender];
        
        position.bullAmount = _getPositionBalance(marketId, account, position.bullAmount, bullDelta);
        position.bearAmount = _getPositionBalance(marketId, account, position.bearAmount, bearDelta);

        self[marketId][msg.sender] = position;

        return position;
    }

    /**
     * @notice get the new position balance after applying the given delta
     * @param marketId the market to modify
     * @param account the account to modify
     * @param currentBalance the current user balance
     * @param delta the delta amount
     * @return amount the ending user balance
     */
    function _getPositionBalance(
        bytes32 marketId,
        address account,
        uint256 currentBalance,
        int256 delta
    ) private pure returns (uint256 amount) {
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