// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { LiquidityManagement, PoolRoleAccounts } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVaultExtension } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultMock } from "@balancer-labs/v3-interfaces/contracts/test/IVaultMock.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { BasicAuthorizerMock } from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BaseTest } from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseTest.sol";
import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";

import { BatchRouterMock } from "@balancer-labs/v3-vault/contracts/test/BatchRouterMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { WeightedPoolFactory } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";
import { WeightedPool } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPool.sol";
import { VaultMockDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultMockDeployer.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { ReBalancerHook, IOracle, TokenData } from "../contracts/hooks/rebalancer/Rebalancer.sol";
import { Oracle } from "../contracts/hooks/rebalancer/Oracle.sol";
import { SwapKind } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { BasePoolTest } from "@balancer-labs/v3-vault/test/foundry/utils/BasePoolTest.sol";
import { PoolHooksMock } from "@balancer-labs/v3-vault/contracts/test/PoolHooksMock.sol";

contract ReBalancerHookE2E is BaseVaultTest {
    using CastingHelpers for address[];
    using ArrayHelpers for *;
    using FixedPoint for uint256;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    // Maximum exit fee of 10%
    uint64 public constant MAX_EXIT_FEE_PERCENTAGE = 10e16;

    uint256 internal constant DEFAULT_AMP_FACTOR = 200;
    uint256 constant DEFAULT_SWAP_FEE = 1e16; // 1%
    uint256 constant TOKEN_AMOUNT = 1e3 * 1e18;

    ReBalancerHook internal rebalancer;

    uint256[] internal weights;
    uint256[] internal tokenAmounts;
    IERC20[] internal poolTokens;
    Oracle internal oracle;
    address ORACLE = 0x1f5D28a5b9a79A18eC5c1f12edaB35b7D13d1615;

    WeightedPoolFactory internal _factoryMock;

    // Overrides to include a deployment forReBalancerHook
    function setUp() public virtual override {
        BaseTest.setUp();

        vault = IVaultMock(address(VaultMockDeployer.deploy()));
        vm.label(address(vault), "vault");
        vaultExtension = IVaultExtension(vault.getVaultExtension());
        vm.label(address(vaultExtension), "vaultExtension");
        vaultAdmin = IVaultAdmin(vault.getVaultAdmin());
        vm.label(address(vaultAdmin), "vaultAdmin");
        authorizer = BasicAuthorizerMock(address(vault.getAuthorizer()));
        vm.label(address(authorizer), "authorizer");
        factoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));
        _factoryMock = new WeightedPoolFactory(IVault(address(vault)), 365 days, "Factory v1", "Pool v1");
        vm.label(address(factoryMock), "factory");
        router = new RouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(router), "router");
        batchRouter = new BatchRouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(batchRouter), "batch router");
        feeController = vault.getProtocolFeeController();
        vm.label(address(feeController), "fee controller");
        oracle = new Oracle(100 * 1e20, ORACLE);
        rebalancer = new ReBalancerHook(IVault(address(vault)), permit2, weth, address(factoryMock), address(oracle));
        vm.label(address(rebalancer), "rebalancer");

        // Here the router is also the hook
        poolHooksContract = address(rebalancer);
        pool = createPool();

        // Approve vault allowances
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender();
            vm.stopPrank();
        }
        if (pool != address(0)) {
            approveForPool(IERC20(pool));
        }
        // Add initial liquidity
        initPool();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    // Overrides approval to include NFTRouter
    function approveForSender() internal override {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(permit2), type(uint256).max);
            permit2.approve(address(tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(rebalancer), type(uint160).max, type(uint48).max);
        }
    }

    // Overrides approval to include NFTRouter
    function approveForPool(IERC20 bpt) internal override {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);

            bpt.approve(address(router), type(uint256).max);
            bpt.approve(address(batchRouter), type(uint256).max);
            bpt.approve(address(rebalancer), type(uint256).max);

            IERC20(bpt).approve(address(permit2), type(uint256).max);
            permit2.approve(address(bpt), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(rebalancer), type(uint160).max, type(uint48).max);

            vm.stopPrank();
        }
    }

    // Overrides pool creation to set liquidityManagement (disables unbalanced liquidity).
    function createPool() internal override returns (address) {
        IERC20[] memory sortedTokens = InputHelpers.sortTokens(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );
        for (uint256 i = 0; i < sortedTokens.length; i++) {
            poolTokens.push(sortedTokens[i]);
            tokenAmounts.push(TOKEN_AMOUNT);
        }

        weights = [uint256(50e16), uint256(50e16)].toMemoryArray();

        PoolRoleAccounts memory roleAccounts;
        // Allow pools created by `factory` to use poolHooksMock hooks
        // PoolHooksMock(poolHooksContract).allowFactory(address(_factoryMock));

        WeightedPool newPool = WeightedPool(
            WeightedPoolFactory(address(_factoryMock)).create(
                "ERC20 Pool",
                "ERC20POOL",
                vault.buildTokenConfig(sortedTokens),
                weights,
                roleAccounts,
                DEFAULT_SWAP_FEE,
                poolHooksContract,
                false, // Do not enable donations
                false, // Do not disable unbalanced add/remove liquidity
                ZERO_BYTES32
            )
        );
        return address(newPool);
    }

    function testAddLiquidity() public {
        BaseVaultTest.Balances memory balancesBefore = getBalances(bob);
        uint256[] memory maxAmountsIn = [dai.balanceOf(bob), usdc.balanceOf(bob)].toMemoryArray();
        vm.prank(bob);
        uint256[] memory amountsIn = rebalancer.addLiquidityProportional(
            pool,
            maxAmountsIn,
            bptAmount,
            false,
            bytes("")
        );
        vm.stopPrank();

        BaseVaultTest.Balances memory balancesAfter = getBalances(bob);

        // bob sends correct lp tokens
        assertEq(
            balancesBefore.bobTokens[daiIdx] - balancesAfter.bobTokens[daiIdx],
            amountsIn[daiIdx],
            "bob's DAI amount is wrong"
        );
        assertEq(
            balancesBefore.bobTokens[usdcIdx] - balancesAfter.bobTokens[usdcIdx],
            amountsIn[usdcIdx],
            "bob's USDC amount is wrong"
        );
    }

    function setUpRebalanceData(address pool, uint256[] memory minRatios) internal {
        ReBalancerHook.RebalanceData[] memory data = new ReBalancerHook.RebalanceData[](2);
        for (uint256 i = 0; i < 2; i++) {
            data[i] = ReBalancerHook.RebalanceData({ minRatio: minRatios[i], rebalanceRequired: false });
        }

        vm.prank(address(0)); // Only pool creator can set rebalance data
        rebalancer.setRebalanceData(pool, data);
    }

    function testRebalancing() public {
        // Set up initial liquidity with both Bob and Alice
        uint256[] memory maxAmountsInBob = [dai.balanceOf(bob), usdc.balanceOf(bob)].toMemoryArray();
        vm.prank(bob);
        rebalancer.addLiquidityProportional(pool, maxAmountsInBob, bptAmount, false, "");

        uint256[] memory maxAmountsInAlice = [dai.balanceOf(alice), usdc.balanceOf(alice)].toMemoryArray();
        vm.prank(alice);
        rebalancer.addLiquidityProportional(pool, maxAmountsInAlice, bptAmount, false, "");

        // et up rebalance thresholds (1% change trigger)
        uint256[] memory minRatios = new uint256[](2);
        minRatios[0] = 1e16; // 1% for DAI
        minRatios[1] = 1e16; // 1% for USDC
        setUpRebalanceData(pool, minRatios);

        // Record initial balances
        BaseVaultTest.Balances memory balancesBefore = getBalances(address(pool));

        // Mock a significant price change in DAI (5% increase)
        uint256 daiInitialPrice = 1e8; // $1.00 in 1e8 precision
        uint256 usdcInitialPrice = 1e8; // $1.00
        uint256 daiPredictedPrice = 155e6; // $1.55
        uint256 usdcPredictedPrice = 1e8; // No change in USDC

        TokenData[] memory tokensData = new TokenData[](2);
        tokensData[0] = TokenData({ latestRoundPrice: daiInitialPrice, predictedPrice: daiPredictedPrice });
        tokensData[1] = TokenData({ latestRoundPrice: usdcInitialPrice, predictedPrice: usdcPredictedPrice });

        vm.prank(ORACLE);
        oracle.setPoolTokensData(pool, tokensData);

        require(oracle.getPoolTokensData(pool)[0].predictedPrice == daiPredictedPrice, "Predicted Price is not set");
        require(oracle.getPoolTokensData(pool)[1].predictedPrice == usdcPredictedPrice, "Predicted Price is not set");

        // Trigger rebalancing through a swap
        vm.expectEmit(true, true, true, true);
        emit ReBalancerHook.RebalanceStarted(pool);

        // Perform a small swap to trigger rebalancing
        vm.prank(bob);
        rebalancer.swapSingleTokenExactIn(
            pool,
            tokens[daiIdx],
            tokens[usdcIdx],
            1e18, // 1 DAI
            0,
            block.timestamp + 1000,
            true,
            "" // No min amount out
        );

        // Verify rebalancing effects
        BaseVaultTest.Balances memory balancesAfter = getBalances(address(pool));

        // Verify DAI balance increased (as it's worth more)
        assertGt(
            balancesAfter.poolTokens[daiIdx],
            balancesBefore.poolTokens[daiIdx],
            "DAI balance should increase after rebalancing"
        );

        // Verify USDC balance decreased proportionally
        assertLt(
            balancesAfter.poolTokens[usdcIdx],
            balancesBefore.poolTokens[usdcIdx],
            "USDC balance should decrease after rebalancing"
        );

        // Verify the ratios are closer to target after rebalancing
        uint256 initialRatio = balancesBefore.poolTokens[daiIdx].divDown(balancesBefore.poolTokens[usdcIdx]);
        uint256 finalRatio = balancesAfter.poolTokens[daiIdx].divDown(balancesAfter.poolTokens[usdcIdx]);
        uint256 targetRatio = daiPredictedPrice.divDown(usdcPredictedPrice);

        uint256 initialDiff = initialRatio > targetRatio ? initialRatio - targetRatio : targetRatio - initialRatio;
        uint256 finalDiff = finalRatio > targetRatio ? finalRatio - targetRatio : targetRatio - finalRatio;

        assertLt(finalDiff, initialDiff, "Rebalancing should move ratios closer to target");
    }
}
