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
    PoolRoleAccounts,
    SwapKind,
    TokenConfig,
    PoolSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { StableMath } from "@balancer-labs/v3-solidity-utils/contracts/math/StableMath.sol";

import { StablePoolFactory } from "../lib/balancer-v3-monorepo/pkg/pool-stable/contracts/StablePoolFactory.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";

import { ATokenMock } from "./mock/ATokenMock.sol";
import { FeeTokenMock } from "./mock/FeeTokenMock.sol";
import { LendingPoolMock } from "./mock/LendingPoolMock.sol";
import { DynamicFeeHook } from "../contracts/hooks/DynamicFeeHook.sol";
import { IDynamicFeeHook } from "../contracts/interfaces/IDynamicFeeHook.sol";
import { ILendingPoolV3 } from "../contracts/interfaces/ILendingPoolV3.sol";

contract DynamicFeeHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    StablePoolFactory internal stablePoolFactory;

    address internal dynamicFeeHook;
    IERC20 internal feeToken;
    IERC20 internal rewardToken;
    ILendingPoolV3 internal lendingPool;

    uint256 internal constant DEFAULT_AMP_FACTOR = 200;

    uint256 internal constant SWAP_FEE_PERCENTAGE = 5e15; // 0.5%

    uint256 internal constant MIN_FEE = 10e15; // 0.1%
    uint256 internal constant MAX_FEE = 10e16; // 1.0%
    uint256 internal constant VOLATILITY_SENSITIVITY = 10e14; // 0.01%
    uint256 internal constant LIQUIDITY_SENSITIVITY = 5e13; // 0.005%
    uint256 internal constant MIN_LOCK_DURATION = 4 weeks;

    function setUp() public override {
        super.setUp();

        // Deploy fee, reward tokens and lending pool
        feeToken = new FeeTokenMock();
        rewardToken = new ATokenMock();
        lendingPool = new LendingPoolMock(address(feeToken), address(rewardToken));
    }

    function createHook() internal override returns (address) {
        // Create the factory here, because it needs to be deployed after the Vault, but before the hook contract.
        stablePoolFactory = new StablePoolFactory(IVault(address(vault)), 365 days, "Factory v1", "Pool v1");
        // lp will be the owner of the hook.
        vm.prank(admin);
        dynamicFeeHook = address(
            new DynamicFeeHook(
                IVault(address(vault)),
                address(stablePoolFactory),
                MIN_FEE,
                MAX_FEE,
                VOLATILITY_SENSITIVITY,
                LIQUIDITY_SENSITIVITY,
                MIN_LOCK_DURATION,
                address(lendingPool)
            )
        );
        vm.label(dynamicFeeHook, "Dynamic Fee Hook");
        return dynamicFeeHook;
    }

    function _createPool(address[] memory tokens, string memory label) internal override returns (address) {
        PoolRoleAccounts memory roleAccounts;

        vm.expectEmit(true, true, false, false);
        emit IDynamicFeeHook.DynamicFeeHookRegistered(dynamicFeeHook, address(stablePoolFactory), address(0));

        address newPool = address(
            stablePoolFactory.create(
                "Stable Pool Test",
                "STABLE-TEST",
                vault.buildTokenConfig(tokens.asIERC20()),
                DEFAULT_AMP_FACTOR,
                roleAccounts,
                BASE_MIN_SWAP_FEE,
                poolHooksContract,
                false, // Does not allow donations
                false, // Do not disable unbalanced add/remove liquidity
                ZERO_BYTES32
            )
        );
        vm.label(newPool, label);

        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), admin);
        vm.prank(admin);
        vault.setStaticSwapFeePercentage(newPool, SWAP_FEE_PERCENTAGE);

        return newPool;
    }

    function testRegistryWithWrongFactory() public {
        address dynamicFeePool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        // Registration fails because this factory is not allowed to register the hook.
        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                dynamicFeePool,
                address(factoryMock)
            )
        );
        _registerPoolWithHook(dynamicFeePool, tokenConfig);
    }

    function testSuccessfulRegistry() public view {
        HooksConfig memory hooksConfig = vault.getHooksConfig(pool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "hooksContract is wrong");
        assertTrue(hooksConfig.shouldCallComputeDynamicSwapFee, "shouldCallComputeDynamicSwapFee is false");
        assertTrue(hooksConfig.shouldCallAfterAddLiquidity, "shouldCallAfterAddLiquidity is false");
        assertTrue(hooksConfig.shouldCallAfterRemoveLiquidity, "shouldCallAfterRemoveLiquidity is false");
        assertTrue(hooksConfig.shouldCallAfterSwap, "shouldCallAfterSwap is false");
        assertTrue(hooksConfig.shouldCallBeforeSwap, "shouldCallBeforeSwap is false");
    }

    function testInvestingFlow() public view {}

    // Registration tests require a new pool, because an existing pool may already be registered.
    function _createPoolToRegister() private returns (address newPool) {
        //newPool = address(deployPoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL"));
        // newPool = new PoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL").address();
        newPool = address(new PoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL"));
        vm.label(newPool, "Directional Fee Pool");
    }

    function _registerPoolWithHook(address dynamicFeePool, TokenConfig[] memory tokenConfig) private {
        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;

        factoryMock.registerPool(dynamicFeePool, tokenConfig, roleAccounts, poolHooksContract, liquidityManagement);
    }
}
