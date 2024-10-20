// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";


import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import {console} from "forge-std/console.sol";


contract SampleSwap is Script {
    IRouter internal router = IRouter(0x77eDc69766409C599F06Ef0B551a0990CBfe13A7); // router given in docs
    IPermit2 internal permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3); // permit2 given in docs
    

    function run() external {
        // The 2 mock tokens of my 50 50 weighted liquidity pool
        IERC20 tokenIn = IERC20(0x239e733ff339495Df5d28730b5cAd2f77fE27407);
        IERC20 tokenOut = IERC20(0x40d514790c1c0528e7143def9104AeBbf54fF1ce);
        // permit2.approve(0x239e733ff339495Df5d28730b5cAd2f77fE27407, )
        // console.log(msg.sender);
        address fromAddr = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
        tokenIn.approve(address(fromAddr), 10000 * 1e18);

        uint256 amountOut = router.swapSingleTokenExactIn(
            0xEA34209c9c86b358Ebf9C92156aA8D12b81508B6, // my pool address
            tokenIn,
            tokenOut,
            10 * 1e18,
            2 * 1e18,
            block.timestamp + 600,
            false,
            ""
        );
        console.log("Amount out: %s", amountOut);
    }
}


contract SampleAddLiquidity is Script {
    IRouter internal router = IRouter(0x77eDc69766409C599F06Ef0B551a0990CBfe13A7);
    function run() external {
        // IERC20 tokenIn = IERC20(0x239e733ff339495Df5d28730b5cAd2f77fE27407);
        // IERC20 tokenOut = IERC20(0x40d514790c1c0528e7143def9104AeBbf54fF1ce);
        uint256[] memory amountsIn = new uint256[](1);
        amountsIn[0] = 1 * 1e18;
        // amountsIn[1] = 2 * 1e18;
        uint256 bptOut = 100 * 1e18;

        uint256[] memory amountIn =  router.addLiquidityProportional(
            0xEA34209c9c86b358Ebf9C92156aA8D12b81508B6,
            amountsIn,
            bptOut,
            false,
            "");

        console.log("Amount out: ", amountIn[0], amountIn[1]);
    }
}


contract SampleDonate is Script {
    IRouter internal router = IRouter(0x77eDc69766409C599F06Ef0B551a0990CBfe13A7);
    function run() external {
        // IERC20 token1 = IERC20(0x239e733ff339495Df5d28730b5cAd2f77fE27407);
        // IERC20 token2 = IERC20(0x40d514790c1c0528e7143def9104AeBbf54fF1ce);
        IERC20(0x239e733ff339495Df5d28730b5cAd2f77fE27407).approve(address(router), 100000 * 1e18);
        IERC20(0x40d514790c1c0528e7143def9104AeBbf54fF1ce).approve(address(router), 200000 * 1e18);
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = 100 * 1e18;
        amountsIn[1] = 200 * 1e18;

        router.donate(
            address(0xEA34209c9c86b358Ebf9C92156aA8D12b81508B6),
            amountsIn,
            false,
            ""
        );
        
        // console.log("Amount out: %s", amountIn);
    }
}


