// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
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

import { SwapDiscountHook } from "../../contracts/hooks/SwapDiscountHook/SwapDiscountHook.sol";
import { DiscountCampaignFactory } from "../../contracts/hooks/SwapDiscountHook/DiscountCampaignFactory.sol";
import {
    IDiscountCampaignFactory
} from "../../contracts/hooks/SwapDiscountHook/Interfaces/IDiscountCampaignFactory.sol";
import { DiscountCampaign } from "../../contracts/hooks/SwapDiscountHook/DiscountCampaign.sol";
import { IDiscountCampaign } from "../../contracts/hooks/SwapDiscountHook/Interfaces/IDiscountCampaign.sol";

import { console } from "forge-std/console.sol";

contract SwapDiscountHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;
    SwapDiscountHook discountHook;
    DiscountCampaignFactory discountCampaignFactory;
    DiscountCampaign discountCampaign;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        discountHook = SwapDiscountHook(poolHooksContract);
        discountCampaignFactory.setSwapDiscountHook(address(discountHook));
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);
        pool = factoryMock.createPool("Test Pool", "TEST");
        discountCampaignFactory = new DiscountCampaignFactory();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(pool, tokenConfig, address(factoryMock));

        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address swapDiscountHook = address(
            new SwapDiscountHook(
                IVault(address(vault)),
                address(factoryMock),
                trustedRouter,
                address(discountCampaignFactory),
                "SwapDiscountNFT",
                "SDN"
            )
        );
        vm.label(swapDiscountHook, "Swap Discount Hook");
        return swapDiscountHook;
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

    // ===================================================================================

    function testUnSuccessfulNFTMint() public {
        _doSwapAndCheckBalances(trustedRouter);
        // becasue no campaign Has been created
        assertEq(IERC721(address(discountHook)).balanceOf(address(bob)), 0);
    }

    function testSuccessfulNFTMint() public {
        deal(address(usdc), address(this), 100e18);
        IERC20(address(usdc)).approve(address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(usdc)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(createParams);

        discountCampaign = DiscountCampaign(campaignAddress);

        _doSwapAndCheckBalances(trustedRouter);
        // becasue no campaign Has been created
        assertEq(IERC721(address(discountHook)).balanceOf(address(bob)), 1);
        (
            bytes32 campaignID,
            address userAddress,
            address _campaignAddress,
            uint256 swappedAmount,
            uint256 timeOfSwap,
            bool hasClaimed
        ) = discountCampaign.userDiscountMapping(1);

        (, , , , uint256 discountRate, , , ) = discountCampaign.campaignDetails();

        uint256 swapTime = block.timestamp;

        assertEq(userAddress, bob, "Invalid user");
        assertEq(_campaignAddress, campaignAddress, "Invalid campaignAddress");
        assertEq(swappedAmount, poolInitAmount / 100, "Invalid swappedAmount");
        assertEq(timeOfSwap, swapTime, "Invalid timeOfSwap");
        assertEq(hasClaimed, false, "Invalid claimed status");

        vm.warp(block.timestamp + 1 days);

        uint256 bobRewardTokenBalalnceBefore = IERC20(usdc).balanceOf(bob);

        discountCampaign.claim(1);

        (campaignID, userAddress, _campaignAddress, swappedAmount, timeOfSwap, hasClaimed) = discountCampaign
            .userDiscountMapping(1);

        assertEq(userAddress, bob, "Invalid user");
        assertEq(_campaignAddress, campaignAddress, "Invalid campaignAddress");
        assertEq(swappedAmount, poolInitAmount / 100, "Invalid swappedAmount");
        assertEq(timeOfSwap, swapTime, "Invalid timeOfSwap");
        assertEq(hasClaimed, true, "Invalid claimed status");

        uint256 bobRewardTokenBalalnceAfter = bobRewardTokenBalalnceBefore + ((swappedAmount * discountRate) / 100e18);

        assertEq(bobRewardTokenBalalnceAfter, IERC20(usdc).balanceOf(bob));

        // if bob tries to reclaim
        vm.expectRevert(IDiscountCampaign.RewardAlreadyClaimed.selector);
        discountCampaign.claim(1);

        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
        console.log(discountRate);
    }

    function testLoggingSuccessfulMint() public {
        // Step 1: Deploy discountCampaignFactory
        console.log("DiscountCampaignFactory deployed at:", address(discountCampaignFactory));

        // Step 2: Set the Swap Discount Hook address
        discountHook = SwapDiscountHook(poolHooksContract);
        discountCampaignFactory.setSwapDiscountHook(address(discountHook));
        console.log("Discount Hook address set to:", address(discountHook));

        // Step 3: Create a discount campaign and log its details
        deal(address(usdc), address(this), 100e18);
        IERC20(address(usdc)).approve(address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(usdc)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(createParams);
        discountCampaign = DiscountCampaign(campaignAddress);

        console.log("DiscountCampaign created at:", campaignAddress);
        console.log("Campaign Reward Amount:", createParams.rewardAmount);
        console.log("Campaign Expiration Time:", createParams.expirationTime);
        console.log("Campaign Discount Amount:", createParams.discountAmount);

        // Step 4: Perform a swap and verify NFT mint
        _doSwapAndCheckBalances2(trustedRouter);
        uint256 nftBalance = IERC721(address(discountHook)).balanceOf(address(bob));
        console.log("NFT balance of Bob after swap:", nftBalance);
        assertEq(nftBalance, 1);

        // Fetch user discount details and log them
        (
            bytes32 campaignID,
            address userAddress,
            address _campaignAddress,
            uint256 swappedAmount,
            uint256 timeOfSwap,
            bool hasClaimed
        ) = discountCampaign.userDiscountMapping(1);

        console.log("User Address after swap:", userAddress);
        console.log("Campaign Address after swap:", _campaignAddress);
        console.log("Swapped Amount:", swappedAmount);
        console.log("Time of Swap:", timeOfSwap);
        console.log("Has Claimed Reward:", hasClaimed);

        // Step 5: Claim the reward and verify balances
        vm.warp(block.timestamp + 1 days);
        uint256 bobRewardTokenBalanceBefore = IERC20(usdc).balanceOf(bob);

        uint256 discountRate;
        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();

        discountCampaign.claim(1);
        console.log("Reward claimed by Bob.");

        // Fetch updated user discount details and log them
        (campaignID, userAddress, _campaignAddress, swappedAmount, timeOfSwap, hasClaimed) = discountCampaign
            .userDiscountMapping(1);
        console.log("Has Claimed Reward after claiming:", hasClaimed);

        // Verify that Bob's reward balance increased

        uint256 bobRewardTokenBalanceAfter = bobRewardTokenBalanceBefore + ((swappedAmount * discountRate) / 100e18);
        assertEq(bobRewardTokenBalanceAfter, IERC20(usdc).balanceOf(bob));
        console.log("Bob's Reward Token Balance after claim:", bobRewardTokenBalanceAfter);

        // Step 6: Attempt to reclaim the reward and expect revert
        vm.expectRevert(IDiscountCampaign.RewardAlreadyClaimed.selector);
        discountCampaign.claim(1);

        console.log("Reward reclaim attempt reverted as expected.");
    }

    function _doSwapAndCheckBalances2(address payable routerToUse) private {
        uint256 exactAmountIn = poolInitAmount / 100;
        uint256 expectedAmountOut = exactAmountIn;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

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

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        // Log swap details for verification
        console.log("Swap executed:");
        console.log("Bob's DAI Balance Before:", balancesBefore.userTokens[daiIdx]);
        console.log("Bob's DAI Balance After:", balancesAfter.userTokens[daiIdx]);
        console.log("Bob's USDC Balance Before:", balancesBefore.userTokens[usdcIdx]);
        console.log("Bob's USDC Balance After:", balancesAfter.userTokens[usdcIdx]);

        // Verify balances as per swap expectations
        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            exactAmountIn,
            "Bob's DAI balance is wrong"
        );
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            expectedAmountOut,
            "Bob's USDC balance is wrong"
        );

        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            exactAmountIn,
            "Vault's DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            expectedAmountOut,
            "Vault's USDC balance is wrong"
        );

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

    function _doSwapAndCheckBalances(address payable routerToUse) private {
        uint256 exactAmountIn = poolInitAmount / 100;
        // PoolMock uses linear math with a rate of 1, so amountIn == amountOut when no fees are applied.
        uint256 expectedAmountOut = exactAmountIn;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

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
}
