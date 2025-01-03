//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DeployMockTokens} from "./00-DeployMockTokens.s.sol";
import {DeployConstantSumPool} from "./01-DeployConstantSumPool.s.sol";
import {DeployConstantProductPool} from "./02-DeployConstantProductPool.s.sol";

import {OrderHook} from "../../contracts/hooks/OrderHook.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {Script, console} from "forge-std/Script.sol";

contract PlaceOrder is Script {
    function run() public {
        placeOrder();
    }

    function placeOrder() public {
        HelperConfig helperConfig = new HelperConfig();
        DeployMockTokens deployTokens = new DeployMockTokens();
        DeployConstantSumPool deployConstantSumPool = new DeployConstantSumPool();
        //DeployConstantProductPool deployConstantProductPool = new DeployConstantProductPool();

        (address mockToken1, address mockToken2, ) = deployTokens
            .deployMockTokens();

        (address orderHook, address pool) = deployConstantSumPool
            .deployConstantSumPool(mockToken1, mockToken2);

        console.log(
            "Account balance: ",
            IERC20(mockToken1).balanceOf(helperConfig.getConfig().account) /
                1e18
        );

        vm.startBroadcast(helperConfig.getConfig().account);
        IERC20(mockToken1).approve(orderHook, 1e18);
        bytes32 orderId = OrderHook(payable(orderHook)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            1e18,
            1e18,
            pool,
            mockToken1,
            mockToken2,
            3
        );

        console.log("Order ID:");
        console.logBytes32(orderId);

        /* deployConstantProductPool.deployConstantProductPool(
            mockToken1,
            mockToken2
        ); */
    }
}
