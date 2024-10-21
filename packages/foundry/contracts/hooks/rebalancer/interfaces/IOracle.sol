// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

/**
 * @param latestRoundPrice It is the latest pice from the Oracle
 * @param predicitedPrice It is the Prediction Price from forward event oracle
 * @param rebalanceRequired It is true if the current price is changed above the
 * minChangeForBalance in which case the pool runs the _rebalance function
 */
struct TokenData {
    uint256 latestRoundPrice;
    uint256 predictedPrice;
}

/**
 * @dev Interface for the rebalancer oracle
 */

interface IOracle {
    /**
     * @dev Get the current fee for the given pool
     * @param pool The address of the pool
     * @return The current fee
     */
    function getFee(address pool) external view returns (uint256);

    /**
     * @dev Get the current position for the given pool
     * @param pool The address of the pool
     * @return The current position
     */
    function getPoolTokensData(address pool) external view returns (TokenData[] memory);

    /**
     * @dev Set the fee for the given pool
     * @param pool The address of the pool
     * @param fee The fee to set
     */
    function setFee(address pool, uint256 fee) external;

    /**
     * @dev Set the position for the given pool
     * @param pool The address of the pool
     * @param _tokensData The TokenData[] array to set
     */
    function setPoolTokensData(
        address pool,
        TokenData[] memory _tokensData
    ) external;

}
