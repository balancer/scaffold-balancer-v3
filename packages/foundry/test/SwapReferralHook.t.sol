// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

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

import { SwapReferralHook } from "../contracts/hooks/SwapReferralHook.sol";

contract SwapReferralHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    // Maximum swap fee of 10%
    uint64 public constant MAX_SWAP_FEE_PERCENTAGE = 10e16;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        // Grants LP the ability to change the static swap fee percentage.
        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), lp);
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);

        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address swapReferralHook = address(
            new SwapReferralHook(IVault(address(vault)), address(factoryMock), trustedRouter)
        );
        vm.label(swapReferralHook, "SwapReferral Fee Hook");
        return swapReferralHook;
    }

    function testRegistryWithWrongFactory() public {
        address swapReferralPool = _createPoolToRegister();
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
                swapReferralPool,
                unauthorizedFactory
            )
        );
        _registerPoolWithHook(swapReferralPool, tokenConfig, unauthorizedFactory);
    }

    function testCreationWithWrongFactory() public {
        address swapReferralPool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                swapReferralPool,
                address(factoryMock)
            )
        );
        _registerPoolWithHook(swapReferralPool, tokenConfig, address(factoryMock));
    }

    function testSuccessfulRegistry() public {
        // Register with the allowed factory.
        address swapReferralPool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectEmit();
        emit SwapReferralHook.SwapReferralHookRegistered(
            poolHooksContract,
            address(factoryMock),
            swapReferralPool
        );

        _registerPoolWithHook(swapReferralPool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(swapReferralPool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallComputeDynamicSwapFee, true, "shouldCallComputeDynamicSwapFee is false");
        assertEq(hooksConfig.shouldCallBeforeSwap, true, "shouldCallBeforeSwap is false");
        assertEq(hooksConfig.shouldCallAfterSwap, true, "shouldCallAfterSwap is false");
    }

    function testSwapWithoutReferralCode() public {
        (bool _hasSwapped, string memory _referralCodeUsed) = SwapReferralHook(poolHooksContract).users(bob);
        assertEq(_referralCodeUsed, '', "Bob used referral code");

        // Bob is not using any referral code so the bob doesn't get any discount
        uint256 _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE;
        bytes memory _userData = bytes("");

        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,bob,_userData);
    }

    function testSwapWithReferralCode() public {
        // Bob is not using any referral code so the bob doesn't get any discount
        uint256 _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE;
        bytes memory _userData = bytes("");
        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,bob,_userData);

        (string memory _referralCode) = SwapReferralHook(poolHooksContract).AddressToCode(bob);
        // Alice is using any referral code of the bob so the alice will get discount
        _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE/2;
        _userData = abi.encode(_referralCode);
        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,alice,_userData);
    }

    function testSwapTocheckReferrerDiscount() public {
        // Bob is not using any referral code so the bob doesn't get any discount
        uint256 _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE;
        bytes memory _userData = bytes("");
        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,bob,_userData);

        (string memory _referralCode) = SwapReferralHook(poolHooksContract).AddressToCode(bob);
        // Alice is using any referral code of the bob so the alice will get discount
        _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE/2;
        _userData = abi.encode(_referralCode);
        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,alice,_userData);

        // Alice used the referral code of bob for the swap.Now, the bob will get 20% discount on the next swap
        _expectedHookFeePercentage = MAX_SWAP_FEE_PERCENTAGE - (MAX_SWAP_FEE_PERCENTAGE/5);
        _userData = bytes("");

        _doSwapAndCheckBalances(trustedRouter,_expectedHookFeePercentage,bob,_userData);
    }

    function _doSwapAndCheckBalances(address payable routerToUse, uint256 expectedHookFeePercentage, address _user, bytes memory userData) private {
        // Since the Vault has no swap fee, the fee will stay in the pool.
        uint256 swapFeePercentage = MAX_SWAP_FEE_PERCENTAGE;

        vm.prank(lp);
        vault.setStaticSwapFeePercentage(pool, swapFeePercentage);

        uint256 exactAmountIn = 1e18;
        // PoolMock uses linear math with a rate of 1, so amountIn == amountOut when no fees are applied.
        uint256 expectedAmountOut = exactAmountIn;
        uint256 expectedHookFee = exactAmountIn.mulDown(expectedHookFeePercentage);
        // The hook fee will remain in the pool, so the expected amountOut discounts the fees.
        expectedAmountOut -= expectedHookFee;

        BaseVaultTest.Balances memory balancesBefore = getBalances(_user);

        vm.prank(_user);
        RouterMock(routerToUse).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            exactAmountIn,
            expectedAmountOut,
            MAX_UINT256,
            false,
            userData
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(_user);

        // User's balance of DAI is supposed to decrease, since DAI is the token in
        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            exactAmountIn,
            "User's DAI balance is wrong"
        );
        // User's balance of USDC is supposed to increase, since USDC is the token out
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            expectedAmountOut,
            "User's USDC balance is wrong"
        );

        // Vault's balance of DAI is supposed to increase, since DAI was added by Bob
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            exactAmountIn,
            "Vault's DAI balance is wrong"
        );
        // Vault's balance of USDC is supposed to decrease, since USDC was given to Bob
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            expectedAmountOut,
            "Vault's USDC balance is wrong"
        );

        // Pool deltas should equal vault's deltas
        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            exactAmountIn,
            "Pool's DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            expectedAmountOut,
            "Pool's USDC balance is wrong"
        );
    }

    // Registry tests require a new pool, because an existing pool may be already registered
    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(new PoolMock(IVault(address(vault)), "SwapReferralPool Fee Pool", "swapReferralPool"));
        vm.label(newPool, "SwapReferralPool Fee Pool");
    }

    function _registerPoolWithHook(address exitFeePool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(factory).registerPool(
            exitFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
