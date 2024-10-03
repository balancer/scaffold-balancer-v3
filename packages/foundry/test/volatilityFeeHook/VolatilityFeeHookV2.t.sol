// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { Script, console } from "forge-std/Script.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import { VolatilityFeeHookV2 } from "../../contracts/hooks/volatilityFee/VolatilityFeeHookV2.sol";
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
import { console } from "forge-std/Script.sol";

contract VolatilityFeeHookV2Test is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        // console.log("Vault:", vault);
        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        // mockAuthorizer Implementation --> grantRole(bytes32 role, account)
        // Authentication.sol implemetns --> getActionId(bytes4 selector) returns (bytes32 role)
        // IVaultAdmin -->     function setStaticSwapFeePercentage(address pool, uint256 swapFeePercentage) external;
        // .selector is inbuilt solidity function
        // Function signature
        // string memory signature = "setStaticSwapFeePercentage(address,uint256)";
        // // Hash the signature using Keccak-256
        // bytes32 hash = keccak256(abi.encodePacked(signature))
        // // Extract the first 4 bytes
        // bytes4 selector = bytes4(hash);
        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), lp);
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);

        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address volatilityFeeHookV2 = address(
            new VolatilityFeeHookV2(IVault(address(vault)), address(factoryMock), trustedRouter)
        );
        vm.label(volatilityFeeHookV2, "Volatility Fee Hook V2");
        return volatilityFeeHookV2;
    }

    function testCreationWithWrongFactory() public {
        address volatilityFeePool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                volatilityFeePool,
                address(factoryMock)
            )
        );
        _registerPoolWithHook(volatilityFeePool, tokenConfig, address(factoryMock));
    }

    function testSuccessfulRegistry() public {
        // Registering with allowed factory
        address volatiltiyFeePool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(volatiltiyFeePool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(volatiltiyFeePool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "Wrong poolHooksContract");
        assertEq(hooksConfig.shouldCallComputeDynamicSwapFee, true, "shouldCallComputeDynamicSwapFee is false");
    }


    // Test Swaping 100 DAI to the DAI/USDC Pool
    function testSwap1() public {
        // poolInitAmount = 1000e18
        uint256 exactAmountIn = poolInitAmount/10;

        uint256 swapFeePercentage = 1e17;

        BaseVaultTest.Balances memory balancesBefore = getBalances(address(bob));
        uint256 balanceIn = balancesBefore.poolTokens[daiIdx];
        uint256 balanceOut = balancesBefore.poolTokens[usdcIdx];
        
        vm.prank(lp);
        
        vault.setStaticSwapFeePercentage(pool, swapFeePercentage);

        uint256 roughAmountOut = exactAmountIn * balanceOut / (balanceIn + exactAmountIn);

        uint256 calculatedDynamicSwapFeePercentage = _calculateSwapFee(roughAmountOut, balanceOut, swapFeePercentage);


        uint256 expectedHookFee = exactAmountIn.mulDown(calculatedDynamicSwapFeePercentage);

        // PoolMock uses a linear math with rate 1, so amountIn = amountOut if no fees are applied
        uint256 expectedAmountOut = exactAmountIn - expectedHookFee;
        _swapAndCheckBalances(exactAmountIn, expectedAmountOut);
    }

    // Test Swaping 200 DAI to the DAI/USDC Pool
    function testSwap2() public {
        // poolInitAmount = 1000e18
        uint256 exactAmountIn = poolInitAmount/5;

        uint256 swapFeePercentage = 1e17;

        BaseVaultTest.Balances memory balancesBefore = getBalances(address(bob));
        uint256 balanceIn = balancesBefore.poolTokens[daiIdx];
        uint256 balanceOut = balancesBefore.poolTokens[usdcIdx];
        
        vm.prank(lp);
        
        vault.setStaticSwapFeePercentage(pool, swapFeePercentage);

        uint256 roughAmountOut = exactAmountIn * balanceOut / (balanceIn + exactAmountIn);

        uint256 calculatedDynamicSwapFeePercentage = _calculateSwapFee(roughAmountOut, balanceOut, swapFeePercentage);


        uint256 expectedHookFee = exactAmountIn.mulDown(calculatedDynamicSwapFeePercentage);

        // PoolMock uses a linear math with rate 1, so amountIn = amountOut if no fees are applied
        uint256 expectedAmountOut = exactAmountIn - expectedHookFee;
        _swapAndCheckBalances(exactAmountIn, expectedAmountOut);
    }
    


    // DAI in --- USDC out
    function _swapAndCheckBalances(uint256 exactAmountIn, uint256 expectedAmountOut) private{
        BaseVaultTest.Balances memory balancesBefore = getBalances(address(bob));

        vm.prank(bob);
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            exactAmountIn,
            expectedAmountOut,
            MAX_UINT256,
            false,
            bytes("")
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(address(bob));


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
        // Vault;s balance of USDC is supposed to decrease, since USDC was taken out
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

    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(new PoolMock(IVault(address(vault)), "Volatility Fee Pool", "volatilityFeePool"));
        vm.label(newPool, "Volatility Fee Pool");
    }

    function _registerPoolWithHook(
        address volatilityFeePool,
        TokenConfig[] memory tokenConfig,
        address factory
    ) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(factory).registerPool(
            volatilityFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

    function _calculateSwapFee(uint256 amount, uint256 balance, uint256 staticSwapFeePercentage) internal pure returns (uint256){
        // Ensure we don't divide by zero
        if (balance == 0) {
            return staticSwapFeePercentage * 100; // Max fee if no balance exists
        }

        // Calculate utilization ratio as amount / balance, scaled to 1e18 for precision
        uint256 utilizationRatio = (amount * 1e18) / balance;

        // We use a quadratic curve for the fee multiplier: utilizationRatio^2
        // This increases the fee more steeply as utilization approaches 100%
        uint256 quadraticMultiplier = (utilizationRatio * utilizationRatio) / 1e18; 

        // Scale the multiplier into the desired range: 1x base fee at low utilization, higher at high utilization
        // For example, multiplying by 99 ensures that at max utilization the fee multiplier reaches 100x
        uint256 feeMultiplier = 1 + (quadraticMultiplier * 99 / 1e18);

        // Return the final fee, multiplying the base fee by the calculated multiplier
        return staticSwapFeePercentage * feeMultiplier;
    }
}
