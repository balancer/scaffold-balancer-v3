// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig,
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
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import { IBatchRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";

import { GaugeRegistry } from "../contracts/mocks/GaugeRegistry.sol";
import { MockQuestBoard } from "../contracts/mocks/MockQuestBoard.sol";
import { QuestSettingsRegistry } from "../contracts/hooks/utils/QuestSettingsRegistry.sol";
import { SereneVeBalDiscountHook } from "../contracts/hooks/SereneVeBalDiscountHook.sol";
import { IQuestBoard } from "../contracts/hooks/interfaces/IQuestBoard.sol";

contract SereneVeBalDiscountHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    GaugeRegistry gaugeRegistry;
    QuestSettingsRegistry questSettings;
    MockQuestBoard questBoard;
    address owner;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    uint256 hookSwapFee = 5e17; // 50%
    uint256 UNIT = 1e18;

    uint256 internal constant SWAP_FEE_PERCENTAGE = 5e16; // 5%

    address payable internal trustedRouter;

    function setUp() public override {
        owner = makeAddr("owner");
        vm.label(owner, "owner");

        gaugeRegistry = new GaugeRegistry();
        questSettings = new QuestSettingsRegistry(owner);
        questBoard = new MockQuestBoard(400, 0);

        vm.prank(owner);
        questSettings.setQuestSettings(
            address(dai),
            1,
            1000,
            2000,
            IQuestBoard.QuestVoteType.NORMAL,
            IQuestBoard.QuestCloseType.NORMAL,
            new address[](0)
        );

        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    function testRegistryWithWrongFactory() public {
        address serenePool = _createPoolToRegister();
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
                serenePool,
                unauthorizedFactory
            )
        );
        _registerPoolWithHook(serenePool, tokenConfig, unauthorizedFactory);
    }

    function testFeeSwapExactInNoVeBal__Fuzz(uint256 swapAmount) public {
        assertEq(veBAL.balanceOf(bob), 0, "Bob has veBAL");
        // Swap between POOL_MINIMUM_TOTAL_SUPPLY and whole pool liquidity (pool math is linear)
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, poolInitAmount);

        uint256 staticFeePercentage = vault.getStaticSwapFeePercentage(address(pool));
        uint256 protocolFeePercentage = staticFeePercentage - ((staticFeePercentage * hookSwapFee) / UNIT);
        uint256 protocolFees = swapAmount.mulUp(protocolFeePercentage);
        uint256 amountCalculatedRaw = swapAmount - protocolFees;
        uint256 reconstructedAmount = (amountCalculatedRaw * (UNIT + protocolFeePercentage)) / UNIT;
        uint256 hookFee = (reconstructedAmount * ((staticFeePercentage * hookSwapFee) / UNIT)) / UNIT;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        uint256 storedHookFeesBefore = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        if (hookFee > 0) {
            vm.expectEmit();
            emit SereneVeBalDiscountHook.HookFeeCharged(poolHooksContract, IERC20(usdc), hookFee);
        }

        vm.prank(bob);
        router.swapSingleTokenExactIn(address(pool), dai, usdc, swapAmount, 0, MAX_UINT256, false, bytes(""));

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        uint256 storedHookFeesAfter = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            swapAmount,
            "Bob DAI balance is wrong"
        );
        assertEq(balancesBefore.hookTokens[daiIdx], balancesAfter.hookTokens[daiIdx], "Hook DAI balance is wrong");
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            swapAmount - hookFee - protocolFees,
            "Bob USDC balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[usdcIdx] - balancesBefore.hookTokens[usdcIdx],
            hookFee,
            "Hook USDC balance is wrong"
        );

        assertEq(storedHookFeesAfter - storedHookFeesBefore, hookFee, "Hook taken fees stored is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            swapAmount,
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            swapAmount - protocolFees,
            "Pool USDC balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            swapAmount,
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            swapAmount - protocolFees,
            "Vault USDC balance is wrong"
        );
    }

    function testFeeSwapExactOutNoVeBal__Fuzz(uint256 swapAmount) public {
        assertEq(veBAL.balanceOf(bob), 0, "Bob has veBAL");
        // Swap between POOL_MINIMUM_TOTAL_SUPPLY and whole pool liquidity (pool math is linear)
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, poolInitAmount);

        uint256 staticFeePercentage = vault.getStaticSwapFeePercentage(address(pool));
        uint256 protocolFeePercentage = staticFeePercentage - ((staticFeePercentage * hookSwapFee) / UNIT);
        uint256 protocolFees = swapAmount.mulDivUp(protocolFeePercentage, protocolFeePercentage.complement());
        uint256 amountCalculatedRaw = swapAmount + protocolFees;
        uint256 reconstructedAmount = (amountCalculatedRaw * (UNIT + protocolFeePercentage)) / UNIT;
        uint256 hookFee = (reconstructedAmount * ((staticFeePercentage * hookSwapFee) / UNIT)) / UNIT;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        uint256 storedHookFeesBefore = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(dai));

        if (hookFee > 0) {
            vm.expectEmit();
            emit SereneVeBalDiscountHook.HookFeeCharged(poolHooksContract, IERC20(dai), hookFee);
        }

        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            dai,
            usdc,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        uint256 storedHookFeesAfter = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(dai));

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            swapAmount + hookFee + protocolFees,
            "Bob DAI balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[daiIdx] - balancesBefore.hookTokens[daiIdx],
            hookFee,
            "Hook DAI balance is wrong"
        );
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            swapAmount,
            "Bob USDC balance is wrong"
        );
        assertEq(balancesAfter.hookTokens[usdcIdx], balancesBefore.hookTokens[usdcIdx], "Hook USDC balance is wrong");

        assertEq(storedHookFeesAfter - storedHookFeesBefore, hookFee, "Hook taken fees stored is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            swapAmount + protocolFees,
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            swapAmount,
            "Pool USDC balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            swapAmount + protocolFees,
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            swapAmount,
            "Vault USDC balance is wrong"
        );
    }

    function testFeeSwapExactInWithVeBal__Fuzz(uint256 swapAmount) public {
        // Mint 1 veBAL to Bob, so he's able to receive the fee discount.
        veBAL.mint(bob, 1);
        assertGt(veBAL.balanceOf(bob), 0, "Bob does not have veBAL");
        // Swap between POOL_MINIMUM_TOTAL_SUPPLY and whole pool liquidity (pool math is linear)
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, poolInitAmount);

        uint256 staticFeePercentage = vault.getStaticSwapFeePercentage(address(pool)) / 2;
        uint256 protocolFeePercentage = staticFeePercentage - ((staticFeePercentage * hookSwapFee) / UNIT);
        uint256 protocolFees = swapAmount.mulUp(protocolFeePercentage);
        uint256 amountCalculatedRaw = swapAmount - protocolFees;
        uint256 reconstructedAmount = (amountCalculatedRaw * (UNIT + protocolFeePercentage)) / UNIT;
        uint256 hookFee = (reconstructedAmount * ((staticFeePercentage * hookSwapFee) / UNIT)) / UNIT;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        uint256 storedHookFeesBefore = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        if (hookFee > 0) {
            vm.expectEmit();
            emit SereneVeBalDiscountHook.HookFeeCharged(poolHooksContract, IERC20(usdc), hookFee);
        }

        vm.prank(bob);
        router.swapSingleTokenExactIn(address(pool), dai, usdc, swapAmount, 0, MAX_UINT256, false, bytes(""));

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        uint256 storedHookFeesAfter = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            swapAmount,
            "Bob DAI balance is wrong"
        );
        assertEq(balancesBefore.hookTokens[daiIdx], balancesAfter.hookTokens[daiIdx], "Hook DAI balance is wrong");
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            swapAmount - hookFee - protocolFees,
            "Bob USDC balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[usdcIdx] - balancesBefore.hookTokens[usdcIdx],
            hookFee,
            "Hook USDC balance is wrong"
        );

        assertEq(storedHookFeesAfter - storedHookFeesBefore, hookFee, "Hook taken fees stored is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            swapAmount,
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            swapAmount - protocolFees,
            "Pool USDC balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            swapAmount,
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            swapAmount - protocolFees,
            "Vault USDC balance is wrong"
        );
    }

    function testFeeSwapExactOutWithVeBal__Fuzz(uint256 swapAmount) public {
        // Mint 1 veBAL to Bob, so he's able to receive the fee discount.
        veBAL.mint(bob, 1);
        assertGt(veBAL.balanceOf(bob), 0, "Bob does not have veBAL");
        // Swap between POOL_MINIMUM_TOTAL_SUPPLY and whole pool liquidity (pool math is linear)
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, poolInitAmount);

        uint256 staticFeePercentage = vault.getStaticSwapFeePercentage(address(pool)) / 2;
        uint256 protocolFeePercentage = staticFeePercentage - ((staticFeePercentage * hookSwapFee) / UNIT);
        uint256 protocolFees = swapAmount.mulDivUp(protocolFeePercentage, protocolFeePercentage.complement());
        uint256 amountCalculatedRaw = swapAmount + protocolFees;
        uint256 reconstructedAmount = (amountCalculatedRaw * (UNIT + protocolFeePercentage)) / UNIT;
        uint256 hookFee = (reconstructedAmount * ((staticFeePercentage * hookSwapFee) / UNIT)) / UNIT;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        uint256 storedHookFeesBefore = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(dai));

        if (hookFee > 0) {
            vm.expectEmit();
            emit SereneVeBalDiscountHook.HookFeeCharged(poolHooksContract, IERC20(dai), hookFee);
        }

        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            dai,
            usdc,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        uint256 storedHookFeesAfter = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(dai));

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            swapAmount + hookFee + protocolFees,
            "Bob DAI balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[daiIdx] - balancesBefore.hookTokens[daiIdx],
            hookFee,
            "Hook DAI balance is wrong"
        );
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            swapAmount,
            "Bob USDC balance is wrong"
        );
        assertEq(balancesAfter.hookTokens[usdcIdx], balancesBefore.hookTokens[usdcIdx], "Hook USDC balance is wrong");

        assertEq(storedHookFeesAfter - storedHookFeesBefore, hookFee, "Hook taken fees stored is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            swapAmount + protocolFees,
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            swapAmount,
            "Pool USDC balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            swapAmount + protocolFees,
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            swapAmount,
            "Vault USDC balance is wrong"
        );
    }

    function testFeeSwapExactInUntrustedRouter__Fuzz(uint256 swapAmount) public {
        // Mint 1 veBAL to Bob, so he's able to receive the fee discount.
        veBAL.mint(bob, 1);
        assertGt(veBAL.balanceOf(bob), 0, "Bob does not have veBAL");
        // Swap between POOL_MINIMUM_TOTAL_SUPPLY and whole pool liquidity (pool math is linear)
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, poolInitAmount);

        // Create an untrusted router
        address payable untrustedRouter = payable(new RouterMock(IVault(address(vault)), weth, permit2));
        vm.label(untrustedRouter, "untrusted router");

        // Allows permit2 to move DAI tokens from Bob to untrustedRouter.
        vm.prank(bob);
        permit2.approve(address(dai), untrustedRouter, type(uint160).max, type(uint48).max);

        uint256 staticFeePercentage = vault.getStaticSwapFeePercentage(address(pool));
        uint256 protocolFeePercentage = staticFeePercentage - ((staticFeePercentage * hookSwapFee) / UNIT);
        uint256 protocolFees = swapAmount.mulUp(protocolFeePercentage);
        uint256 amountCalculatedRaw = swapAmount - protocolFees;
        uint256 reconstructedAmount = (amountCalculatedRaw * (UNIT + protocolFeePercentage)) / UNIT;
        uint256 hookFee = (reconstructedAmount * ((staticFeePercentage * hookSwapFee) / UNIT)) / UNIT;

        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);

        uint256 storedHookFeesBefore = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        if (hookFee > 0) {
            vm.expectEmit();
            emit SereneVeBalDiscountHook.HookFeeCharged(poolHooksContract, IERC20(usdc), hookFee);
        }

        vm.prank(bob);
        RouterMock(untrustedRouter).swapSingleTokenExactIn(address(pool), dai, usdc, swapAmount, 0, MAX_UINT256, false, bytes(""));

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        uint256 storedHookFeesAfter = SereneVeBalDiscountHook(poolHooksContract).takenFees(address(pool), address(usdc));

        assertEq(
            balancesBefore.userTokens[daiIdx] - balancesAfter.userTokens[daiIdx],
            swapAmount,
            "Bob DAI balance is wrong"
        );
        assertEq(balancesBefore.hookTokens[daiIdx], balancesAfter.hookTokens[daiIdx], "Hook DAI balance is wrong");
        assertEq(
            balancesAfter.userTokens[usdcIdx] - balancesBefore.userTokens[usdcIdx],
            swapAmount - hookFee - protocolFees,
            "Bob USDC balance is wrong"
        );
        assertEq(
            balancesAfter.hookTokens[usdcIdx] - balancesBefore.hookTokens[usdcIdx],
            hookFee,
            "Hook USDC balance is wrong"
        );

        assertEq(storedHookFeesAfter - storedHookFeesBefore, hookFee, "Hook taken fees stored is wrong");

        assertEq(
            balancesAfter.poolTokens[daiIdx] - balancesBefore.poolTokens[daiIdx],
            swapAmount,
            "Pool DAI balance is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            swapAmount - protocolFees,
            "Pool USDC balance is wrong"
        );
        assertEq(
            balancesAfter.vaultTokens[daiIdx] - balancesBefore.vaultTokens[daiIdx],
            swapAmount,
            "Vault DAI balance is wrong"
        );
        assertEq(
            balancesBefore.vaultTokens[usdcIdx] - balancesAfter.vaultTokens[usdcIdx],
            swapAmount - protocolFees,
            "Vault USDC balance is wrong"
        );
    }

    function testNoGaugeWhenCreatingQuest() public {
        IBatchRouter.SwapPathStep[][] memory steps = new IBatchRouter.SwapPathStep[][](0);

        vm.expectRevert(SereneVeBalDiscountHook.CannotCreateQuest.selector);
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);
    }

    function testQuestAlreadyCreatedForThisEpoch__Fuzz(uint256 swapAmount) public {
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, 1e19);
        gaugeRegistry.register(address(pool), makeAddr("gauge"));

        // Swap to get USDC fees
        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            usdc,
            dai,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        IBatchRouter.SwapPathStep[][] memory steps = new IBatchRouter.SwapPathStep[][](2);
        steps[0] = new IBatchRouter.SwapPathStep[](1);
        steps[0][0] = IBatchRouter.SwapPathStep({ pool: address(pool), tokenOut: dai, isBuffer: false });
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);

        uint48[] memory periods = new uint48[](1);
        periods[0] = 0;
        questBoard.setPeriodsForQuestId(1, periods);

        vm.expectRevert(SereneVeBalDiscountHook.CannotCreateQuest.selector);
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);
    }

    function testCreateNormalQuestSecondEpoch__Fuzz(uint256 swapAmount) public {
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, 1e19);
        gaugeRegistry.register(address(pool), makeAddr("gauge"));

        // Swap to get USDC fees
        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            usdc,
            dai,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        IBatchRouter.SwapPathStep[][] memory steps = new IBatchRouter.SwapPathStep[][](2);
        steps[0] = new IBatchRouter.SwapPathStep[](1);
        steps[0][0] = IBatchRouter.SwapPathStep({ pool: address(pool), tokenOut: dai, isBuffer: false });
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);

        // Swap to get USDC fees
        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            usdc,
            dai,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        uint48[] memory periods = new uint48[](1);
        periods[0] = 0;
        questBoard.setPeriodsForQuestId(1, periods);
        questBoard.setPeriod(1);

        vm.expectCall(address(questBoard), abi.encodeWithSelector(IQuestBoard.createRangedQuest.selector));
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);

        assertEq(SereneVeBalDiscountHook(poolHooksContract).gauges(address(pool)), makeAddr("gauge"), "Gauge not set");
        assertEq(SereneVeBalDiscountHook(poolHooksContract).lastQuestCreated(address(pool)), 1, "Quest not created");
        assertEq(usdc.balanceOf(poolHooksContract), 0, "Usdc balance is wrong");
        assertApproxEqAbs(dai.balanceOf(poolHooksContract), 0, 1, "Dai balance is wrong");
    }

    function testCreateNormalQuest__Fuzz(uint256 swapAmount) public {
        swapAmount = bound(swapAmount, POOL_MINIMUM_TOTAL_SUPPLY, 1e19);
        gaugeRegistry.register(address(pool), makeAddr("gauge"));

        // Swap to get USDC fees
        vm.prank(bob);
        router.swapSingleTokenExactOut(
            address(pool),
            usdc,
            dai,
            swapAmount,
            MAX_UINT256,
            block.timestamp + 1,
            false,
            bytes("")
        );

        IBatchRouter.SwapPathStep[][] memory steps = new IBatchRouter.SwapPathStep[][](2);
        steps[0] = new IBatchRouter.SwapPathStep[](1);
        steps[0][0] = IBatchRouter.SwapPathStep({ pool: address(pool), tokenOut: dai, isBuffer: false });
        vm.expectCall(address(questBoard), abi.encodeWithSelector(IQuestBoard.createRangedQuest.selector));
        SereneVeBalDiscountHook(poolHooksContract).createQuest(address(pool), steps);

        assertEq(SereneVeBalDiscountHook(poolHooksContract).gauges(address(pool)), makeAddr("gauge"), "Gauge not set");
        assertEq(SereneVeBalDiscountHook(poolHooksContract).lastQuestCreated(address(pool)), 1, "Quest not created");
        assertEq(usdc.balanceOf(poolHooksContract), 0, "Usdc balance is wrong");
        assertApproxEqAbs(dai.balanceOf(poolHooksContract), 0, 1, "Dai balance is wrong");
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);

        // lp will be the owner of the hook.
        address sereneHook = address(
            new SereneVeBalDiscountHook(
                IVault(address(vault)),
                permit2,
                address(factoryMock),
                address(gaugeRegistry),
                address(batchRouter),
                address(questBoard),
                address(questSettings),
                address(dai),
                uint64(hookSwapFee),
                address(veBAL),
                trustedRouter
            )
        );
        vm.label(sereneHook, "sereneHook");
        return address(sereneHook);
    }

    // Overrides pool creation to set liquidityManagement (disables unbalanced liquidity)
    function _createPool(address[] memory tokens, string memory label) internal override returns (address) {
        address newPool = factoryMock.createPool("SereneVeBalDiscountHook Pool", "SNKP");
        vm.label(address(newPool), label);

        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;

        factoryMock.registerPool(
            address(newPool),
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), admin);
        vm.prank(admin);
        vault.setStaticSwapFeePercentage(newPool, SWAP_FEE_PERCENTAGE);

        return address(newPool);
    }

    // Registry tests require a new pool, because an existing pool may be already registered
    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(new PoolMock(IVault(address(vault)), "SereneVeBalDiscountHook Pool", "SHK"));
        vm.label(newPool, "newPool");
    }

    function _registerPoolWithHook(address exitFeePool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;

        PoolFactoryMock(factory).registerPool(
            exitFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
