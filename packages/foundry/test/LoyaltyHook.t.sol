// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig,
    RemoveLiquidityKind,
    AddLiquidityKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import { BasePoolMath } from "@balancer-labs/v3-vault/contracts/BasePoolMath.sol";

import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";

import { LoyaltyHook } from "../contracts/hooks/LoyaltyHook.sol";
import { LoyaltyRewardStrategy } from "../contracts/hooks/strategies/LoyaltyRewardStrategy.sol";
import { LoyaltyToken } from "../contracts/mocks/LoyaltyToken.sol";
import { ERC20TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LoyaltyHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    string private constant TEST_POOL_NAME = "Test Pool";
    string private constant TEST_POOL_SYMBOL = "TEST";

    // Fee Percentages
    uint64 private constant MAX_SWAP_FEE_PERCENTAGE = 10 * 1e16; // 10%
    uint64 private constant EXIT_FEE_PERCENTAGE = 10 * 1e16; // 10%

    // DiscountStrategy test params
    uint256 DECAY_PER_ACTION = 10 * 1e16; // DECAY_PER_ACTION: 10% decay
    uint256 MAX_DECAY = 90 * 1e16; // MAX_DECAY: 90% max decay

    // Test mint amount
    uint256 private constant LOYALTY_MINT_AMOUNT = 701 * 1e18;

    uint256 internal daiIdx; // Index of DAI token in the pool
    uint256 internal usdcIdx; // Index of USDC token in the pool

    LoyaltyToken internal loyaltyToken;
    LoyaltyRewardStrategy internal loyaltyRewardStrategy;
    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();
        // Retrieve and store the sorted indexes of DAI and USDC tokens in the pool
        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    /// Creates and registers the LoyaltyHook with the Vault for testing.
    function createHook() internal override returns (address) {
        trustedRouter = payable(router); // Assign the trusted router

        // Deploy the LoyaltyToken contract with predefined name and symbol
        loyaltyToken = new LoyaltyToken("Loyalty", "LOYALTY");
        loyaltyRewardStrategy = createLoyaltyRewardStrategy();

        // Deploy the LoyaltyHook contract with the Vault address, trusted router, and LoyaltyToken address
        vm.prank(lp); // Simulate the pool creator (lp) deploying the LoyaltyHook
        LoyaltyHook loyaltyHook = new LoyaltyHook(
            IVault(address(vault)),
            trustedRouter,
            address(loyaltyToken),
            address(loyaltyRewardStrategy)
        );

        // Grant the LoyaltyHook contract the minter role on the LoyaltyToken
        loyaltyToken.grantMinterRole(address(loyaltyHook));

        return address(loyaltyHook);
    }

    /// testing hook registration, based on VeBALFeeDiscountHookExampleTest.testSuccessfulRegistry
    function testSuccessfulRegistry() public {
        address loyaltyPool = factoryMock.createPool(TEST_POOL_NAME, TEST_POOL_SYMBOL);
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectEmit();
        emit LoyaltyHook.LoyaltyHookRegistered(poolHooksContract, loyaltyPool);

        _registerPoolWithHook(loyaltyPool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(loyaltyPool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallComputeDynamicSwapFee, true, "shouldCallComputeDynamicSwapFee is false");
    }

    /**
     * @notice Tests a swap operation when the user does not possess any Loyalty tokens.
     * @dev Ensures that the swap proceeds without any fee discounts.
     *      Verifies that the token balances before and after the swap are adjusted correctly.
     */
    function testSwapWithoutLoyaltyBalance() public {
        // Assert that Bob initially has no Loyalty tokens
        assertEq(loyaltyToken.balanceOf(bob), 0, "Bob does have loyalty");

        // Perform a swap and verify the resulting balances
        _doSwapAndCheckBalances(trustedRouter);
    }

    /**
     * @notice Tests a swap operation when the user possesses Loyalty tokens.
     * @dev Ensures that the swap applies the appropriate fee discounts based on Loyalty token holdings.
     *      Verifies that the token balances before and after the swap reflect the discounted fees.
     */
    function testSwapWithLoyaltyBalance() public {
        // Mint Loyalty tokens to Bob to qualify for a fee discount
        vm.prank(poolHooksContract); // Simulate the hook contract minting tokens
        loyaltyToken.mint(bob, LOYALTY_MINT_AMOUNT);

        // Assert that Bob now has Loyalty tokens
        assertGt(loyaltyToken.balanceOf(bob), 0, "Bob doesn't have loyalty");

        // Perform a swap and verify the resulting balances with discount applied
        _doSwapAndCheckBalances(trustedRouter);
    }

    /**
     * @notice Performs a swap operation and checks the resulting token balances for correctness.
     * Heavily based on VeBALFeeDiscountHookExampleTest._doSwapAndCheckBalances
     * @param routerToUse The router address to initiate the swap.
     * @dev This internal function abstracts the swap and balance verification logic used in multiple tests.
     *      It sets the swap fee percentage, calculates expected amounts considering discounts,
     *      performs the swap, and asserts the correctness of token balances before and after the swap.
     */
    function _doSwapAndCheckBalances(address payable routerToUse) private {
        // Set the swap fee percentage in the LoyaltyHook
        vm.prank(lp); // Simulate the pool creator setting the swap fee
        LoyaltyHook(poolHooksContract).setHookSwapFeePercentage(MAX_SWAP_FEE_PERCENTAGE);

        uint256 exactAmountIn = poolInitAmount / 100; // Define the input amount for the swap
        // PoolMock uses linear math with a rate of 1, so amountIn == amountOut when no fees are applied.
        uint256 expectedAmountOut = exactAmountIn;

        // Determine if the swap is initiated by the trusted router
        bool isUsingTrustedRouter = routerToUse == trustedRouter;
        uint256 discountedFeePercentage = MAX_SWAP_FEE_PERCENTAGE; // Initialize with max swap fee with no discount applied
        if (isUsingTrustedRouter) {
            // Calculate the discounted swap fee based on the user's loyalty status
            discountedFeePercentage = loyaltyRewardStrategy.calculateDiscountedFeePercentage(
                discountedFeePercentage,
                loyaltyToken.balanceOf(bob)
            );
        }

        // Calculate the expected hook fee using the discounted fee percentage
        uint256 expectedHookFee = exactAmountIn.mulDown(discountedFeePercentage).divDown(FixedPoint.ONE);

        // The hook fee remains in the pool, so the expected amountOut is reduced by the hook fee
        expectedAmountOut -= expectedHookFee;

        // Capture Bob's token balances before the swap
        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        // Simulate Bob performing the swap via the specified router
        vm.prank(bob);
        RouterMock(routerToUse).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            exactAmountIn,
            expectedAmountOut,
            MAX_UINT256,
            false,
            bytes("")
        );

        // Capture Bob's token balances after the swap
        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        // Bob's balance of DAI is supposed to decrease, since DAI is the token in
        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            exactAmountIn,
            "Bob's DAI balance is wrong"
        );
        // Bob's balance of USDC is supposed to increase, since USDC is the token out
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            expectedAmountOut,
            "Bob's USDC balance is wrong"
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

    /**
     * @notice Tests that Loyalty tokens are minted correctly after a swap operation.
     * @dev Ensures that the minted Loyalty tokens correspond to the expected discounted amount.
     *      Verifies that the Loyalty token balance increases as expected after the swap.
     */
    function testLoyaltyMintAfterSwap() public {
        // Set the swap fee percentage in the LoyaltyHook
        vm.prank(lp);
        LoyaltyHook(poolHooksContract).setHookSwapFeePercentage(MAX_SWAP_FEE_PERCENTAGE);

        uint256 exactAmountIn = poolInitAmount / 100; // Define the input amount for the swap

        // Calculate the discounted fee percentage based on Bob's loyalty status
        uint256 discountedFeePercentage = loyaltyRewardStrategy.calculateDiscountedFeePercentage(
            MAX_SWAP_FEE_PERCENTAGE,
            loyaltyToken.balanceOf(bob)
        );

        // Calculate the expected amount out after applying the discounted fee
        uint256 feeAmount = exactAmountIn.mulDown(discountedFeePercentage);
        uint256 expectedAmountOut = exactAmountIn - feeAmount;

        // Capture Bob's Loyalty token balance before the swap
        uint256 balanceBefore = loyaltyToken.balanceOf(bob);

        // Simulate Bob performing the swap via the trusted router
        vm.prank(bob);
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            exactAmountIn,
            expectedAmountOut,
            MAX_UINT256,
            false,
            bytes("")
        );

        // Capture Bob's Loyalty token balance after the swap
        uint256 balanceAfter = loyaltyToken.balanceOf(bob);

        // Calculate the amount of Loyalty tokens minted during this swap
        uint256 mintedAmount = balanceAfter - balanceBefore;

        // Assert that Loyalty tokens were minted
        assertGt(mintedAmount, 0, "No loyalty tokens minted for swap");

        // Assert that the minted amount matches the expected amount out
        assertEq(mintedAmount, expectedAmountOut, "Minted amount does not match expected amount");
    }

    /**
     * @notice Tests that exit fees are correctly applied and returned to LPs when liquidity is removed.
     * Heavily based on ExitFeeHookExampleTest.testExitFeeReturnToLPs().
     * @dev Ensures that exit fees are calculated based on Loyalty token holdings and are correctly distributed.
     *      Verifies that the LP and pool token balances reflect the applied exit fees.
     */
    function testExitFeeReturnToLPs() public virtual {
        // Mint Loyalty tokens to LP to qualify for a discount
        vm.prank(poolHooksContract);
        loyaltyToken.mint(lp, LOYALTY_MINT_AMOUNT); // LP now qualifies for Tier 1 discount (50%)

        // Expect the ExitFeePercentageChanged event to be emitted when setting the exit fee
        vm.expectEmit();
        emit LoyaltyHook.ExitFeePercentageChanged(poolHooksContract, EXIT_FEE_PERCENTAGE);

        // Set the exit fee percentage in the LoyaltyHook
        vm.prank(lp);
        LoyaltyHook(poolHooksContract).setExitFeePercentage(EXIT_FEE_PERCENTAGE);

        uint256 amountOut = poolInitAmount / 2; // Define the amount to remove

        // Calculate the discounted exit fee percentage based on LP's loyalty status
        uint256 discountedExitFeePercentage = loyaltyRewardStrategy.calculateDiscountedFeePercentage(
            EXIT_FEE_PERCENTAGE,
            loyaltyToken.balanceOf(lp)
        );

        // Calculate the expected hook fee using the discounted exit fee percentage
        uint256 hookFee = amountOut.mulDown(discountedExitFeePercentage);

        // Prepare the minimum amounts out after applying the hook fee
        uint256[] memory minAmountsOut = [amountOut - hookFee, amountOut - hookFee].toMemoryArray();

        // Capture LP's token balances before removing liquidity
        BaseVaultTest.Balances memory balancesBefore = getBalances(lp);

        // Expect the ExitFeeCharged event to be emitted for both DAI and USDC
        vm.expectEmit();
        emit LoyaltyHook.ExitFeeCharged(pool, IERC20(dai), hookFee);

        vm.expectEmit();
        emit LoyaltyHook.ExitFeeCharged(pool, IERC20(usdc), hookFee);

        // Simulate the LP removing liquidity proportionally from the pool
        vm.prank(lp);
        router.removeLiquidityProportional(pool, 2 * amountOut, minAmountsOut, false, bytes(""));

        // Capture LP's token balances after removing liquidity
        BaseVaultTest.Balances memory balancesAfter = getBalances(lp);

        // Assert that LP's DAI amount has increased correctly, accounting for the hook fee
        assertEq(
            balancesAfter.lpTokens[daiIdx] - balancesBefore.lpTokens[daiIdx],
            amountOut - hookFee,
            "LP's DAI amount is wrong"
        );
        // Assert that LP's USDC amount has increased correctly, accounting for the hook fee
        assertEq(
            balancesAfter.lpTokens[usdcIdx] - balancesBefore.lpTokens[usdcIdx],
            amountOut - hookFee,
            "LP's USDC amount is wrong"
        );
        // Assert that LP's BPT balance has decreased by the correct amount
        assertEq(balancesBefore.lpBpt - balancesAfter.lpBpt, 2 * amountOut, "LP's BPT amount is wrong");

        // Assert that the Pool's DAI balance has decreased correctly, accounting for the hook fee
        assertEq(
            balancesBefore.poolTokens[daiIdx] - balancesAfter.poolTokens[daiIdx],
            amountOut - hookFee,
            "Pool's DAI amount is wrong"
        );
        // Assert that the Pool's USDC balance has decreased correctly, accounting for the hook fee
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            amountOut - hookFee,
            "Pool's USDC amount is wrong"
        );
        // Assert that the Pool's BPT supply has decreased by the correct amount
        assertEq(balancesBefore.poolSupply - balancesAfter.poolSupply, 2 * amountOut, "BPT supply amount is wrong");

        // Assert that the Vault's DAI balance has decreased correctly, accounting for the hook fee
        assertEq(
            balancesBefore.vaultTokens[daiIdx] - balancesAfter.vaultTokens[daiIdx],
            amountOut - hookFee,
            "Vault's DAI amount is wrong"
        );
        // Assert that the Vault's USDC balance has decreased correctly, accounting for the hook fee
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            amountOut - hookFee,
            "Vault's USDC amount is wrong"
        );

        // Assert that the Hook's token balances remain unchanged
        assertEq(balancesBefore.hookTokens[daiIdx], balancesAfter.hookTokens[daiIdx], "Hook's DAI amount is wrong");
        assertEq(balancesBefore.hookTokens[usdcIdx], balancesAfter.hookTokens[usdcIdx], "Hook's USDC amount is wrong");
        assertEq(balancesBefore.hookBpt, balancesAfter.hookBpt, "Hook's BPT amount is wrong");
    }

    /**
     * @notice Tests the addition of liquidity and verifies the resulting token balances.
     * @dev Ensures that adding liquidity correctly adjusts the user's and pool's token balances.
     *      Verifies that the LoyaltyHook's `onAfterAddLiquidity` callback is invoked.
     */
    function testMintAfterAddLiquidity() public {
        // Compute the actual amounts in based on proportional liquidity addition
        uint256[] memory actualAmountsIn = BasePoolMath.computeProportionalAmountsIn(
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            BalancerPoolToken(pool).totalSupply(),
            bptAmount
        );

        uint256 daiAmount = actualAmountsIn[daiIdx];
        uint256 usdcAmount = actualAmountsIn[usdcIdx];

        // Prepare the maximum amounts in for adding liquidity
        uint256[] memory maxAmountsIn = [daiAmount, usdcAmount].toMemoryArray();

        // Capture Bob's token balances before adding liquidity
        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        // Set up expected balances after adding liquidity
        uint256[] memory expectedBalances = [poolInitAmount + daiAmount, poolInitAmount + usdcAmount].toMemoryArray();

        // Expect the LoyaltyHook.onAfterAddLiquidity to be called with specific parameters
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
                    bptAmount,
                    expectedBalances,
                    bytes("")
                )
            )
        );

        // Bob should not have LOYALTY tokens before liquidity provision
        assertEq(loyaltyToken.balanceOf(bob), 0, "Bob has loyalty before liquidity provision");

        // Simulate Bob adding liquidity proportionally to the pool
        vm.prank(bob);
        router.addLiquidityProportional(pool, maxAmountsIn, bptAmount, false, bytes(""));

        // Bob should have LOYALTY tokens after liquidity provision
        assertGt(loyaltyToken.balanceOf(bob), 0, "Bob doesn't have loyalty after liquidity provision");

        // Capture Bob's token balances after adding liquidity
        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        // Assert that Bob's DAI balance has decreased by the correct amount
        assertEq(
            balancesAfter.userTokens[daiIdx],
            balancesBefore.userTokens[daiIdx] - daiAmount,
            "Bob's DAI balance did not decrease correctly"
        );
        // Assert that Bob's USDC balance has decreased by the correct amount
        assertEq(
            balancesAfter.userTokens[usdcIdx],
            balancesBefore.userTokens[usdcIdx] - usdcAmount,
            "Bob's USDC balance did not decrease correctly"
        );
        // Assert that Bob received the expected amount of BPT tokens
        assertEq(
            balancesAfter.userBpt,
            balancesBefore.userBpt + bptAmount,
            "Bob did not receive the correct amount of BPT"
        );
    }

    /**
     * @notice Tests multiple liquidity additions to verify the decay mechanism for Loyalty token minting.
     * @dev Ensures that the Loyalty token minting decreases appropriately with each additional liquidity action.
     *      Verifies that the final minted amount reflects the maximum decay factor.
     */
    function testMintAfterMultipleLiquidityAdditions() public {
        // Initial setup parameters
        uint256[] memory maxAmountsIn = [poolInitAmount, poolInitAmount].toMemoryArray();

        // Define the number of liquidity additions to perform
        uint256 numAdditions = 11;
        uint256[] memory mintedAmounts = new uint256[](numAdditions); // Array to store minted Loyalty tokens

        // Perform multiple liquidity additions
        for (uint256 i = 0; i < numAdditions; i++) {
            // Capture Bob's Loyalty token balance before the addition
            uint256 balanceBefore = loyaltyToken.balanceOf(bob);

            // Simulate Bob adding liquidity proportionally to the pool
            vm.prank(bob);
            router.addLiquidityProportional(pool, maxAmountsIn, bptAmount, false, bytes(""));

            // Capture Bob's Loyalty token balance after the addition
            uint256 balanceAfter = loyaltyToken.balanceOf(bob);

            // Calculate the amount of Loyalty tokens minted during this addition
            mintedAmounts[i] = balanceAfter - balanceBefore;

            // Assert that Loyalty tokens were minted
            assertGt(mintedAmounts[i], 0, "No loyalty tokens minted");

            // Calculate the expected mint amount based on the action count and decay
            uint256 expectedMintAmount;
            if (i == 0) {
                // For the first addition, full amount is minted without decay
                expectedMintAmount = bptAmount;
            } else {
                // For subsequent additions, apply the decay factor
                uint256 decayPercentage = DECAY_PER_ACTION * i;
                if (decayPercentage > MAX_DECAY) {
                    decayPercentage = MAX_DECAY;
                }
                expectedMintAmount = (bptAmount * (FixedPoint.ONE - decayPercentage)) / FixedPoint.ONE;
            }

            // Assert that the minted Loyalty tokens approximately match the expected amount
            assertApproxEqRel(mintedAmounts[i], expectedMintAmount, 1e16, "Minted amount did not match expected decay");
        }

        // Define the expected final mint amount after maximum decay
        uint256 expectedFinalMint = bptAmount / 10; // 10% of the original amount (90% decay)

        // Assert that the final minted Loyalty tokens reflect the maximum decay applied
        assertApproxEqRel(
            mintedAmounts[numAdditions - 1],
            expectedFinalMint,
            1e16, // 1% tolerance
            "Final minted amount does not reflect maximum decay (should be 10% of original)"
        );
    }

    /**
     * @notice Tests that the action count for a user resets after the specified interval.
     * @dev Ensures that after the reset interval, the user's action count starts fresh,
     *      allowing full minting amounts without accumulated decay from previous actions.
     *      Verifies that the action count resets correctly and Loyalty token minting reflects the reset.
     */
    function testActionCountResetsAfter30Days() public {
        // Capture the initial action count for Bob
        uint256 initialActionCount = LoyaltyHook(poolHooksContract).userActionCount(bob);
        assertEq(initialActionCount, 0, "Initial action count should be 0");

        // Perform the first liquidity addition, which should increment the action count to 1
        vm.prank(bob);
        router.addLiquidityProportional(
            pool,
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            bptAmount,
            false,
            bytes("")
        );

        // Check that the action count has been incremented to 1
        uint256 actionCountAfterFirst = LoyaltyHook(poolHooksContract).userActionCount(bob);
        assertEq(actionCountAfterFirst, 1, "Action count should be 1 after first liquidity addition");

        // Capture Bob's Loyalty token balance after the first addition
        uint256 loyaltyBalanceAfterFirst = loyaltyToken.balanceOf(bob);

        // Perform the second liquidity addition, which should apply a decay and increment the action count to 2
        vm.prank(bob);
        router.addLiquidityProportional(
            pool,
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            bptAmount,
            false,
            bytes("")
        );

        // Check that the action count has been incremented to 2
        uint256 actionCountAfterSecond = LoyaltyHook(poolHooksContract).userActionCount(bob);
        assertEq(actionCountAfterSecond, 2, "Action count should be 2 after second liquidity addition");

        // Capture Bob's Loyalty token balance after the second addition
        uint256 loyaltyBalanceAfterSecond = loyaltyToken.balanceOf(bob);

        // Advance the blockchain time by the reset interval to trigger the action count reset
        vm.warp(block.timestamp + LoyaltyHook(poolHooksContract).resetInterval());

        // Perform the third liquidity addition, which should reset the action count and start at 1 again
        vm.prank(bob);
        router.addLiquidityProportional(
            pool,
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            bptAmount,
            false,
            bytes("")
        );

        // Check that the action count has reset to 1
        uint256 actionCountAfterThird = LoyaltyHook(poolHooksContract).userActionCount(bob);
        assertEq(actionCountAfterThird, 1, "Action count should reset to 1 after 30 days and third liquidity addition");

        // Capture Bob's Loyalty token balance after the third addition
        uint256 loyaltyBalanceAfterThird = loyaltyToken.balanceOf(bob);
        // Calculate the amount of Loyalty tokens minted during the third addition
        uint256 thirdMintAmount = loyaltyBalanceAfterThird - loyaltyBalanceAfterSecond;

        // Assert that the minted Loyalty tokens during the third addition match the expected amount before decay
        assertEq(thirdMintAmount, loyaltyBalanceAfterFirst, "Third mint amount incorrect after reset");
    }

    function _registerPoolWithHook(address exitFeePool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;
        liquidityManagement.enableDonation = true;

        PoolFactoryMock(factory).registerPool(
            exitFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

    function _createPool(address[] memory tokens, string memory label) internal virtual override returns (address) {
        PoolMock newPool = new PoolMock(IVault(address(vault)), TEST_POOL_NAME, TEST_POOL_SYMBOL);
        vm.label(address(newPool), label);

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;
        liquidityManagement.enableDonation = true;

        vm.expectEmit();
        emit LoyaltyHook.LoyaltyHookRegistered(poolHooksContract, address(newPool));

        factoryMock.registerPool(
            address(newPool),
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
        return address(newPool);
    }

    /**
     * @notice Deploys the LoyaltyRewardStrategy with defined parameters.
     * @return LoyaltyRewardStrategy The deployed LoyaltyRewardStrategy contract instance.
     */
    function createLoyaltyRewardStrategy() internal returns (LoyaltyRewardStrategy) {
        uint256[] memory thresholds = new uint256[](3);
        thresholds[0] = 100 * 1e18; // TIER1_THRESHOLD: 100 tokens
        thresholds[1] = 500 * 1e18; // TIER2_THRESHOLD: 500 tokens
        thresholds[2] = 1000 * 1e18; // TIER3_THRESHOLD: 1000 tokens

        uint256[] memory discounts = new uint256[](3);
        discounts[0] = 50 * 1e16; // TIER1_DISCOUNT: 50% discount
        discounts[1] = 80 * 1e16; // TIER2_DISCOUNT: 80% discount
        discounts[2] = 90 * 1e16; // TIER3_DISCOUNT: 90% discount

        uint256 decayPerAction = DECAY_PER_ACTION; // DECAY_PER_ACTION: 10% decay
        uint256 maxDecay = MAX_DECAY; // MAX_DECAY: 90% max decay

        // Deploy tLoyaltyRewardStrateegyegy contract
        return new LoyaltyRewardStrategy(thresholds, discounts, decayPerAction, maxDecay);
    }
}
