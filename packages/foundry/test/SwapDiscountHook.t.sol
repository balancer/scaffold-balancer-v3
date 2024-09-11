// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";

import { SwapDiscountHook } from "../contracts/hooks/SwapDiscountHook.sol";
import { console } from "forge-std/console.sol";

contract SwapDiscountHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    // Maximum discount fee of 50%
    uint64 public constant MAX_SWAP_DISCOUNT_PERCENTAGE = 50e16;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);

        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address swapDiscountHook = address(
            new SwapDiscountHook(
                IVault(address(vault)),
                address(factoryMock),
                trustedRouter,
                address(dai),
                MAX_SWAP_DISCOUNT_PERCENTAGE
            )
        );
        vm.label(swapDiscountHook, "Swap Discount Hook");
        return swapDiscountHook;
    }

    function testRegistryWithWrongFactorySwap() public {
        address swapDHook = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        uint32 pauseWindowEndTime = IVaultAdmin(address(vault)).getPauseWindowEndTime();
        uint32 bufferPeriodDuration = IVaultAdmin(address(vault)).getBufferPeriodDuration();
        uint32 pauseWindowDuration = pauseWindowEndTime - bufferPeriodDuration;
        address unauthorizedFactory = address(new PoolFactoryMock(IVault(address(vault)), pauseWindowDuration));

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                swapDHook,
                unauthorizedFactory
            )
        );
        _registerPoolWithHook(swapDHook, tokenConfig, unauthorizedFactory);
    }

    function testCreationWithWrongFactorySwap() public {
        address swapDHookPool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                swapDHookPool,
                address(factoryMock)
            )
        );
        _registerPoolWithHook(swapDHookPool, tokenConfig, address(factoryMock));
    }

    function testSuccessfulRegistrySwap() public {
        // Registering with allowed factory
        address swapDHookPool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(swapDHookPool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(swapDHookPool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallAfterSwap, true, "shouldCallAfterSwap is false");
    }

    function testSwapDiscountHook() public {
        assertTrue(dai.balanceOf(bob) > 0, "Bob has 0 dai");
        assertTrue(usdc.balanceOf(bob) > 0, "Bob has 0 usdc");

        _doSwapAndCheckBalances(trustedRouter);

        // Balances memory balances = getBalances(address(bob));
        // console.log(balances.bobTokens[0]);
    }

    // function testSwapWithVeBal() public {
    //     // Mint 1 veBAL to bob, so he's able to receive the fee discount
    //     veBAL.mint(address(bob), 1);
    //     assertGt(veBAL.balanceOf(bob), 0, "Bob does not have veBAL");

    //     _doSwapAndCheckBalances(trustedRouter);
    // }

    // function testSwapWithVeBalAndUntrustedRouter() public {
    //     // Mint 1 veBAL to bob, so he's able to receive the fee discount
    //     veBAL.mint(address(bob), 1);
    //     assertGt(veBAL.balanceOf(bob), 0, "Bob does not have veBAL");

    //     // Create an untrusted router
    //     address payable untrustedRouter = payable(new RouterMock(IVault(address(vault)), weth, permit2));
    //     vm.label(untrustedRouter, "untrusted router");

    //     // Allows permit2 to move DAI tokens from bob to untrustedRouter
    //     vm.prank(bob);
    //     permit2.approve(address(dai), untrustedRouter, type(uint160).max, type(uint48).max);

    //     // Even if bob has veBAL, since he is using an untrusted router, he will get no discounts
    //     _doSwapAndCheckBalances(untrustedRouter);
    // }

    function _doSwapAndCheckBalances(address payable routerToUse) private {
        // 10% swap fee. Since vault does not have swap fee, the fee will stay in the pool
        uint256 swapDiscountPercentage = 5e17;

        // vm.prank(lp);
        // vault.setStaticSwapFeePercentage(pool, swapFeePercentage);

        uint256 exactAmountIn = 100e18;
        // PoolMock uses a linear math with rate 1, so amountIn = amountOut if no fees are applied
        uint256 expectedAmountOut = exactAmountIn;
        // If bob has veBAL and router is trusted, bob gets a 50% discount
        bool shouldGetDiscount = SwapDiscountHook(poolHooksContract).discountToken() == address(dai);
        uint256 expectedDiscountedToken = exactAmountIn.mulDown(swapDiscountPercentage);
        // Hook fee will remain in the pool, so the expected amount out discounts the fees
        // expectedAmountOut -= expectedDiscountedToken;

        BaseVaultTest.Balances memory balancesBefore = getBalances(address(bob));

        vm.prank(bob);
        RouterMock(routerToUse).swapSingleTokenExactIn(
            pool,
            usdc,
            dai,
            exactAmountIn,
            expectedAmountOut,
            MAX_UINT256,
            false,
            bytes("")
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(address(bob));

        // Bob's balance of USDC is supposed to decrease, since USDC is the token in
        assertEq(
            balancesBefore.userTokens[usdcIdx] - balancesAfter.userTokens[usdcIdx],
            exactAmountIn,
            "Bob's USDC balance is wrong"
        );

        // Bob's balance of USDC is supposed to increase, since USDC is the token out
        assertEq(
            balancesAfter.userTokens[daiIdx] - balancesBefore.userTokens[daiIdx],
            expectedAmountOut,
            "Bob's DAI balance is wrong"
        );

        // Bob's discount should be 50% of the tokenOut since DAI is the token out
        assertEq(expectedDiscountedToken, 50000000000000000000, "Bob's Discount is wrong");
    }

    // Registry tests require a new pool, because an existing pool may be already registered
    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(new PoolMock(IVault(address(vault)), "SwapD Hook Pool", "swapDHookPool"));
        vm.label(newPool, "SwapD Hook Pool");
    }

    function _registerPoolWithHook(address swapDhookPool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(factory).registerPool(
            swapDhookPool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
