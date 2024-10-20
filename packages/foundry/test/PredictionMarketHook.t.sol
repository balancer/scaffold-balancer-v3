// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    SwapKind,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { PredictionMarketHook } from "../contracts/prediction-market/PredictionMarketHook.sol";
import { 
    PredictionMarket,
    Position,
    Side 
} from "../contracts/prediction-market/Types.sol";



contract PredictionMarketHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    function setUp() public virtual override {
        BaseVaultTest.setUp();
    }

    // Sets the hook for the pool, and stores the address in `poolHooksContract`.
    function createHook() internal override returns (address) {
        PredictionMarketHook hook = new PredictionMarketHook(IVault(address(vault)), address(factoryMock));
        return address(hook);
    }

    // Overrides pool creation to set liquidityManagement (enables donation).
    function _createPool(address[] memory tokens, string memory label) internal override returns (address) {
        address predictionMarketPool = factoryMock.createPool("Prediction Market Pool", "PREDICTION-POOL");
        vm.label(predictionMarketPool, label);

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.enableDonation = true;

        vm.expectEmit();
        emit PredictionMarketHook.PredictionMarketHookRegistered(poolHooksContract, predictionMarketPool);

        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(weth), address(usdc)].toMemoryArray().asIERC20()
        );


        factoryMock.registerPool(
            predictionMarketPool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        return predictionMarketPool;
    }

    function testAddLiquidityToUnregisteredPool() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarketHook.PoolNotFound.selector);

        //passing any non registered address should revert. Using the vault address here
        PredictionMarketHook(poolHooksContract).addLiquidity(address(vault), address(usdc), address(weth), block.timestamp+60, 1e18, Side.Both);
    }

    function testAddLiquidityWithNonPoolTokens() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarketHook.InvalidTokenPair.selector);

        PredictionMarketHook(poolHooksContract).addLiquidity(pool, address(usdc), address(dai), block.timestamp+60, 1e18, Side.Both);
    }

    function testAddLiquidityWithSameToken() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarketHook.InvalidTokenPair.selector);

        PredictionMarketHook(poolHooksContract).addLiquidity(pool, address(usdc), address(usdc), block.timestamp+60, 1e18, Side.Both);
    }

    function testAddLiquidityWithCloseTimestampInPast() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarketHook.TimestampIsInPast.selector);

        PredictionMarketHook(poolHooksContract).addLiquidity(pool, address(usdc), address(dai), block.timestamp-60, 1e18, Side.Both);
    }

    function testSuccessfulAddLiquidity() public {
        vm.startPrank(alice);

        uint8 decimals = address(usdc) > address(weth) ? usdc.decimals() : weth.decimals();

        usdc.approve(poolHooksContract, type(uint256).max);
        weth.approve(poolHooksContract, type(uint256).max);

        PredictionMarketHook hook = PredictionMarketHook(poolHooksContract);

        uint256 amountIn = 1*(10**decimals);
        address tokenA = address(usdc);
        address tokenB = address(weth);
        uint256 endTimestamp = block.timestamp+60;
        bytes32 marketId = hook.getMarketId(pool, tokenA, tokenB, endTimestamp);
        
        Position memory position = hook.addLiquidity(pool, tokenA, tokenB, endTimestamp, amountIn, Side.Both);

        PredictionMarket memory market = hook.getMarketById(marketId);

        uint256 expectedFee = Math.mulDiv(amountIn, hook.FEE(), 1e6);

        vm.assertEq(pool, market.pool);
        vm.assertEq(marketId, market.id);
        vm.assertEq(position.bullAmount, amountIn/2);
        vm.assertEq(position.bearAmount, amountIn/2);
        vm.assertEq(amountIn, market.liquidity);
        vm.assertEq(1e18, market.openPrice);
        vm.assertEq(expectedFee, market.fees);
    }


}
