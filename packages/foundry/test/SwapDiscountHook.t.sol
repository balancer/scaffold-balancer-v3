// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity ^0.8.24;

// import "forge-std/Test.sol";

// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
// import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
// import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
// import {
//     HooksConfig,
//     LiquidityManagement,
//     PoolRoleAccounts,
//     TokenConfig
// } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

// import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
// import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
// import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

// import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
// import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
// import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
// import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";

// import { SwapDiscountHook } from "../contracts/hooks/SwapDiscountHook/SwapDiscountHook.sol";
// import { console } from "forge-std/console.sol";

// contract SwapDiscountHookTest is BaseVaultTest {
//     using CastingHelpers for address[];
//     using FixedPoint for uint256;
//     using ArrayHelpers for *;

//     uint256 internal daiIdx;
//     uint256 internal usdcIdx;
//     SwapDiscountHook discountHook;

//     // Maximum discount fee of 50%
//     uint64 public constant MAX_SWAP_DISCOUNT_PERCENTAGE = 50e16;

//     address payable internal trustedRouter;

//     function setUp() public override {
//         super.setUp();

//         (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

//         discountHook = SwapDiscountHook(poolHooksContract);
//     }

//     function createHook() internal override returns (address) {
//         trustedRouter = payable(router);

//         // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
//         vm.prank(lp);
//         address swapDiscountHook = address(
//             new SwapDiscountHook(IVault(address(vault)), address(factoryMock), trustedRouter, "SwapDiscountNFT", "SDN")
//         );
//         vm.label(swapDiscountHook, "Swap Discount Hook");
//         return swapDiscountHook;
//     }

//     function testRegistryWithWrongFactorySwap() public {
//         address swapDHook = _createPoolToRegister();
//         TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
//             [address(dai), address(usdc)].toMemoryArray().asIERC20()
//         );

//         uint32 pauseWindowEndTime = IVaultAdmin(address(vault)).getPauseWindowEndTime();
//         uint32 bufferPeriodDuration = IVaultAdmin(address(vault)).getBufferPeriodDuration();
//         uint32 pauseWindowDuration = pauseWindowEndTime - bufferPeriodDuration;
//         address unauthorizedFactory = address(new PoolFactoryMock(IVault(address(vault)), pauseWindowDuration));

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IVaultErrors.HookRegistrationFailed.selector,
//                 poolHooksContract,
//                 swapDHook,
//                 unauthorizedFactory
//             )
//         );
//         _registerPoolWithHook(swapDHook, tokenConfig, unauthorizedFactory);
//     }

//     function testCreationWithWrongFactorySwap() public {
//         address swapDHookPool = _createPoolToRegister();
//         TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
//             [address(dai), address(usdc)].toMemoryArray().asIERC20()
//         );

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IVaultErrors.HookRegistrationFailed.selector,
//                 poolHooksContract,
//                 swapDHookPool,
//                 address(factoryMock)
//             )
//         );
//         _registerPoolWithHook(swapDHookPool, tokenConfig, address(factoryMock));
//     }

//     function testSuccessfulRegistrySwap() public {
//         // Registering with allowed factory
//         address swapDHookPool = factoryMock.createPool("Test Pool", "TEST");
//         TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
//             [address(dai), address(usdc)].toMemoryArray().asIERC20()
//         );

//         _registerPoolWithHook(swapDHookPool, tokenConfig, address(factoryMock));

//         HooksConfig memory hooksConfig = vault.getHooksConfig(swapDHookPool);

//         assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
//         assertEq(hooksConfig.shouldCallAfterSwap, true, "shouldCallAfterSwap is false");
//     }

//     function _registerPoolWithHook(address swapDhookPool, TokenConfig[] memory tokenConfig, address factory) private {
//         PoolRoleAccounts memory roleAccounts;
//         LiquidityManagement memory liquidityManagement;

//         PoolFactoryMock(factory).registerPool(
//             swapDhookPool,
//             tokenConfig,
//             roleAccounts,
//             poolHooksContract,
//             liquidityManagement
//         );
//     }

//     // Registry tests require a new pool, because an existing pool may be already registered
//     function _createPoolToRegister() private returns (address newPool) {
//         newPool = address(new PoolMock(IVault(address(vault)), "SwapD Hook Pool", "swapDHookPool"));
//         vm.label(newPool, "SwapD Hook Pool");
//     }

//     // ======================================================================= //

//     function testUnSuccessfulCreationOfCampaign() public {
//         discountHook.createCampaign(
//             100 ether,
//             block.timestamp + 7 days,
//             2 days,
//             500000000000000000,
//             address(pool),
//             address(this),
//             address(usdc)
//         );
//         vm.expectRevert();
//         discountHook.createCampaign(
//             100 ether,
//             block.timestamp + 7 days,
//             2 days,
//             500000000000000000,
//             address(pool),
//             address(this),
//             address(usdc)
//         );
//     }

//     function testSuccessfulCreationOfCampaign() public {
//         discountHook.createCampaign(
//             100 ether,
//             block.timestamp + 7 days,
//             2 days,
//             500000000000000000,
//             address(pool),
//             address(this),
//             address(usdc)
//         );

//         (address campaignAddress, address owner, address rewardToken, uint256 timeOfCreation) = discountHook
//             .discountCampaigns(address(pool));

//         assertEq(campaignAddress, 0x31f98AFA8142Fdd8B0d1eFfB15E08FeFA7AaAA83, "Address doesnot matches");
//         assertEq(owner, address(this), "Address doesnot matches");
//         assertEq(timeOfCreation, block.timestamp, "time doesnot matches");
//     }

//     function testSuccessfulMintOfNFT() public {
//         discountHook.createCampaign(
//             100 ether,
//             block.timestamp + 7 days,
//             2 days,
//             500000000000000000,
//             address(pool),
//             address(this),
//             address(usdc)
//         );
//         _doSwapAndCheckBalances(trustedRouter);

//         assertEq(IERC721(address(discountHook)).balanceOf(address(bob)), 1);

//         (address userAddress, address campaignAddress, uint256 swappedAmount, uint256 timeOfSwap, ) = discountHook
//             .userDiscountMapping(1);

//         assertEq(campaignAddress, 0x31f98AFA8142Fdd8B0d1eFfB15E08FeFA7AaAA83, "Address doesnot matches");
//         assertEq(userAddress, bob, "Address doesnot matches");
//         assertEq(swappedAmount, poolInitAmount / 100, "Amount doesnot matches");
//         assertEq(timeOfSwap, block.timestamp, "timestamp doesnot matches");
//     }

//     function testUnSuccessfulMintOfNFT() public {
//         _doSwapAndCheckBalances(trustedRouter);
//         assertEq(IERC721(address(discountHook)).balanceOf(address(bob)), 0);
//     }

//     function _doSwapAndCheckBalances(address payable routerToUse) private {
//         uint256 exactAmountIn = poolInitAmount / 100;
//         // PoolMock uses linear math with a rate of 1, so amountIn == amountOut when no fees are applied.
//         uint256 expectedAmountOut = exactAmountIn;

//         BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

//         vm.prank(bob);
//         RouterMock(routerToUse).swapSingleTokenExactIn(
//             pool,
//             dai,
//             usdc,
//             exactAmountIn,
//             expectedAmountOut,
//             MAX_UINT256,
//             false,
//             bytes("")
//         );

//         BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

//         // Bob's balance of DAI is supposed to decrease, since DAI is the token in
//         assertEq(
//             balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
//             exactAmountIn,
//             "Bob's DAI balance is wrong"
//         );
//         // Bob's balance of USDC is supposed to increase, since USDC is the token out
//         assertEq(
//             balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
//             expectedAmountOut,
//             "Bob's USDC balance is wrong"
//         );

//         // Vault's balance of DAI is supposed to increase, since DAI was added by Bob
//         assertEq(
//             balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
//             exactAmountIn,
//             "Vault's DAI balance is wrong"
//         );
//         // Vault's balance of USDC is supposed to decrease, since USDC was given to Bob
//         assertEq(
//             balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
//             expectedAmountOut,
//             "Vault's USDC balance is wrong"
//         );

//         // Pool deltas should equal vault's deltas
//         assertEq(
//             balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
//             exactAmountIn,
//             "Pool's DAI balance is wrong"
//         );
//         assertEq(
//             balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
//             expectedAmountOut,
//             "Pool's USDC balance is wrong"
//         );
//     }
// }
