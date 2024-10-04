// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";

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

import { DiscountCampaignFactory } from "../../contracts/hooks/SwapDiscountHook/DiscountCampaignFactory.sol";
import { DiscountCampaign } from "../../contracts/hooks/SwapDiscountHook/DiscountCampaign.sol";
import { SwapDiscountHook } from "../../contracts/hooks/SwapDiscountHook/SwapDiscountHook.sol";
import {
    IDiscountCampaignFactory
} from "../../contracts/hooks/SwapDiscountHook/Interfaces/IDiscountCampaignFactory.sol";

import { IDiscountCampaign } from "../../contracts/hooks/SwapDiscountHook/Interfaces/IDiscountCampaign.sol";
import { console } from "forge-std/console.sol";

contract DiscountCampaignTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    DiscountCampaignFactory discountCampaignFactory;
    DiscountCampaign discountCampaign;
    SwapDiscountHook discountHook;
    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        discountHook = SwapDiscountHook(poolHooksContract);
        discountCampaignFactory.setSwapDiscountHook(address(discountHook));
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

    function test_NotAbleToClaimRewardBeforeCoolDownPeriod() public {
        deal(address(usdc), address(this), 100e18);
        IERC20(address(usdc)).approve(address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 1 days,
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

        (bytes32 campaignId, , , , uint256 discountRate, , , ) = discountCampaign.campaignDetails();

        uint256 swapTime = block.timestamp;

        assertEq(userAddress, bob, "Invalid user");
        assertEq(_campaignAddress, campaignAddress, "Invalid campaignAddress");
        assertEq(swappedAmount, poolInitAmount / 100, "Invalid swappedAmount");
        assertEq(timeOfSwap, swapTime, "Invalid timeOfSwap");
        assertEq(hasClaimed, false, "Invalid claimed status");
        assertEq(campaignID, keccak256(abi.encode(block.timestamp, 2 days)));
        assertEq(campaignID, campaignId);

        vm.expectRevert(IDiscountCampaign.CoolDownPeriodNotPassed.selector);
        discountCampaign.claim(1);

        vm.warp(block.timestamp + 1 days + 3600);

        uint256 bobRewardTokenBalalnceBefore = IERC20(usdc).balanceOf(bob);

        discountCampaign.claim(1);

        (campaignID, userAddress, _campaignAddress, swappedAmount, timeOfSwap, hasClaimed) = discountCampaign
            .userDiscountMapping(1);

        assertEq(userAddress, bob, "Invalid user");
        assertEq(_campaignAddress, campaignAddress, "Invalid campaignAddress");
        assertEq(swappedAmount, poolInitAmount / 100, "Invalid swappedAmount");
        assertEq(timeOfSwap, swapTime, "Invalid timeOfSwap");
        assertEq(hasClaimed, true, "Invalid claimed status");
        assertEq(campaignID, keccak256(abi.encode(swapTime, 2 days)));

        uint256 bobRewardTokenBalalnceAfter = bobRewardTokenBalalnceBefore + ((swappedAmount * discountRate) / 100e18);

        assertEq(bobRewardTokenBalalnceAfter, IERC20(usdc).balanceOf(bob));
    }

    function test_NotAbleToClaimRewardAfterExpiration() public {
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

        (bytes32 campaignId, , , , uint256 discountRate, , , ) = discountCampaign.campaignDetails();

        uint256 swapTime = block.timestamp;

        assertEq(userAddress, bob, "Invalid user");
        assertEq(_campaignAddress, campaignAddress, "Invalid campaignAddress");
        assertEq(swappedAmount, poolInitAmount / 100, "Invalid swappedAmount");
        assertEq(timeOfSwap, swapTime, "Invalid timeOfSwap");
        assertEq(hasClaimed, false, "Invalid claimed status");
        assertEq(campaignID, keccak256(abi.encode(block.timestamp, 2 days)));
        assertEq(campaignID, campaignId);

        vm.warp(block.timestamp + 2 days + 3600);

        // uint256 bobRewardTokenBalalnceBefore = IERC20(usdc).balanceOf(bob);

        // user wont be able to claim because discount is expired
        vm.expectRevert(IDiscountCampaign.DiscountExpired.selector);
        discountCampaign.claim(1);

        // Now updating the campaign
        deal(address(usdc), address(this), 50e18);
        IERC20(address(usdc)).approve(address(discountCampaignFactory), 50e18);

        IDiscountCampaignFactory.CampaignParams memory updateParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 50e18,
            expirationTime: 5 days,
            coolDownPeriod: 0,
            discountAmount: 20e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(usdc)
        });

        discountCampaignFactory.updateCampaign(updateParams);

        // user wont be able to claim because campaign has changed
        vm.expectRevert(IDiscountCampaign.CampaignExpired.selector);
        discountCampaign.claim(1);
    }

    function test_NotAbleToClaimRewardFromAnotherCampaign() public {
        deal(address(usdc), address(this), 200e18);
        IERC20(address(usdc)).approve(address(discountCampaignFactory), 200e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 1 days,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(usdc)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(createParams);

        discountCampaign = DiscountCampaign(campaignAddress);

        _doSwapAndCheckBalances(trustedRouter);

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

        vm.warp(block.timestamp + 1 days + 1);

        // if a wrong nft id or id from a different campaign is provided
        vm.expectRevert(IDiscountCampaign.InvalidTokenID.selector);
        discountCampaign.claim(2);
    }

    function test_DiscountRate() public {
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

        discountCampaign = DiscountCampaign(discountCampaignFactory.createCampaign(createParams));
        console.log(poolInitAmount);
        _doSwapAndCheckBalancesWithAmount(trustedRouter, poolInitAmount);

        (, , , , uint256 discountRate, , , ) = discountCampaign.campaignDetails();

        assertEq(discountRate, 50e18);

        uint256 swapTime = block.timestamp;

        vm.warp(block.timestamp + 2 days);

        uint256 bobRewardTokenBalalnceBefore = IERC20(usdc).balanceOf(bob);

        discountCampaign.claim(1);

        uint256 bobRewardTokenBalalnceAfter = bobRewardTokenBalalnceBefore + ((100e18 * discountRate) / 100e18);

        assertEq(bobRewardTokenBalalnceAfter, IERC20(usdc).balanceOf(bob));

        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();

        assertEq(discountRate, 25e18);
    }

    // function test_fuzz_discountRateUntilZero2() public {
    //     // Initial setup
    //     deal(address(usdc), address(this), 100e18);
    // IERC20(address(usdc)).approve(address(discountCampaignFactory), 100e18);

    //     IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
    //         rewardAmount: 100e18,
    //         expirationTime: 10 days, // Extended expiration time to ensure the loop has enough time to run.
    //         coolDownPeriod: 0,
    //         discountAmount: 50e18,
    //         pool: address(pool),
    //         owner: address(this),
    //         rewardToken: address(usdc)
    //     });

    //     discountCampaign = DiscountCampaign(discountCampaignFactory.createCampaign(createParams));

    //     uint256 tokenId = 1;
    //     uint256 discountRate;
    //     uint256 maxIterations = 1000; // Increased max limit to ensure the loop has enough iterations to reach zero.
    //     uint256 iterationCount = 0;

    //     // Initial discount rate before starting
    //     (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
    //     console.log("Initial Discount Rate:", discountRate);

    //     // Loop until discountRate becomes zero or reaches max iterations
    //     while (iterationCount < maxIterations) {
    //         // Bound the amount to swap to avoid out of bounds values and ensure consistency
    //         uint256 amountToSwap = bound(
    //             uint256(keccak256(abi.encodePacked(block.timestamp, iterationCount))),
    //             90e18,
    //             100e18 // Setting upper bound to 5e18 to manage rewards correctly
    //         );

    //         // Log the amount being swapped
    //         console.log("Iteration:", iterationCount);
    //         console.log("Bound Result:", amountToSwap);
    //         console.log("Current Discount Rate:", discountRate);

    //         // Swap by Alice
    //         vm.prank(alice);
    //         _doSwapAndCheckBalancesWithAmount(trustedRouter, amountToSwap);

    //         // Get updated discount rate after swap
    //         (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
    //         console.log("Discount Rate After Swap:", discountRate);

    //         // Ensure block time passes for the claim process
    //         vm.warp(block.timestamp + 1);

    //         // Fetch claimable reward directly from the contract for verification
    //         uint256 claimableReward = discountCampaign.getClaimableReward(tokenId);
    //         console.log("Claimable Reward from Contract:", claimableReward);

    //         // Claim rewards for Alice
    //         discountCampaign.claim(tokenId);

    //         // Log claim and check discount rate
    //         console.log("Token ID Claimed:", tokenId);
    //         console.log("Discount Rate After Claim:", discountRate);

    //         // Increment tokenId to ensure next iteration swaps with a different token ID
    //         tokenId++;

    //         // Get the updated discount rate
    //         address rewardToken;
    //         (, , , , discountRate, rewardToken, , ) = discountCampaign.campaignDetails();
    //         console.log("Discount Rate After Claim:", discountRate);

    //         console.log("Reward Amount Left in the contract", IERC20(rewardToken).balanceOf(address(discountCampaign)));

    //         // If discount rate is zero, break the loop
    //         if (discountRate == 0) {
    //             console.log("Discount rate reached zero after iteration:", iterationCount);
    //             break;
    //         }

    //         iterationCount++;
    //     }

    //     // Ensure the loop terminated because the discount rate is zero
    //     assertEq(discountRate, 0, "Discount rate did not reach zero within max iterations");
    // }

    function test_fuzz_discountRate() public {
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

        discountCampaign = DiscountCampaign(discountCampaignFactory.createCampaign(createParams));

        vm.prank(alice);
        _doSwapAndCheckBalancesWithAmount(trustedRouter, poolInitAmount / 100);

        vm.prank(bob);
        _doSwapAndCheckBalancesWithAmount(trustedRouter, poolInitAmount / 80);

        vm.prank(alice);
        _doSwapAndCheckBalancesWithAmount(trustedRouter, poolInitAmount / 30);

        vm.prank(bob);
        _doSwapAndCheckBalancesWithAmount(trustedRouter, poolInitAmount / 150);

        (, , , , uint256 discountRate, , , ) = discountCampaign.campaignDetails();

        assertEq(discountRate, 50e18);

        uint256 swapTime = block.timestamp;

        vm.warp(block.timestamp + 2 days);

        assertEq(discountCampaign.getClaimableReward(1), ((poolInitAmount / 100) * discountRate) / 100e18); //5000000000000000000
        discountCampaign.claim(1);
        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
        assertEq(discountRate, 47500000000000000000);

        assertEq(discountCampaign.getClaimableReward(2), ((poolInitAmount / 80) * 47500000000000000000) / 100e18); //5937500000000000000
        discountCampaign.claim(2);
        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
        assertEq(discountRate, 44531250000000000000);

        assertEq(discountCampaign.getClaimableReward(3), ((poolInitAmount / 30) * 44531250000000000000) / 100e18); //14843750000000000000
        discountCampaign.claim(3);
        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
        assertEq(discountRate, 37109375000000000000);

        assertEq(discountCampaign.getClaimableReward(4), ((poolInitAmount / 150) * 37109375000000000000) / 100e18); //2473958333333333333
        discountCampaign.claim(4);
        (, , , , discountRate, , , ) = discountCampaign.campaignDetails();
        assertEq(discountRate, 35872395833333333334);
    }

    // ===============================================================================

    function createAnotherPool() public returns (address pool2) {
        pool2 = factoryMock.createPool("Test Pool", "TEST");

        if (pool2 != address(0)) {
            approveForPool(IERC20(pool2));
        }
        // Add initial liquidity
        vm.startPrank(lp);
        _initPool(pool2, [poolInitAmount, poolInitAmount].toMemoryArray(), 0);
        vm.stopPrank();

        trustedRouter = payable(router);
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(pool2, tokenConfig, address(factoryMock));
    }

    function _doSwapAndCheckBalancesWithAmount(address payable routerToUse, uint256 amountToSwap) private {
        uint256 exactAmountIn = amountToSwap;
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

    function createCampaign(IDiscountCampaignFactory.CampaignParams memory params) public returns (address) {
        return discountCampaignFactory.createCampaign(params);
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);
        discountCampaignFactory = new DiscountCampaignFactory();
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
}
