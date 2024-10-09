// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {
    HooksConfig,
    LiquidityManagement,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";

import { SwapDiscountHook } from "packages/foundry/contracts/hooks/SwapDiscountHook.sol";
import { console } from "forge-std/console.sol";

contract SwapDiscountHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    uint64 public constant MAX_SWAP_DISCOUNT_PERCENTAGE = 50e16; // 50%
    uint256 public constant REQUIRED_BALANCE = 100e18; // Minimum required balance for discount (100 BAL)

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        // Mint 100 BAL tokens for the test account (Bob)
        deal(address(dai), bob, REQUIRED_BALANCE);
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);

        // LP will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address swapDiscountHook = address(
            new SwapDiscountHook(
                IVault(address(vault)),
                address(factoryMock),
                trustedRouter,
                address(dai),
                MAX_SWAP_DISCOUNT_PERCENTAGE,
                REQUIRED_BALANCE
            )
        );
        vm.label(swapDiscountHook, "Swap Discount Hook");
        return swapDiscountHook;
    }

    function testSuccessfulRegistrySwap() public {
        // Registering with allowed factory
        address swapDHookPool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(swapDHookPool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(swapDHookPool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallAfterSwap, true, "shouldCallAfterSwap is false");
    }

    function testSwapDiscountWithSufficientBalance() public {
        // Bob has enough DAI for the discount
        vm.prank(bob);
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            usdc,
            dai,
            REQUIRED_BALANCE,
            REQUIRED_BALANCE,
            MAX_UINT256,
            false,
            bytes("")
        );

        // Check Bob's DAI balance after the swap
        uint256 expectedDAIAmount = REQUIRED_BALANCE.mulDown(1 - MAX_SWAP_DISCOUNT_PERCENTAGE);
        assertEq(dai.balanceOf(bob), expectedDAIAmount, "Bob's DAI balance is incorrect after discount");
    }

    function testSwapDiscountWithInsufficientBalance() public {
        // Adjust Bob's DAI balance to be less than the required balance for discount
        vm.prank(bob);
        deal(address(dai), bob, REQUIRED_BALANCE / 2); // Only 50 DAI

        vm.prank(bob);
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            usdc,
            dai,
            REQUIRED_BALANCE,
            REQUIRED_BALANCE,
            MAX_UINT256,
            false,
            bytes("")
        );

        // Check Bob's DAI balance after the swap
        assertEq(
            dai.balanceOf(bob),
            REQUIRED_BALANCE,
            "Bob's DAI balance should be unchanged due to insufficient balance"
        );
    }

    // Registry tests require a new pool, because an existing pool may already be registered
    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(new PoolMock(IVault(address(vault)), "SwapD Hook Pool", "swapDHookPool"));
        vm.label(newPool, "SwapD Hook Pool");
    }

    function _registerPoolWithHook(address swapDhookPool, TokenConfig[] memory tokenConfig, address factory) private {
        LiquidityManagement memory liquidityManagement;
        PoolFactoryMock(factory).registerPool(
            swapDhookPool,
            tokenConfig,
            PoolRoleAccounts({ lp: lp, guardian: address(0), rewards: address(0) }),
            poolHooksContract,
            liquidityManagement
        );
    }
}
