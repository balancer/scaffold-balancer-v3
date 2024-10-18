//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DeployMockTokens} from "./00-DeployMockTokens.s.sol";
import {DeployConstantSumPool} from "./01-DeployConstantSumPool.s.sol";
import {DeployConstantProductPool} from "./02-DeployConstantProductPool.s.sol";

import {OrderHook} from "../../contracts/hooks/OrderHook.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {Script, console} from "forge-std/Script.sol";

contract ExecuteOrder is Script {
    function run() public {
        executeOrder();
    }

    function executeOrder() public {
        HelperConfig helperConfig = new HelperConfig();
        DeployMockTokens deployTokens = new DeployMockTokens();
        //DeployConstantSumPool deployConstantSumPool = new DeployConstantSumPool();
        DeployConstantProductPool deployConstantProductPool = new DeployConstantProductPool();

        (address mockToken1, address mockToken2, ) = deployTokens
            .deployMockTokens();

        /* (address orderHook, address pool) = deployConstantSumPool
            .deployConstantSumPool(mockToken1, mockToken2); */

        (address orderHook, address pool) = deployConstantProductPool
            .deployConstantProductPool(mockToken1, mockToken2);

        vm.startBroadcast(helperConfig.getConfig().account);

        bytes32 orderId = placeOrder(
            mockToken1,
            mockToken2,
            helperConfig,
            orderHook,
            pool
        );

        console.log("Order ID:");
        console.logBytes32(orderId);

        console.log(
            "Account MockToken1 balance after order: ",
            IERC20(mockToken1).balanceOf(helperConfig.getConfig().account) /
                1e16
        );
        console.log(
            "Account MockToken2 balance after order: ",
            IERC20(mockToken2).balanceOf(helperConfig.getConfig().account) /
                1e16
        );

        uint256[] memory poolPrice = IVault(helperConfig.getConfig().vault)
            .getCurrentLiveBalances(pool);

        uint256 limit = ((((1e18 * poolPrice[0]) / poolPrice[1]) * (100 - 4)) /
            100);

        uint256 amountOut = IRouter(payable(helperConfig.getConfig().router))
            .swapSingleTokenExactIn(
                pool,
                IERC20(mockToken1),
                IERC20(mockToken2),
                1e18,
                limit,
                block.timestamp + 1 hours,
                false,
                ""
            );
        console.log("Amount out: ", amountOut / 1e16);

        console.log(
            "Account MockToken1 balance after swap: ",
            IERC20(mockToken1).balanceOf(helperConfig.getConfig().account) /
                1e16
        );
        console.log(
            "Account MockToken2 balance after swap: ",
            IERC20(mockToken2).balanceOf(helperConfig.getConfig().account) /
                1e16
        );

        OrderHook(payable(orderHook)).executeOrder(orderId, "");

        vm.stopBroadcast();

        console.log(
            "Account MockToken1 balance after order execution: ",
            IERC20(mockToken1).balanceOf(helperConfig.getConfig().account) /
                1e16
        );
        console.log(
            "Account MockToken2 balance after order execution: ",
            IERC20(mockToken2).balanceOf(helperConfig.getConfig().account) /
                1e16
        );
    }

    function placeOrder(
        address mockToken1,
        address mockToken2,
        HelperConfig helperConfig,
        address orderHook,
        address pool
    ) public returns (bytes32 orderId) {
        console.log(
            "Account MockToken1 balance: ",
            IERC20(mockToken1).balanceOf(helperConfig.getConfig().account) /
                1e16
        );
        console.log(
            "Account MockToken2 balance: ",
            IERC20(mockToken2).balanceOf(helperConfig.getConfig().account) /
                1e16
        );

        IERC20(mockToken1).approve(orderHook, 1e18);
        orderId = OrderHook(payable(orderHook)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            1e18,
            1e18,
            pool,
            mockToken1,
            mockToken2,
            4
        );
    }
}
