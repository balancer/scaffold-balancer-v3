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
        deal(address(usdc), address(discountCampaignFactory), 100e18);

        address campaignAddress = discountCampaignFactory.createCampaign(
            100e18,
            2 days,
            0,
            50e18,
            address(pool),
            address(this),
            address(usdc)
        );

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
