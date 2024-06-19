// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import {TokenConfig, PoolConfig} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ArrayHelpers.sol";
import {BasicAuthorizerMock} from "@balancer-labs/v3-solidity-utils/contracts/test/BasicAuthorizerMock.sol";
import {ERC20TestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import {WETHTestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/WETHTestToken.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {Vault} from "@balancer-labs/v3-vault/contracts/Vault.sol";
import {Router} from "@balancer-labs/v3-vault/contracts/Router.sol";
import {VaultMock} from "@balancer-labs/v3-vault/contracts/test/VaultMock.sol";
import {PoolConfigBits, PoolConfigLib} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";

import {BaseVaultTest} from "@test/vault/test/foundry/utils/BaseVaultTest.sol";
import {ConstantSumPool} from "../contracts/ConstantSumPool.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";

/**
 * @title Custom Pool Starter Test Template
 * @author BUIDL GUIDL
 * @notice This test file serves as a starting template that developers can use when creating their own BalancerV3 custom pool tests. Paired with the README, this template has comments marked "TODO" that help guide devlopers to address starting test aspects. This is not production ready, and it is the developers responsibility to carry out proper testing and auditing for their pool.
 * These tests roughly mirror the typical testing cases that are found in the BalancerV3 monorepo for weighted pool tests.  As a reference tool, it only makes sense to have tests that, at the very least, roughly mirror how weighted pools are tested within BalancerV3 monorepo.
 * @dev This template is written for the Constant Price Custom Pool.
 * When creating your own custom pool, developers are expected to: create their own custom pool file, test file, script file, and of course update dependencies as needed. They simply can just duplicate or override the files that are in this repo marked as "example" within their title.
 */
contract CustomPoolTemplateTest is BaseVaultTest {
    using ArrayHelpers for *;

    CustomPoolFactoryExample factory; // TODO - use your own custom pool factory when working with your own custom pool type.
    ConstantSumPool internal constantSumPool; // TODO - use your own custom pool type of course.

    uint256 constant USDC_AMOUNT = 1e3 * 1e18;
    uint256 constant DAI_AMOUNT = 1e3 * 1e18;

    uint256 constant DAI_AMOUNT_IN = 1 * 1e18;
    uint256 constant USDC_AMOUNT_OUT = 1 * 1e18;

    uint256 constant DELTA = 1e9;

    uint256 internal bptAmountOut;

    // TODO - setup may require further details depending on your custom pool specifications. This is just a basic setup as per the README.
    function setUp() public virtual override {
        BaseVaultTest.setUp();
    }

    /**
     * @dev Tests to ensure that pool pause state and associated details are correct (bool pause, pauseWindow duration, bufferPeriod duration, and pauseManager) - recall that these are specified within your custom pool factory contract.
     * For further information, see `FactoryWidePauseWindow.sol` that is inherited by `BasePoolFactory.sol`, which is inherited by the custom pool factory (`CustomPoolFactoryExample.sol`) used in these tests.
     */
    function testPoolPausedState() public {
        (
            bool paused,
            uint256 pauseWindow,
            uint256 bufferPeriod,
            address pauseManager
        ) = vault.getPoolPausedState(address(pool));

        assertFalse(paused);
        assertApproxEqAbs(pauseWindow, START_TIMESTAMP + 365 days, 1);
        assertApproxEqAbs(
            bufferPeriod,
            START_TIMESTAMP + 365 days + 30 days,
            1
        );
        assertEq(pauseManager, address(0));
    }

    /**
     * @dev Checks status of lp, vault, and pool after initialization, by doing the following:
     * - Checks LP balance of pool’s underlying ERC20 tokens and that it has transferred ERC20
     * - Checks that vault has the correct underlying ERC20 balances newly transferred from lp
     * - Checks the vault’s internal accounting for the respective pool; recall that the vault has all of the ERC20s and does internal accounting for respective pools. Aka the pools don’t hold the respective underlying ERC20s, the vault does.
     */
    function testInitialize() public {
        // Tokens are transferred from lp
        assertEq(
            defaultBalance - usdc.balanceOf(lp),
            USDC_AMOUNT,
            "LP: Wrong USDC balance"
        );
        assertEq(
            defaultBalance - dai.balanceOf(lp),
            DAI_AMOUNT,
            "LP: Wrong DAI balance"
        );

        // Tokens are stored in the Vault
        assertEq(
            usdc.balanceOf(address(vault)),
            USDC_AMOUNT,
            "Vault: Wrong USDC balance"
        );
        assertEq(
            dai.balanceOf(address(vault)),
            DAI_AMOUNT,
            "Vault: Wrong DAI balance"
        );

        // Tokens are deposited to the pool
        (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(
            address(pool)
        );
        assertEq(balances[0], DAI_AMOUNT, "Pool: Wrong DAI balance");
        assertEq(balances[1], USDC_AMOUNT, "Pool: Wrong USDC balance");

        // should mint correct amount of BPT tokens
        // Account for the precision loss
        assertApproxEqAbs(
            constantSumPool.balanceOf(lp),
            bptAmountOut,
            DELTA,
            "LP: Wrong bptAmountOut"
        );
        assertApproxEqAbs(
            bptAmountOut,
            2 * DAI_AMOUNT,
            DELTA,
            "Wrong bptAmountOut"
        ); // TODO - "2 * DAI_AMOUNT" is the amount expected with this type of custom pool. This may differ for your pool type and its invariant.
    }

    /**
     * @dev Checks status of Bob, vault, and pool after adding liquidity via `addLiquidityUnbalanced()`, by doing the following:
     * - Adds liquidity to pool via calling `addLiquidityUnbalanced()` from the Router - see `IRouter.sol` natspec for function.
     * - Checks Bob's balance of pool’s underlying ERC20 tokens and that they have transferred ERC20
     * - Checks that vault has the correct underlying ERC20 balances newly transferred from Bob
     * - Checks the vault’s internal accounting for the respective pool; recall that the vault has all of the ERC20s and does internal accounting for respective pools. Aka the pools don’t hold the respective underlying ERC20s, the vault does.
     * - Checks that Bob has the correct amount of BPTs from the tx.
     */
    function testAddLiquidity() public {
        uint256[] memory amountsIn = [uint256(DAI_AMOUNT), uint256(USDC_AMOUNT)]
            .toMemoryArray();
        vm.prank(bob);
        bptAmountOut = router.addLiquidityUnbalanced(
            address(pool),
            amountsIn,
            DAI_AMOUNT - DELTA,
            false,
            bytes("")
        );

        // Tokens are transferred from Bob
        assertEq(
            defaultBalance - usdc.balanceOf(bob),
            USDC_AMOUNT,
            "LP: Wrong USDC balance"
        );
        assertEq(
            defaultBalance - dai.balanceOf(bob),
            DAI_AMOUNT,
            "LP: Wrong DAI balance"
        );

        // Tokens are stored in the Vault
        assertEq(
            usdc.balanceOf(address(vault)),
            USDC_AMOUNT * 2,
            "Vault: Wrong USDC balance"
        );
        assertEq(
            dai.balanceOf(address(vault)),
            DAI_AMOUNT * 2,
            "Vault: Wrong DAI balance"
        );

        // Tokens are deposited to the pool
        (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(
            address(pool)
        );
        assertEq(balances[0], DAI_AMOUNT * 2, "Pool: Wrong DAI balance");
        assertEq(balances[1], USDC_AMOUNT * 2, "Pool: Wrong USDC balance");

        // should mint correct amount of BPT tokens
        assertApproxEqAbs(
            constantSumPool.balanceOf(bob),
            bptAmountOut,
            DELTA,
            "LP: Wrong bptAmountOut"
        );
        assertApproxEqAbs(
            bptAmountOut,
            2 * DAI_AMOUNT,
            DELTA,
            "Wrong bptAmountOut"
        ); // TODO - "2 * DAI_AMOUNT" is the amount expected with this type of custom pool. This may differ for your pool type and its invariant.
    }

    /**
     * @dev Checks status of lp, vault, and pool after removing liquidity via `removeLiquidityProportional()`, by doing the following:
     * - Adds liquidity to pool via calling `addLiquidityUnbalanced()` from the Router - see `IRouter.sol` natspec for function.
     * - Removes liquidity via calling `removeLiquidityProportional()` from the Router - see `IRouter.sol` natspec for function.
     * - Checks Bob's balance of pool’s underlying ERC20 tokens and that they have received their initial ERC20 transfer back from vault.
     * - Checks that vault has the correct underlying ERC20 balances, which was the amount initialized by user 'lp'.
     * - Checks the vault’s internal accounting for the respective pool; recall that the vault has all of the ERC20s and does internal accounting for respective pools. Aka the pools don’t hold the respective underlying ERC20s, the vault does.
     * - Checks that the return value from calling `removeLiquidityProportional()` is correct and equals to amount specified in param `minAmountsOut` for function.
     * - Checks that Bob no longer has any BPT, and that the amount he had before calling `removeLiquidityProportional()` was the same as the amount requested of BPT to be redeemed.
     */
    function testRemoveLiquidity() public {
        vm.startPrank(bob);
        router.addLiquidityUnbalanced(
            address(pool),
            [uint256(DAI_AMOUNT), uint256(USDC_AMOUNT)].toMemoryArray(),
            DAI_AMOUNT - DELTA,
            false,
            bytes("")
        );

        constantSumPool.approve(address(vault), type(uint256).max);

        uint256 bobBptBalance = constantSumPool.balanceOf(bob);
        uint256 bptAmountIn = bobBptBalance;

        uint256[] memory amountsOut = router.removeLiquidityProportional(
            address(pool),
            bptAmountIn,
            [uint256(less(DAI_AMOUNT, 1e4)), uint256(less(USDC_AMOUNT, 1e4))]
                .toMemoryArray(),
            false,
            bytes("")
        );

        vm.stopPrank();

        // Tokens are transferred to Bob
        assertApproxEqAbs(
            usdc.balanceOf(bob),
            defaultBalance,
            DELTA,
            "LP: Wrong USDC balance"
        );
        assertApproxEqAbs(
            dai.balanceOf(bob),
            defaultBalance,
            DELTA,
            "LP: Wrong DAI balance"
        );

        // Tokens are stored in the Vault
        assertApproxEqAbs(
            usdc.balanceOf(address(vault)),
            USDC_AMOUNT,
            DELTA,
            "Vault: Wrong USDC balance"
        );
        assertApproxEqAbs(
            dai.balanceOf(address(vault)),
            DAI_AMOUNT,
            DELTA,
            "Vault: Wrong DAI balance"
        );

        // Tokens are deposited to the pool
        (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(
            address(pool)
        );
        assertApproxEqAbs(
            balances[0],
            DAI_AMOUNT,
            DELTA,
            "Pool: Wrong DAI balance"
        );
        assertApproxEqAbs(
            balances[1],
            USDC_AMOUNT,
            DELTA,
            "Pool: Wrong USDC balance"
        );

        // amountsOut are correct
        assertApproxEqAbs(
            amountsOut[0],
            DAI_AMOUNT,
            DELTA,
            "Wrong DAI AmountOut"
        );
        assertApproxEqAbs(
            amountsOut[1],
            USDC_AMOUNT,
            DELTA,
            "Wrong USDC AmountOut"
        );

        // should mint correct amount of BPT tokens
        assertEq(constantSumPool.balanceOf(bob), 0, "LP: Wrong BPT balance");
        assertEq(bobBptBalance, bptAmountIn, "LP: Wrong bptAmountIn");
    }

    /**
     * @dev Checks status of the user (Bob), vault, and pool after carrying out a swap tx with the pool (swap DAI for USDC) by doing the following:
     * - Bob swaps DAI for USDC with pool by calling `swapSingleTokenExactIn()` from router - see `IRouter.sol` natspec for function.
     * - Checks Bob's balance of pool’s underlying ERC20 tokens and that they have received at least the amount of USDC requested in swap. Also checks amount of DAI Bob has and that his balance is reduced as expected from the swap.
     * - Checks that vault has the correct underlying ERC20 balances, which should be an increased amount of DAI, and lessened amount of USDC from swap tx.
     * - Checks the vault’s internal accounting for the respective pool. It does this by grabbing the appropriate token indices to use when checking `balances` array from `getPoolTokenInfo(address(pool))` from the vault. Of course the USDC should be lessened and the DAI should be increased from the swap tx.
     */
    function testSwap() public {
        vm.prank(bob);
        uint256 amountCalculated = router.swapSingleTokenExactIn(
            address(pool),
            dai,
            usdc,
            DAI_AMOUNT_IN,
            less(USDC_AMOUNT_OUT, 1e3),
            type(uint256).max,
            false,
            bytes("")
        );

        // Tokens are transferred from Bob
        assertEq(
            usdc.balanceOf(bob),
            defaultBalance + amountCalculated,
            "LP: Wrong USDC balance"
        );
        assertEq(
            dai.balanceOf(bob),
            defaultBalance - DAI_AMOUNT_IN,
            "LP: Wrong DAI balance"
        );

        // Tokens are stored in the Vault
        assertEq(
            usdc.balanceOf(address(vault)),
            USDC_AMOUNT - amountCalculated,
            "Vault: Wrong USDC balance"
        );
        assertEq(
            dai.balanceOf(address(vault)),
            DAI_AMOUNT + DAI_AMOUNT_IN,
            "Vault: Wrong DAI balance"
        );

        (, , uint256[] memory balances, ) = vault.getPoolTokenInfo(
            address(pool)
        );

        (uint256 daiIdx, uint256 usdcIdx) = getSortedIndexes(
            address(dai),
            address(usdc)
        );

        assertEq(
            balances[daiIdx],
            DAI_AMOUNT + DAI_AMOUNT_IN,
            "Pool: Wrong DAI balance"
        );
        assertEq(
            balances[usdcIdx],
            USDC_AMOUNT - amountCalculated,
            "Pool: Wrong USDC balance"
        );
    }

    /**
     * @dev Grants user (Alice) role enabling her to call `setStaticSwapFeePercentage()` on the vault, then user (Bob) carries out a `addLiquidityUnbalanced()` call on pool.
     * Question: This test could have further asserts added on, but it looks like monorepo doesn't have that. It would be testing for the fee to be correcetly adjusted no?
     */
    function testAddLiquidityUnbalanced() public {
        authorizer.grantRole(
            vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector),
            alice
        );
        vm.prank(alice);
        vault.setStaticSwapFeePercentage(address(pool), 10e16);

        uint256[] memory amountsIn = [uint256(1e2 * 1e18), uint256(USDC_AMOUNT)]
            .toMemoryArray();
        vm.prank(bob);

        router.addLiquidityUnbalanced(
            address(pool),
            amountsIn,
            0,
            false,
            bytes("")
        );
    }

    /// Helpers

    function createPool() internal override returns (address) {
        factory = new CustomPoolFactoryExample(
            IVault(address(vault)),
            365 days
        );
        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = IERC20(usdc);
        tokens[1].token = IERC20(dai);

        constantSumPool = ConstantSumPool(
            factory.create(
                "ERC20 Pool",
                "ERC20POOL",
                tokens,
                keccak256(abi.encode("TEST"))
            )
        );
        return address(constantSumPool);
    }

    function initPool() internal override {
        uint256[] memory amountsIn = [uint256(DAI_AMOUNT), uint256(USDC_AMOUNT)]
            .toMemoryArray();
        vm.prank(lp);
        bptAmountOut = router.initialize(
            pool,
            InputHelpers.sortTokens(
                [address(dai), address(usdc)].toMemoryArray().asIERC20()
            ),
            amountsIn, // 1000 of each
            // Account for the precision loss
            DAI_AMOUNT - DELTA - 1e6, // 1 - 1e9 -1e6
            false,
            bytes("")
        );
    }

    function less(
        uint256 amount,
        uint256 base
    ) internal pure returns (uint256) {
        return (amount * (base - 1)) / base;
    }
}
