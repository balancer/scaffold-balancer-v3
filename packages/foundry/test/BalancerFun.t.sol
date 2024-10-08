// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";

import { BalancerFun } from "../contracts/hooks/BalancerFun.sol";

/**
 * @title BalancerFunTest
 * @notice Unit tests for the BalancerFun contract.
 * @dev Inherits from BaseVaultTest to perform setup and test BalancerFun interactions.
 */
contract BalancerFunTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint;

    uint internal daiIdx;
    uint internal usdcIdx;

    /**
     * @notice Sets up the test environment.
     * @dev Overrides BaseVaultTest's setUp function to initialize token indexes.
     */
    function setUp() public virtual override {
        BaseVaultTest.setUp();
        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    /**
     * @notice Creates a new BalancerFun hook for testing.
     * @dev Deploys a new instance of BalancerFun and sets it as the hook for the pool.
     * @return address The address of the newly created hook.
     */
    function createHook() internal override returns (address) {
        // lp will be the owner of the hook. Only the owner can set hook fee percentages.
        vm.prank(lp);
        BalancerFun hook = new BalancerFun(IVault(address(vault)), IERC20(address(router)));
        return address(hook);
    }

    /**
     * @notice Creates a new pool with custom liquidity management settings.
     * @dev Overrides the pool creation to disable unbalanced liquidity by setting liquidityManagement.
     * @param tokens The tokens to be used in the pool.
     * @param label A label for the pool.
     * @return address The address of the newly created pool.
     */
    function _createPool(address[] memory tokens, string memory label) internal override returns (address) {
        PoolMock newPool = new PoolMock(IVault(address(vault)), "Balancer.Fun Pool", "BALFUN");
        vm.label(address(newPool), label);
        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;
        LiquidityManagement memory liquidityManagement;
        factoryMock.registerPool(
            address(newPool),
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        return address(newPool);
    }

    /**
     * @notice Tests the setup of the contract.
     * @dev Verifies that the setup has been completed successfully.
     */
    function testSetUp() public {
        assertEq(daiIdx, 0, "SetUp has failed");
    }
    
    /**
     * @notice Tests a swap operation.
     * @dev Executes a swap and verifies the balance changes for Alice.
     */
    function testSwap() public {
        (
            BaseVaultTest.Balances memory balancesBefore,
            BaseVaultTest.Balances memory balancesAfter,
            uint swapAmount,
            uint[] memory accruedFees,
            uint iterations
        ) = _executeSwap(1 ether);

        assertEq(
            balancesBefore.aliceTokens[daiIdx] - balancesAfter.aliceTokens[daiIdx],
            swapAmount,
            "Alice DAI balance is wrong"
        );
    }

    /**
     * @notice Executes a swap operation.
     * @dev Performs a swap of the specified amount and returns relevant data.
     * @param _swapAmount The amount to be swapped.
     * @return balancesBefore The balances before the swap.
     * @return balancesAfter The balances after the swap.
     * @return swapAmount The amount that was swapped.
     * @return accruedFees The accrued fees during the swap.
     * @return iterations The number of iterations performed.
     */
    function _executeSwap(uint _swapAmount) private returns (
            BaseVaultTest.Balances memory balancesBefore,
            BaseVaultTest.Balances memory balancesAfter,
            uint swapAmount,
            uint[] memory accruedFees,
            uint iterations
        )
    {
        vm.prank(lp);
        balancesBefore = getBalances(alice);
        bytes4 routerMethod;
        routerMethod = IRouter.swapSingleTokenExactIn.selector;
        uint amountGiven = _swapAmount;
        
        vm.prank(alice);
        (bool success, ) = address(router).call(
            abi.encodeWithSelector(
                routerMethod,
                address(pool),
                dai,
                usdc,
                amountGiven,
                amountGiven,
                MAX_UINT256,
                false,
                bytes("")
            )
        );

        assertTrue(success, "Swap has failed");
        balancesAfter = getBalances(alice);
        swapAmount = _swapAmount;
    }
}
