// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ATokenMock } from "./ATokenMock.sol";
import { FeeTokenMock } from "./FeeTokenMock.sol";
import { ILendingPoolV3 } from "../../contracts/interfaces/ILendingPoolV3.sol";

contract LendingPoolMock is ILendingPoolV3 {
    address public feeToken;
    address public aToken;

    constructor(address _feeToken, address _aToken) {
        feeToken = _feeToken;
        aToken = _aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /*referralCode*/) external {
        FeeTokenMock(asset).transferFrom(msg.sender, address(this), amount);

        ATokenMock(asset).mint(onBehalfOf, amount);
        return;
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        ATokenMock(asset).burn(to, amount);

        FeeTokenMock(asset).mint(msg.sender, amount);
        return amount;
    }

    function getReserveData(address) external view returns (ReserveDataLegacy memory) {
        ILendingPoolV3.ReserveConfigurationMap memory config = ReserveConfigurationMap(0);
        config.data = 0;

        return
            ReserveDataLegacy({
                configuration: config,
                liquidityIndex: 0,
                currentLiquidityRate: 0,
                variableBorrowIndex: 0,
                currentVariableBorrowRate: 0,
                currentStableBorrowRate: 0,
                lastUpdateTimestamp: 0,
                id: 0,
                aTokenAddress: aToken,
                stableDebtTokenAddress: address(0),
                variableDebtTokenAddress: address(0),
                interestRateStrategyAddress: address(0),
                accruedToTreasury: 0,
                unbacked: 0,
                isolationModeTotalDebt: 0
            });
    }
}
