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
    function getFee(address pool) external view returns (uint24);

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
    function setFee(address pool, uint24 fee) external;

    /**
     * @dev Set the position for the given pool
     * @param pool The address of the pool
     * @param i The index of the token to set for the pool
     * @param latestRoundPrice The Latest Round price from Price Aggregator
     * @param predictedPrice The predict price based on forward events
     */
    function setPoolTokenData(
        address pool,
        uint i,
        uint256 latestRoundPrice,
        uint256 predictedPrice
    ) external;


    /**
     * @dev Update the oracle for the given pool
     * @param pool The address of the pool
     */
    function updateOracle(address pool) external;
}
