// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { BaseTest } from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseTest.sol";
import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { IVaultMock } from "@balancer-labs/v3-interfaces/contracts/test/IVaultMock.sol";
import { IVaultExtension } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { BasicAuthorizerMock } from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { BatchRouterMock } from "@balancer-labs/v3-vault/contracts/test/BatchRouterMock.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { VaultMockDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultMockDeployer.sol";
import { SetAndForgetSwapHook } from "../contracts/hooks/SetAndForgetSwapHook.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { ConstantProductFactory } from "../contracts/factories/ConstantProductFactory.sol";
import { ConstantProductPool } from "../contracts/pools/ConstantProductPool.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { OrderBook } from "../contracts/CustomRouter.sol";

import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import { DateTime } from "solidity-datetime/contracts/DateTime.sol";

contract SetAndForgetSwapHookTest is BaseVaultTest {
    using ArrayHelpers for *;
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    

    uint256 internal wstethIdx;
    uint256 internal usdcIdx;
    
    // SetAndForgetSwapHook hook is both the router and hook
    SetAndForgetSwapHook internal safsRouter;
    // ConstantProductFactory 
    ConstantProductFactory internal cpFactory;

    function setUp() public override {
        super.setUp();
                
        (wstethIdx, usdcIdx) = getSortedIndexes(address(wsteth), address(usdc));

        //   uint256 maxExecutionTime = DateTime.timestampFromDateTime( 
        //     2024,
        //     10,
        //     21,
        //     10,
        //     15, 
        //     0
        // );


        // uint256 _minTokenInExecutionPrice = safsRouter.queryTokenRateXY(pool, usdcIdx, wstethIdx);
        // uint256 _maxTokenInExecutionPrice = _minTokenInExecutionPrice + 2e18;

        // vm.startPrank(bob);
        // IERC20(address(wsteth)).approve(address(safsRouter.orderBook()), 1e18);
        // safsRouter.orderBook().placeLimitOrder(1e18, maxExecutionTime, _minTokenInExecutionPrice, _maxTokenInExecutionPrice, address(wsteth), address(usdc));
        // vm.stopPrank();
    }

    
    function initPool() internal override {
        vm.startPrank(lp);
        // Set the initial exchange rate to 3200 USD per wstETH
        // Define the initial token amounts
        uint256 TokenAmountA = 1e9 * 1e18; // 1 billion USDC (6 decimals + 18 for precision)
        uint256 TokenAmountB = 3125 * 1e2 * 1e18; // 312,500 wstETH (18 decimals)
        
        // Calculate the expected BPT (Balancer Pool Token) amount
        // Using the geometric mean of the two token amounts: sqrt(A * B)
        // Not certain if this is a common way to determine initial LP token supply
        uint256 expectedAddLiquidityBptAmountOut = Math.sqrt(TokenAmountB * TokenAmountA);
    
        // Call the _initPool function to initialize the Balancer pool
        _initPool(
            pool, // The address of the Balancer pool
            [TokenAmountB, TokenAmountA].toMemoryArray(), // Array of initial token amounts
            expectedAddLiquidityBptAmountOut - 1e9 // Slightly reduce BPT amount to ensure successful pool creation
        );
        vm.stopPrank();
    }

    function _initPool(
        address poolToInit,
        uint256[] memory amountsIn,
        uint256 minBptOut
    ) internal override returns (uint256 bptOut) {
        (IERC20[] memory tokens, , , ) = vault.getPoolTokenInfo(poolToInit);

        return safsRouter.initialize(poolToInit, tokens, amountsIn, minBptOut, false, bytes(""));
    }  

    function createHook() internal override returns (address) {
        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.startPrank(lp);
        cpFactory = new ConstantProductFactory(IVault(address(vault)), 365 days);
        vm.label(address(cpFactory), "cpFactory");

        safsRouter = new SetAndForgetSwapHook(address(cpFactory), IVault(vault), weth, permit2,  "ExecutorNFTBadge", "ENB SAFS", "OrderCreatoorNFTBadge", "OCNB SAFS");
        vm.label(address(safsRouter), "safsRouter");

        address setAndForgetSwapHook = payable(
            safsRouter
        );

        vm.label(setAndForgetSwapHook, "Set And Forget Swap Hook");

        vm.stopPrank();

        vm.roll(block.number + 1);
        return setAndForgetSwapHook;
    }

    function createPool() internal override returns (address) {
        // lp will be the owner of the pool.
        vm.startPrank(lp);
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        IERC20[] memory sortedTokens = InputHelpers.sortTokens(
            [address(wsteth), address(usdc)].toMemoryArray().asIERC20()
        );

        ConstantProductPool newPool = ConstantProductPool(
            ConstantProductFactory(address(cpFactory)).create(
                "Constant Product Pool", // name
                "CPP", // symbol
                ZERO_BYTES32, // salt
                vault.buildTokenConfig(sortedTokens), // TokenConfig[]
                0.003e18,
                false,
                roleAccounts,
                poolHooksContract,
                liquidityManagement
            )
        ); 
        vm.stopPrank();

        return address(newPool);
    }

    function approveForSender() internal override {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(permit2), type(uint256).max);
            permit2.approve(address(tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(safsRouter), type(uint160).max, type(uint48).max);
        }
    }

    function approveForPool(IERC20 bpt) internal override {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);

            bpt.approve(address(router), type(uint256).max);
            bpt.approve(address(batchRouter), type(uint256).max);
            bpt.approve(address(safsRouter), type(uint256).max);

            IERC20(bpt).approve(address(permit2), type(uint256).max);
            permit2.approve(address(bpt), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(safsRouter), type(uint160).max, type(uint48).max);

            vm.stopPrank();
        }
    }

    function testPlaceOrderAndInstantlyExecute() public {
        vm.startPrank(lp);
        safsRouter.orderBook().executoorRegisterWithRouter();
        vm.stopPrank();
    
        uint256 exactAmountIn = 1e18;
        uint256 expectedAmountOut = 3190 * 1e18;

        vm.startPrank(alice);
        safsRouter.swapSingleTokenExactIn(pool, wsteth, usdc, exactAmountIn, expectedAmountOut, MAX_UINT256, false, bytes(""));
        vm.stopPrank();

        uint256 maxExecutionTime = DateTime.timestampFromDateTime( 
            2024,
            10,
            21,
            10,
            15, 
            0
        );


        uint256 _minTokenInExecutionPrice = safsRouter.queryTokenRateXY(pool, usdcIdx, wstethIdx);
        uint256 _maxTokenInExecutionPrice = _minTokenInExecutionPrice + 2e18;
console.log(_minTokenInExecutionPrice);
        vm.startPrank(bob);
        IERC20(address(wsteth)).approve(address(safsRouter.orderBook()), 5e18);
        safsRouter.orderBook().placeLimitOrder(5e18, maxExecutionTime, _minTokenInExecutionPrice, _maxTokenInExecutionPrice, address(wsteth), address(usdc));
        vm.stopPrank();
        
        vm.startPrank(lp);
        console.log("FIRST ONE");
        console.log(lp);

        console.log("permit2", address(permit2));
        console.log(safsRouter.orderBook().minPricePoint2OrderIds(_minTokenInExecutionPrice, 0));
        safsRouter.swapSingleTokenExactInMod(pool, wsteth, usdc, exactAmountIn, expectedAmountOut, MAX_UINT256, false, bytes(""));
        vm.stopPrank();
        

        // console.log(preTimestamp > block.timestamp);
 
    } 

    // function testSwap() public {
    //      // initial balance: 1 000 000 000 [ 000 000 000 000 000 000 ] wsteth / usdc
    //     BaseVaultTest.Balances memory balancesBefore = getBalances(bob);
    //     console.log(balancesBefore.userTokens[wstethIdx]);
    //     console.log(balancesBefore.userTokens[usdcIdx]);

    //     uint256 exactAmountIn = 1e18;
    //     uint256 expectedAmountOut = 3190 * 1e18;

    //     // vm.startPrank(alice);
    //     vm.startPrank(bob);

    //     safsRouter.swapSingleTokenExactIn(pool, wsteth, usdc, exactAmountIn, expectedAmountOut, MAX_UINT256, false, bytes(""));
    //     vm.stopPrank();

       
    //     BaseVaultTest.Balances memory balancesAfter = getBalances(bob);
    //     console.log(balancesAfter.userTokens[wstethIdx]);
    //     console.log(balancesAfter.userTokens[usdcIdx]);
    // }

    function oldtestSwap() public {

    //     // check if it adhered to the invariant 
    //     // swaps as needed
        
    //     BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

    //     // I want to swap between wsteth to usdc 
    //     // 1. How much wsteth do i have ? 
    //     // 1 000 000 000, 000 000 000 000 000 000 ( 1 M wsteth )
    //     // 2. How much usdc do i have ?
    //     // 1 000 000 000, 000 000 000 000 000 000 ( 1 M usdc )
    //     // 3 The pools initialization amoun, kept in the vault
    //     // 1000 000 000 000 000 000 000 (seems to be 1 K tokens on both side)
    //     // uint256 exactAmountIn = 10e18;
    //     BaseVaultTest.Balances memory balancesPool = getBalances(address(vault));
    //     // console.log(balancesPool.userTokens[wstethIdx]);

         
    //     uint256 exactAmountIn = 1e18;
    //     // PoolMock uses linear math with a rate of 1, so amountIn == amountOut when no fees are applied.
    //     uint256 expectedAmountOut = 3190 * 1e18;
 
    //     vm.prank(address(bob));
    //     safsRouter.swapSingleTokenExactIn(pool, wsteth, usdc, exactAmountIn, expectedAmountOut, MAX_UINT256, false, bytes(""));
    //     // uint256 expectedAmountOut =  safsRouter.querySwapSingleTokenExactIn(pool, wsteth, usdc, exactAmountIn, bytes(""));
    //     // vault.getPoolTokenInfo(address(pool));
    //     uint256[] memory lastBalancesLiveScaled18 = safsRouter.queryTokenLiquidity(address(pool));
    //     BaseVaultTest.Balances memory balancesAfter = getBalances(bob);
        
    //     console.log(lastBalancesLiveScaled18[wstethIdx]);
    //     console.log(lastBalancesLiveScaled18[usdcIdx]);
    //     console.log(lastBalancesLiveScaled18[usdcIdx] / lastBalancesLiveScaled18[wstethIdx]);

    //     uint256 tokenRate = safsRouter.queryTokenRateXY(address(pool), wstethIdx, usdcIdx);
    //     // uint256 tokenRate = safsRouter.queryTokenRateYX(address(pool), usdcIdx, wstethIdx);
    //     console.log(tokenRate);
    //     // 3200 000 000 000 000 000 000
    //     //          312 500 000 000 000\

    //     // I can measure both liquidity and rate via the router

    //     // 312 500 ETH
    //     // 1 000 000 000 USDC
    //     // 0.000 312 500 ETH / 1 USDC

    //     //       312 500 000 000 000
    //     // 1 000 000 000 000 000 000
    }

    function convertToTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256) {
        require(year >= 1970, "Year must be 1970 or later");
        
        // Months data for regular and leap years
        uint8[12] memory daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        
        // Check for leap year and update February days
        if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
            daysInMonth[1] = 29;
        }
        
        uint256 timestamp = 0;
        
        // Calculate years contribution
        for (uint16 i = 1970; i < year; i++) {
            if ((i % 4 == 0 && i % 100 != 0) || (i % 400 == 0)) {
                timestamp += 366 days;
            } else {
                timestamp += 365 days;
            }
        }
        
        // Calculate months contribution
        for (uint8 i = 1; i < month; i++) {
            timestamp += daysInMonth[i - 1] * 1 days;
        }
        
        // Add days, hours, minutes, and seconds
        timestamp += (day - 1) * 1 days;
        timestamp += hour * 1 hours;
        timestamp += minute * 1 minutes;
        timestamp += second;
        
        return timestamp;
    }
}