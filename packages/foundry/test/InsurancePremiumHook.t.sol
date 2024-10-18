// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    LiquidityManagement,
    PoolRoleAccounts,
    RemoveLiquidityKind,
    AfterSwapParams,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BasePoolMath } from "@balancer-labs/v3-vault/contracts/BasePoolMath.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";

import { InsurancePremiumHook } from "../contracts/InsurancePremiumHook.sol";

contract InsurancePremiumHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    function setUp() public virtual override {
        BaseVaultTest.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    // Sets the hook of the pool and stores the address in the variable poolHooksContract
    function createHook() internal override returns (address) {
        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        InsurancePremiumHook hook = new InsurancePremiumHook(IVault(address(vault)));
        return address(hook);
    }

    // Overrides pool creation to set liquidityManagement (disables unbalanced liquidity)
    function _createPool(address[] memory tokens, string memory label) internal override returns (address) {
        PoolMock newPool = deployPoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL");
        vm.label(address(newPool), label);

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;

        vm.expectEmit();
        emit InsurancePremiumHook.InsurancePremiumHookRegistered(poolHooksContract, address(newPool));

        factoryMock.registerPool(
            address(newPool),
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        return address(newPool);
    }

    function testHookFeeAddLiquidityExactIn__Fuzz(uint256 expectedBptOut, uint64 hookFeePercentage) public {
        // Add fee between 0 and 100%
        hookFeePercentage = uint64(bound(hookFeePercentage, 0, FixedPoint.ONE));

        vm.expectEmit();
        emit InsurancePremiumHook.HookAddLiquidityFeePercentageChanged(poolHooksContract, hookFeePercentage);

        vm.prank(lp);
        InsurancePremiumHook(poolHooksContract).setAddLiquidityHookFeePercentage(hookFeePercentage);

        // Since operation is not settled in advance, max expected bpt out can't generate a hook fee higher than
        // pool liquidity, or else the hook won't be able to charge fees
        expectedBptOut = bound(
            expectedBptOut,
            POOL_MINIMUM_TOTAL_SUPPLY * PRODUCTION_MIN_TRADE_AMOUNT,
            hookFeePercentage == 0 ? MAX_UINT256 : poolInitAmount.divDown(hookFeePercentage)
        );

        // Make sure bob has enough to pay for the transaction
        if (expectedBptOut > dai.balanceOf(bob)) {
            expectedBptOut = dai.balanceOf(bob);
        }

        uint256[] memory actualAmountsIn = BasePoolMath.computeProportionalAmountsIn(
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            BalancerPoolToken(pool).totalSupply(),
            expectedBptOut
        );
        uint256 actualAmountIn = actualAmountsIn[daiIdx]; // Proportional, so doesn't matter which token
        uint256 hookFee = actualAmountIn.mulDown(hookFeePercentage);

        uint256[] memory expectedBalances = [poolInitAmount + actualAmountIn, poolInitAmount + actualAmountIn]
            .toMemoryArray();

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        vm.prank(bob);
        vm.expectCall(
            address(poolHooksContract),
            abi.encodeCall(
                IHooks.onAfterAddLiquidity,
                (
                    address(router),
                    pool,
                    AddLiquidityKind.PROPORTIONAL,
                    actualAmountsIn,
                    actualAmountsIn,
                    expectedBptOut,
                    expectedBalances,
                    bytes("")
                )
            )
        );

        if (hookFee > 0) {
            vm.expectEmit();
            emit InsurancePremiumHook.HookFeeCharged(poolHooksContract, IERC20(dai), hookFee);

            vm.expectEmit();
            emit InsurancePremiumHook.HookFeeCharged(poolHooksContract, IERC20(usdc), hookFee);
        }

        uint256[] memory maxAmountsIn = [actualAmountIn + hookFee, actualAmountIn + hookFee].toMemoryArray();
        router.addLiquidityProportional(pool, maxAmountsIn, expectedBptOut, false, bytes(""));

        _checkAddLiquidityHookTestResults(balancesBefore, actualAmountsIn, expectedBptOut, hookFee);
        _checkWithdrawals(hookFee, hookFee);
    }

    function testHookFeeRemoveLiquidityExactIn__Fuzz(uint256 expectedBptIn, uint64 hookFeePercentage) public {
        // Add liquidity so bob has BPT to remove liquidity
        vm.prank(bob);
        router.addLiquidityProportional(
            pool,
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            2 * poolInitAmount,
            false,
            bytes("")
        );

        // Add fee between 0 and 100%
        hookFeePercentage = uint64(bound(hookFeePercentage, 0, FixedPoint.ONE));

        vm.expectEmit();
        emit InsurancePremiumHook.HookRemoveLiquidityFeePercentageChanged(poolHooksContract, hookFeePercentage);

        vm.prank(lp);
        InsurancePremiumHook(poolHooksContract).setRemoveLiquidityHookFeePercentage(hookFeePercentage);

        // Make sure bob has enough to pay for the transaction
        expectedBptIn = bound(
            expectedBptIn,
            POOL_MINIMUM_TOTAL_SUPPLY * PRODUCTION_MIN_TRADE_AMOUNT,
            BalancerPoolToken(pool).balanceOf(bob)
        );

        // Since bob added poolInitAmount in each token of the pool, the pool balances are doubled
        uint256[] memory actualAmountsOut = BasePoolMath.computeProportionalAmountsOut(
            [2 * poolInitAmount, 2 * poolInitAmount].toMemoryArray(),
            BalancerPoolToken(pool).totalSupply(),
            expectedBptIn
        );
        uint256 actualAmountOut = actualAmountsOut[usdcIdx];
        uint256 hookFee = actualAmountOut.mulDown(hookFeePercentage);

        uint256[] memory expectedBalances = [2 * poolInitAmount - actualAmountOut, 2 * poolInitAmount - actualAmountOut]
            .toMemoryArray();

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        vm.prank(bob);
        vm.expectCall(
            address(poolHooksContract),
            abi.encodeCall(
                IHooks.onAfterRemoveLiquidity,
                (
                    address(router),
                    pool,
                    RemoveLiquidityKind.PROPORTIONAL,
                    expectedBptIn,
                    actualAmountsOut,
                    actualAmountsOut,
                    expectedBalances,
                    bytes("")
                )
            )
        );

        if (hookFee > 0) {
            vm.expectEmit();
            emit InsurancePremiumHook.HookFeeCharged(poolHooksContract, IERC20(dai), hookFee);

            vm.expectEmit();
            emit InsurancePremiumHook.HookFeeCharged(poolHooksContract, IERC20(usdc), hookFee);
        }

        uint256[] memory minAmountsOut = [actualAmountOut - hookFee, actualAmountOut - hookFee].toMemoryArray();
        router.removeLiquidityProportional(pool, expectedBptIn, minAmountsOut, false, bytes(""));

        _checkRemoveLiquidityHookTestResults(balancesBefore, actualAmountsOut, expectedBptIn, hookFee);
        _checkWithdrawals(hookFee, hookFee);
    }

    function _checkAddLiquidityHookTestResults(
        BaseVaultTest.Balances memory balancesBefore,
        uint256[] memory actualAmountsIn,
        uint256 expectedBptOut,
        uint256 expectedHookFee
    ) private view {
        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        assertEq(balancesAfter.userBpt - balancesBefore.userBpt, expectedBptOut, "Bob BPT balance is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            actualAmountsIn[daiIdx],
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesAfter.poolTokens[usdcIdx] - balancesBefore.poolTokens[usdcIdx],
            actualAmountsIn[usdcIdx],
            "Pool USDC balance is wrong"
        );
        assertEq(balancesAfter.poolSupply - balancesBefore.poolSupply, expectedBptOut, "Pool Supply is wrong");

        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            actualAmountsIn[daiIdx],
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[usdcIdx] - balancesBefore.vaultTokens[usdcIdx],
            actualAmountsIn[usdcIdx],
            "Vault USDC balance is wrong"
        );

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            actualAmountsIn[daiIdx] + expectedHookFee,
            "Bob DAI balance is wrong"
        );
        assertEq(
            balancesBefore.userTokens[usdcIdx] - balancesAfter.userTokens[usdcIdx],
            actualAmountsIn[usdcIdx] + expectedHookFee,
            "Bob USDC balance is wrong"
        );

        assertEq(
            balancesAfter.hookTokens[daiIdx] - balancesBefore.hookTokens[daiIdx],
            expectedHookFee,
            "Hook DAI balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[usdcIdx] - balancesBefore.hookTokens[usdcIdx],
            expectedHookFee,
            "Hook USDC balance is wrong"
        );
    }

    function _checkRemoveLiquidityHookTestResults(
        BaseVaultTest.Balances memory balancesBefore,
        uint256[] memory actualAmountsOut,
        uint256 expectedBptIn,
        uint256 expectedHookFee
    ) private view {
        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        assertEq(balancesBefore.userBpt - balancesAfter.userBpt, expectedBptIn, "Bob BPT balance is wrong");

        assertEq(
            balancesBefore.poolTokens[daiIdx] - balancesAfter.poolTokens[daiIdx],
            actualAmountsOut[daiIdx],
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            actualAmountsOut[usdcIdx],
            "Pool USDC balance is wrong"
        );
        assertEq(balancesBefore.poolSupply - balancesAfter.poolSupply, expectedBptIn, "Pool Supply is wrong");

        assertEq(
            balancesBefore.vaultTokens[daiIdx] - balancesAfter.vaultTokens[daiIdx],
            actualAmountsOut[daiIdx],
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            actualAmountsOut[usdcIdx],
            "Vault USDC balance is wrong"
        );

        assertEq(
            balancesAfter.userTokens[daiIdx] - balancesBefore.userTokens[daiIdx],
            actualAmountsOut[daiIdx] - expectedHookFee,
            "Bob DAI balance is wrong"
        );
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            actualAmountsOut[usdcIdx] - expectedHookFee,
            "Bob USDC balance is wrong"
        );

        assertEq(
            balancesAfter.hookTokens[daiIdx] - balancesBefore.hookTokens[daiIdx],
            expectedHookFee,
            "Hook DAI balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[usdcIdx] - balancesBefore.hookTokens[usdcIdx],
            expectedHookFee,
            "Hook USDC balance is wrong"
        );
    }
}