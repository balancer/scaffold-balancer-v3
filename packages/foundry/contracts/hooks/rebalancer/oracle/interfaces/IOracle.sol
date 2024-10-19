// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;


/**
 * @dev Struct for holding position for the token
 */
struct PositionData{
    uint24 tickUpper;
    uint24 tickLower;
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
    function getPosition(address pool) external view returns (Position memory);


    /**
     * @dev Set the fee for the given pool
     * @param pool The address of the pool
     * @param fee The fee to set
     */
    function setFee(address pool, uint24 fee) external;

    /**
     * @dev Set the position for the given pool
     * @param pool The address of the pool
     * @param _lowerTick The lower tick boundry
     * @param _upperTick The upper tick boundry
     */
    function setPositionData(address pool, uint24 _lowerTick, uint24 _upperTick) external;

    /**
     * @dev Update the oracle for the given pool
     * @param pool The address of the pool
     */
    function updateOracle(address pool) external;

}