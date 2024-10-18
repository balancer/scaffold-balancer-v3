// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ILendingPoolV3 {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveDataLegacy {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    function getReserveData(address asset) external view returns (ReserveDataLegacy memory);

    // @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    // @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
