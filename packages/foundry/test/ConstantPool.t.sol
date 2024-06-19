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
 * @title Constant Sum Pool Test Example
 * @author BUIDL GUIDL
 * @notice This test file serves as an example of some areas one needs to focus on when writing their own custom BalancerV3 pool. This is not production ready, and it is the developers responsibility to carry out proper testing and auditing for their pool.
 * These tests roughly mirror the typical testing cases that are found in the BalancerV3 monorepo for weighted pool tests.  As a reference tool, it only makes sense to have tests that, at the very least, roughly mirror how weighted pools are tested within BalancerV3 monorepo.
 * @dev This test is written for the Constant Sum Custom Pool. Developers may duplicate this as a starting template for their own custom pool test file.
 * When creating your own custom pool, developers are expected to: create their own custom pool file, test file, script file. They simply can just duplicate or override the files that are here marked as "example" within their title.
 */
contract ConstantSumPoolTest is BaseVaultTest {
    using ArrayHelpers for *;

    CustomPoolFactoryExample factory;
    ConstantSumPool internal constantSumPool;

    uint256 constant USDC_AMOUNT = 1e3 * 1e18;
    uint256 constant DAI_AMOUNT = 1e3 * 1e18;

    uint256 constant DAI_AMOUNT_IN = 1 * 1e18;
    uint256 constant USDC_AMOUNT_OUT = 1 * 1e18;

    uint256 constant DELTA = 1e9;

    uint256 internal bptAmountOut;

    function setUp() public virtual override {
        BaseVaultTest.setUp();
    }

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

    // TODO - see question in issue #28
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
        (, , uint256[] memory balances, , ) = vault.getPoolTokenInfo(
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
        );
    }

    // @dev TODO - see questions in issue #28
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
        (, , uint256[] memory balances, , ) = vault.getPoolTokenInfo(
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
        );
    }

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
        (, , uint256[] memory balances, , ) = vault.getPoolTokenInfo(
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

        (, , uint256[] memory balances, , ) = vault.getPoolTokenInfo(
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
