// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig,
    PoolSwapParams,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";

import { MevTaxHook } from "../contracts/hooks/MevTaxHook.sol";

contract MevTaxHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    uint256 private constant MEV_TAX_MULTIPLIER = 99e18;
    uint256 private constant STATIC_SWAP_FEE_PERCENTAGE = 0.03e18;

    function setUp() public virtual override {
        BaseVaultTest.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    function createHook() internal override returns (address) {
        MevTaxHook hook = new MevTaxHook(IVault(address(vault)), address(factoryMock), MEV_TAX_MULTIPLIER);
        return address(hook);
    }

    function testSuccessfulRegistration() public {
        address pool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        factoryMock.registerPool(pool, tokenConfig, roleAccounts, poolHooksContract, liquidityManagement);

        HooksConfig memory hooksConfig = vault.getHooksConfig(pool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallComputeDynamicSwapFee, true, "shouldCallComputeDynamicSwapFee is false");
    }

    function testOnComputeDynamicSwapFeePercentage() public {
        uint256 baseFee = 10 gwei;
        uint256 priorityFee = 1 gwei;

        vm.fee(baseFee);
        vm.txGasPrice(baseFee + priorityFee);

        PoolSwapParams memory params;
        (bool success, uint256 dynamicSwapFeePercentage) = MevTaxHook(poolHooksContract).onComputeDynamicSwapFeePercentage(
            params,
            address(0),
            STATIC_SWAP_FEE_PERCENTAGE
        );

        assertTrue(success, "onComputeDynamicSwapFeePercentage failed");
        uint256 expectedDynamicSwapFee = _calcDynSwapFee(STATIC_SWAP_FEE_PERCENTAGE, MEV_TAX_MULTIPLIER, priorityFee);
        assertEq(dynamicSwapFeePercentage, expectedDynamicSwapFee, "Incorrect dynamic swap fee percentage");
    }

    function testSwapWithMevTax() public {
        uint256 swapAmount = 1e18;
        uint256 baseFee = 10 gwei;
        uint256 maxPriorityFee = 10 gwei;
        uint256 lastAmountOut = type(uint256).max;

        vm.fee(baseFee);

        // Set the swap fee percentage on the pool
        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), lp);
        vm.prank(lp);
        vault.setStaticSwapFeePercentage(pool, STATIC_SWAP_FEE_PERCENTAGE);

        for (uint256 priorityFee = 0 gwei; priorityFee < maxPriorityFee; priorityFee += 1 gwei) {
            vm.txGasPrice(baseFee + priorityFee);

            uint256 expectedDynamicSwapFee = _calcDynSwapFee(STATIC_SWAP_FEE_PERCENTAGE, MEV_TAX_MULTIPLIER, priorityFee);
            uint256 expectedAmountOut = swapAmount - (swapAmount * expectedDynamicSwapFee) / 1e18;

            // Get bob's balances before a swap
            Balances memory balancesBefore = getBalances(bob);
            
            // Perform swap, get amount out from vault, grab balances after, then roll back as if it never happened
            (uint256 amountOutVault, Balances memory balancesAfter) = _executeAndUndoSwap(swapAmount);

            uint256 amountOut = balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx];
            assertEq(balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx], swapAmount, "Bob's DAI balance is wrong");
            assertEq(amountOut, expectedAmountOut, "Bob's USDC balance is wrong");
            assertEq(amountOut, amountOutVault, "Vault delta != Bob's delta");
            assertTrue(amountOut < lastAmountOut, "MEV tax not increasing");
            lastAmountOut = amountOut;
        } 
    }

    function _calcDynSwapFee(uint256 staticFee, uint256 taxMultiplier, uint256 priorityFee) internal returns (uint256) {
        uint256 percentIncrease = (taxMultiplier * priorityFee)/1e18;
        uint256 staticFeeMultiplier = 1e18 + percentIncrease;
        return staticFee * staticFeeMultiplier / 1e18;
    }

    function _executeAndUndoSwap(uint256 amountIn) internal returns (uint256, Balances memory) {
        // Create a storage checkpoint
        uint256 snapshot = vm.snapshot();

        try this.executeSwap(amountIn) returns (uint256 amountOut) {
            Balances memory balancesAfter = getBalances(bob);
            // Revert to the snapshot to undo the swap
            vm.revertTo(snapshot);
            return (amountOut, balancesAfter);
        } catch Error(string memory reason) {
            vm.revertTo(snapshot);
            revert(reason);
        } catch {
            vm.revertTo(snapshot);
            revert("Low level error during swap");
        }
    }

    function executeSwap(uint256 amountIn) external returns (uint256) {
        vm.prank(bob);
        IERC20(dai).approve(address(router), amountIn);

        // Perform the actual swap
        vm.prank(bob);
        return
            router.swapSingleTokenExactIn(
                address(pool),
                IERC20(dai),
                IERC20(usdc),
                amountIn,
                0, // `minAmountOut = 0` guaranteed no limit error
                block.timestamp, // `deadline = now` won't timeout
                false,
                ""
            );
    }

}