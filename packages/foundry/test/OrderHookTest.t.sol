// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {HooksConfig, LiquidityManagement, PoolConfig, PoolRoleAccounts, TokenConfig} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVaultErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IVaultErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BaseVaultTest} from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolMock} from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import {PoolFactoryMock} from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import {RouterMock} from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";

import {OrderHook} from ".././contracts/hooks/OrderHook.sol";

contract OrderHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address payable internal trustedRouter;

    uint8 slippageTolerance = 3;
    uint256 orderAmountIn = 1e20;
    uint256 mockTriggerPrice = 1e20 + 1e19;
    address badToken = makeAddr("badToken");
    address dummyUser = makeAddr("dummyUser");
    uint256 swapAmount = 1e19;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
    }

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);
        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address orderHook = address(
            new OrderHook(
                IVault(address(vault)),
                address(factoryMock),
                trustedRouter,
                permit2
            )
        );
        vm.label(orderHook, "Order Hook");
        return orderHook;
    }

    function testRegistryWithWrongFactory() public {
        address orderPool = _createPoolToRegister();

        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        uint32 pauseWindowEndTime = IVaultAdmin(address(vault))
            .getPauseWindowEndTime();
        uint32 bufferPeriodDuration = IVaultAdmin(address(vault))
            .getBufferPeriodDuration();
        uint32 pauseWindowDuration = pauseWindowEndTime - bufferPeriodDuration;
        address unauthorizedFactory = address(
            new PoolFactoryMock(IVault(address(vault)), pauseWindowDuration)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                orderPool,
                unauthorizedFactory
            )
        );

        _registerPoolWithHook(orderPool, tokenConfig, unauthorizedFactory);
    }

    function testCreationWithWrongFactory() public {
        address orderPool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.HookRegistrationFailed.selector,
                poolHooksContract,
                orderPool,
                address(factoryMock)
            )
        );
        _registerPoolWithHook(orderPool, tokenConfig, address(factoryMock));
    }

    function testSuccessfulRegistry() public {
        // Registering with allowed factory
        address orderPool = factoryMock.createPool("Test Pool", "TEST");
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(orderPool, tokenConfig, address(factoryMock));

        HooksConfig memory hooksConfig = vault.getHooksConfig(orderPool);

        assertEq(
            hooksConfig.hooksContract,
            poolHooksContract,
            "Wrong poolHooksContract"
        );
        assertEq(
            hooksConfig.shouldCallAfterSwap,
            true,
            "shouldCallComputeDynamicSwapFee is false"
        );
    }

    function testGetVaultPrice() public view {
        uint256[] memory balancesLiveScaled18 = OrderHook(
            payable(poolHooksContract)
        ).getPoolPrice(pool);

        (
            IERC20[] memory poolTokens,
            ,
            ,
            uint256[] memory lastBalancesLiveScaled18
        ) = vault.getPoolTokenInfo(pool);

        for (uint256 i = 0; i < poolTokens.length; i++) {
            assertEq(lastBalancesLiveScaled18[i], balancesLiveScaled18[i]);
        }
    }

    /*///////////////////////////////// 
    /////     PLACE ORDER TESTS   /////
    ////////////////////////////////*/

    function testPlaceOrderRevertsForZeroFund() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OrderHook.OrderHook__OrderAmountInMustBeMoreThanZero.selector
            )
        );
        OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            0,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );
    }

    function testRevertsIfTokenNotInPool() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IVaultErrors.TokenNotRegistered.selector,
                IERC20(badToken)
            )
        );
        OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            badToken,
            slippageTolerance
        );
    }

    function testRevertsIfNotEnoughAllowance() public {
        uint256 currentAllowance = tokens[0].allowance(
            users[2],
            poolHooksContract
        );
        vm.prank(users[2]);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                poolHooksContract,
                currentAllowance,
                orderAmountIn
            )
        );
        OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );
    }

    function testRevertsIfNotEnoughBalance() public {
        uint256 fromBalance = tokens[0].balanceOf(dummyUser);
        vm.prank(dummyUser);
        tokens[0].approve(poolHooksContract, orderAmountIn);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                dummyUser,
                fromBalance,
                orderAmountIn
            )
        );
        vm.prank(dummyUser);
        OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );
    }

    function testOrderPlacedSuccessfully() public {
        uint256 initialUserBalance = tokens[0].balanceOf(users[2]);
        uint256 orderCountBefore = OrderHook(payable(poolHooksContract))
            .orderCount();

        vm.prank(users[2]);
        tokens[0].approve(poolHooksContract, orderAmountIn);

        vm.prank(users[2]);
        bytes32 orderId = OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );

        assertEq(
            tokens[0].balanceOf(poolHooksContract),
            orderAmountIn,
            "Incorrect balance of token0"
        );

        assertEq(
            tokens[0].balanceOf(users[2]) + orderAmountIn,
            initialUserBalance
        );

        OrderHook.Order memory order = OrderHook(payable(poolHooksContract))
            .getOrderById(orderId);

        vm.prank(users[2]);
        OrderHook.Order[] memory userOrders = OrderHook(
            payable(poolHooksContract)
        ).getUserOrders();

        assertEq(abi.encode(order.orderId), abi.encode(userOrders[0].orderId));
        assertEq(order.orderId, userOrders[0].orderId);

        assertEq(
            orderCountBefore + 1,
            OrderHook(payable(poolHooksContract)).orderCount()
        );
    }

    /*///////////////////////////////// 
    /////   CANCEL ORDER TESTS   /////
    ////////////////////////////////*/

    function testRevertsIfNotOwner() public {
        vm.prank(users[2]);
        tokens[0].approve(poolHooksContract, orderAmountIn);

        vm.prank(users[2]);
        bytes32 orderId = OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                OrderHook.OrderHook__UnauthorizedCaller.selector
            )
        );
        OrderHook(payable(poolHooksContract)).cancelOrder(orderId);
    }

    function testRevertsIfOrderNotExists() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OrderHook.OrderHook__UnauthorizedCaller.selector
            )
        );
        bytes32 fakeOrderId = keccak256(
            abi.encodePacked(users[2], block.timestamp)
        );
        OrderHook(payable(poolHooksContract)).cancelOrder(fakeOrderId);
    }

    function testCancelOrderSuccessfully() public {
        uint256 initialBalance = tokens[0].balanceOf(users[2]);

        vm.startPrank(users[2]);
        tokens[0].approve(poolHooksContract, orderAmountIn);

        bytes32 orderId = OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            mockTriggerPrice,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );

        assertEq(initialBalance - orderAmountIn, tokens[0].balanceOf(users[2]));

        OrderHook(payable(poolHooksContract)).cancelOrder(orderId);
        vm.stopPrank();

        assertEq(initialBalance, tokens[0].balanceOf(users[2]));
    }

    /*///////////////////////////////// 
    /////  AFTER SWAP HOOk TESTS  /////
    ////////////////////////////////*/

    function testRevertsIfRouterNotTrusted() public {
        address payable untrustedRouter = payable(
            new RouterMock(IVault(address(vault)), weth, permit2)
        );

        vm.prank(users[2]);
        vm.expectRevert(
            abi.encodeWithSelector(
                OrderHook.OrderHook__UnauthorizedRouter.selector
            )
        );
        RouterMock(untrustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            swapAmount,
            block.timestamp + 1 hours,
            false,
            bytes("")
        );
    }

    function testHookEmitsEventsAfterSwap() public {
        _doOrder();

        vm.recordLogs();
        vm.prank(users[2]);
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            swapAmount,
            block.timestamp + 1 hours,
            false,
            bytes("")
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 eventSig = keccak256(
            "AfterSwapPrice(address,address,uint256,uint256,uint256,uint256)"
        );

        // Iterate over the logs to find and decode the AfterSwapPrice event
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];

            // Check if the event matches the signature
            if (log.topics[0] == eventSig) {
                // Decode event parameters
                address tokenIn = address(uint160(uint256(log.topics[1])));
                address tokenOut = address(uint160(uint256(log.topics[2])));

                // Assert that the emitted values match your expectations
                assertEq(tokenIn, address(dai));
                assertEq(tokenOut, address(usdc), "Unexpected tokenOut");
            }
        }
    }

    /*///////////////////////////////// 
    /////   EXECUTE ORDER TESTS   /////
    ////////////////////////////////*/

    function testRevertsIfOrderNotExistsForExecution() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                OrderHook.OrderHook__UnauthorizedCaller.selector
            )
        );
        bytes32 fakeOrderId = keccak256(
            abi.encodePacked(users[2], block.timestamp)
        );
        OrderHook(payable(poolHooksContract)).executeOrder(fakeOrderId, "");
    }

    function testEmitsEventOnceExecuted() public {
        bytes32[] memory orderIds = _doOrder();

        uint256 initialBalance = tokens[1].balanceOf(users[2]);
        console.log("Initial user balance: ", initialBalance);
        console.log(
            "Initial hook balance: ",
            tokens[0].balanceOf(poolHooksContract)
        );

        vm.expectEmit();
        emit OrderHook.OrderExecuted(orderIds[0], users[2]);
        vm.prank(users[2]);
        OrderHook(payable(poolHooksContract)).executeOrder(orderIds[0], "");

        console.log(
            "New hook balance: ",
            tokens[0].balanceOf(poolHooksContract)
        );
        console.log("New user balance: ", tokens[1].balanceOf(users[2]));

        assertEq(0, tokens[0].balanceOf(poolHooksContract));
        assert(initialBalance < tokens[1].balanceOf(users[2]));
    }

    /*/////////////////////////////////////
    ///////   FUNCTIONALITY TESTS   ///////
    /////////////////////////////////////*/
    function testUserCanSwap() public {
        uint256 initialBalance1 = tokens[0].balanceOf(users[2]);
        uint256 initialBalance2 = tokens[1].balanceOf(users[2]);
        vm.startPrank(users[2]);

        uint256 amountOut = RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            swapAmount,
            block.timestamp + 1 hours,
            false,
            bytes("")
        );

        vm.stopPrank();
        assertEq(initialBalance1 - swapAmount, tokens[0].balanceOf(users[2]));
        assertEq(initialBalance2 + amountOut, tokens[1].balanceOf(users[2]));
    }

    function testPoolHookCanSwap() public {
        vm.prank(users[2]);
        tokens[0].transfer(poolHooksContract, swapAmount);

        assertEq(swapAmount, tokens[0].balanceOf(poolHooksContract));
        console.log(
            "hook balance 1 before: ",
            tokens[0].balanceOf(poolHooksContract)
        );
        console.log(
            "hook balance 2 before: ",
            tokens[1].balanceOf(poolHooksContract)
        );

        vm.startPrank(poolHooksContract);
        tokens[0].approve(address(permit2), swapAmount);
        permit2.approve(
            address(tokens[0]),
            address(router),
            uint160(swapAmount),
            type(uint48).max
        );
        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            swapAmount,
            block.timestamp + 1 hours,
            false,
            bytes("")
        );

        vm.stopPrank();

        console.log(
            "hook balance 1 after: ",
            tokens[0].balanceOf(poolHooksContract)
        );
        console.log(
            "hook balance 2 after: ",
            tokens[1].balanceOf(poolHooksContract)
        );

        assertEq(swapAmount, tokens[1].balanceOf(poolHooksContract));
    }

    /*/////////////////////////////////////
    ///////     INTERNAL FUNCTIONS  ///////
    /////////////////////////////////////*/

    function _doOrder() private returns (bytes32[] memory) {
        bytes32[] memory orderIds = new bytes32[](2);
        // Order 1 TAKE_PROFIT
        vm.startPrank(users[2]);
        tokens[0].approve(poolHooksContract, orderAmountIn);
        tokens[1].approve(poolHooksContract, orderAmountIn);

        uint256[] memory balancesLiveScaled18 = OrderHook(
            payable(poolHooksContract)
        ).getPoolPrice(pool);

        orderIds[0] = OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.TAKE_PROFIT,
            orderAmountIn,
            balancesLiveScaled18[0] + 1e19,
            pool,
            address(tokens[0]),
            address(tokens[1]),
            slippageTolerance
        );

        RouterMock(trustedRouter).swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            swapAmount,
            block.timestamp + 1 hours,
            false,
            bytes("")
        );

        // Order 2 STOP_LOSS
        orderIds[1] = OrderHook(payable(poolHooksContract)).placeOrder(
            OrderHook.OrderType.STOP_LOSS,
            orderAmountIn,
            balancesLiveScaled18[1] - 1e19,
            pool,
            address(tokens[1]),
            address(tokens[0]),
            slippageTolerance
        );
        vm.stopPrank();

        return orderIds;
    }

    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(
            new PoolMock(IVault(address(vault)), "Order pool", "orderPool")
        );
        vm.label(newPool, "Order pool");
    }

    function _registerPoolWithHook(
        address orderPool,
        TokenConfig[] memory tokenConfig,
        address factory
    ) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(factory).registerPool(
            orderPool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
