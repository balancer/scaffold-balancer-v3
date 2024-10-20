// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

interface IVolatilityDiscount {
    function getVolatilityFeePercent(address oracleAddress) external view returns (uint256);
}
