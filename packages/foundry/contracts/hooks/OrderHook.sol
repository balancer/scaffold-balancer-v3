// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IBasePoolFactory} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {LiquidityManagement, TokenConfig, HookFlags, AfterSwapParams} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {VaultGuard} from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import {BaseHooks} from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/// @title A Hook to trade coins in a balancer v3 pool
/// @author Atiq Ishrak
/// @notice This hook allows users to place orders in a pool and execute them based on the current price of the pool
contract OrderHook is BaseHooks, VaultGuard, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*/////////////////////////////
    ///////      ERRORS     ///////
    /////////////////////////////*/

    error OrderHook__UnauthorizedRouter();
    error OrderHook__OrderAmountInMustBeMoreThanZero();
    error OrderHook__InsufficientAllowance();
    error OrderHook__InsufficientBalance();
    error OrderHook__UnauthorizedCaller();
    error OrderHook__OrderAlreadyExecutedOrCancelled();
    error OrderHook__OrderUnableToExecute(
        bytes32 orderId,
        address user,
        uint256 currentTokenInPrice,
        uint256 triggerPrice,
        OrderType orderType
    );

    /*/////////////////////////////
    ///////      EVENTS     ///////
    /////////////////////////////*/

    event OrderPlaced(
        bytes32 indexed orderId,
        address indexed user,
        OrderType orderType,
        uint256 amountIn,
        uint256 triggerPrice,
        uint8 slippageTolerance
    );
    event OrderExecuted(bytes32 indexed orderId, address indexed user);
    event OrderCanceled(
        bytes32 indexed orderId,
        address indexed user,
        OrderType orderType
    );
    event OrdersProcessed(bytes32[] orderIds);
    event AfterSwapPrice(
        address indexed pool,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 currentTokenInPrice,
        uint256 currentTokenOutPrice
    );

    /*/////////////////////////////
    /////  ENUMS, STRUCTS    //////
    /////////////////////////////*/

    enum OrderType {
        STOP_LOSS,
        BUY_STOP,
        BUY_LIMIT,
        TAKE_PROFIT
    }

    enum OrderStatus {
        OPEN,
        EXECUTED,
        CANCELLED
    }

    struct Order {
        bytes32 orderId;
        address trader;
        OrderType orderType;
        OrderStatus orderStatus;
        uint256 amountIn;
        uint256 triggerPrice;
        address tokenIn;
        address tokenOut;
        address pool;
        uint8 slippageTolerance;
    }

    /*/////////////////////////////
    ///////    VARIABLES    ///////
    /////////////////////////////*/

    // only calls from a trusted routers are allowed to call this hook, because the hook relies on the getSender
    // implementation to work properly
    address private immutable i_trustedRouter;
    // only pools from the allowedFactory are able to register and use this hook
    address private immutable i_allowedFactory;
    IVault private immutable i_vault;
    IPermit2 private immutable i_permit2;

    uint256 public orderCount;
    mapping(bytes32 => Order) public orders;
    mapping(address => bytes32[]) public userOrders;
    // pool address => token address => price
    mapping(address => mapping(IERC20 => uint256)) public prevPrices;

    /// @notice Only the trader or the owner of the order is allowed
    modifier Onlytrader(address trader, address caller) {
        if (trader != caller) {
            revert OrderHook__UnauthorizedCaller();
        }
        _;
    }

    /// @notice Construct a new OrderHook
    /// @param vault The vault contract
    /// @param allowedFactory The factory that is allowed to use this hook
    /// @param trustedRouter The router that is allowed to call this hook
    /// @param permit2 Contract to approve tokens
    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        IPermit2 permit2
    ) VaultGuard(vault) {
        i_allowedFactory = allowedFactory;
        i_trustedRouter = trustedRouter;
        i_vault = vault;
        i_permit2 = permit2;
    }

    // Receive function to receive ether
    receive() external payable {}

    // Fallback function to receive ether
    fallback() external payable {}

    /// @notice Get the hook flags
    function getHookFlags()
        public
        pure
        override
        returns (HookFlags memory hookFlags)
    {
        hookFlags.shouldCallAfterSwap = true;
    }

    /// @notice Check if the pool is allowed to register with this hook
    /// @dev This hook implements a restrictive approach, where we check if the factory is an allowed factory and if the pool is created by the allowed factory
    /// @param factory The factory contract that is deploying the pool
    /// @param pool The pool that is being registered with this hook
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory /* tokenConfig */,
        LiquidityManagement calldata /* liquidityManagement */
    ) public view override onlyVault returns (bool) {
        // This hook implements a restrictive approach, where we check if the factory is an allowed factory and if
        // the pool was created by the allowed factory
        return
            factory == i_allowedFactory &&
            IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /*///////////////////////////////////
    ///////////    HOOK       ///////////
    ///////////////////////////////////*/

    /// @notice After swap hook
    /// @dev This hook is called after a swap is executed. We store the previous prices of the tokens in the pool
    /// @dev This emits an event with the current prices so that we can use that offchain to evalaute the positions of the current active orders
    /// @dev Only the vault and trusted router is allowed to call this hook
    /// @param params The parameters of the swap
    function onAfterSwap(
        AfterSwapParams calldata params
    )
        public
        override
        onlyVault
        returns (bool success, uint256 hookAdjustedAmountCalculatedRaw)
    {
        if (params.router != i_trustedRouter) {
            revert OrderHook__UnauthorizedRouter();
        }

        emit AfterSwapPrice(
            params.pool,
            address(params.tokenIn),
            address(params.tokenOut),
            params.tokenInBalanceScaled18,
            params.tokenOutBalanceScaled18
        );

        prevPrices[params.pool][params.tokenIn] = params.tokenInBalanceScaled18;
        prevPrices[params.pool][params.tokenOut] = params
            .tokenOutBalanceScaled18;

        return (true, params.amountCalculatedRaw);
    }

    /*///////////////////////////////////
    ///////    PLACE ORDER       ////////
    ///////////////////////////////////*/

    /// @notice Place an order in a pool
    /// @dev The order is placed by transferring the tokenIn to this contract
    /// @param orderType Type of the order
    /// @param amountIn Amount of tokenIn
    /// @param triggerPrice The Price at which the order should be executed
    /// @param pool Pool address
    /// @param tokenIn Address of the tokenIn
    /// @param tokenOut Address of the tokenOut
    /// @param slippageTolerance Slippage percentage allowed
    /// @return orderId The id of the order
    function placeOrder(
        OrderType orderType,
        uint256 amountIn,
        uint256 triggerPrice,
        address pool,
        address tokenIn,
        address tokenOut,
        uint8 slippageTolerance
    ) external returns (bytes32 orderId) {
        if (amountIn == 0) {
            revert OrderHook__OrderAmountInMustBeMoreThanZero();
        }

        i_vault.getPoolTokenCountAndIndexOfToken(pool, IERC20(tokenIn));
        i_vault.getPoolTokenCountAndIndexOfToken(pool, IERC20(tokenOut));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        orderId = keccak256(
            abi.encodePacked(msg.sender, orderCount, block.timestamp)
        );

        orders[orderId] = Order({
            orderId: orderId,
            trader: msg.sender,
            orderType: orderType,
            orderStatus: OrderStatus.OPEN,
            amountIn: amountIn,
            triggerPrice: triggerPrice,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            pool: pool,
            slippageTolerance: slippageTolerance
        });

        userOrders[msg.sender].push(orderId);
        orderCount++;

        emit OrderPlaced(
            orderId,
            msg.sender,
            orderType,
            amountIn,
            triggerPrice,
            slippageTolerance
        );
    }

    /*///////////////////////////////////
    ///////    CANCEL ORDER      ////////
    ///////////////////////////////////*/

    /// @notice Cancel an order
    /// @dev The order is cancelled and tokens are transferred back to the trader
    /// @param orderId The id of the order
    function cancelOrder(
        bytes32 orderId
    ) external nonReentrant Onlytrader(orders[orderId].trader, msg.sender) {
        if (orders[orderId].orderStatus != OrderStatus.OPEN) {
            revert OrderHook__OrderAlreadyExecutedOrCancelled();
        }

        orders[orderId].orderStatus = OrderStatus.CANCELLED;
        IERC20(orders[orderId].tokenIn).transfer(
            msg.sender,
            orders[orderId].amountIn
        );

        emit OrderCanceled(orderId, msg.sender, orders[orderId].orderType);
    }

    /*///////////////////////////////////
    ///////    EXECUTE ORDER     ////////
    ///////////////////////////////////*/

    /// @notice Execute an order
    /// @dev The order is executed only if the current price of the pool satisfies the order conditions
    /// @dev After execution the tokenOut is transferred to the trader
    /// @param orderId The id of the order to execute
    /// @param data The data to pass to the router
    function executeOrder(
        bytes32 orderId,
        bytes calldata data
    ) external nonReentrant Onlytrader(orders[orderId].trader, msg.sender) {
        Order storage order = orders[orderId];
        if (order.orderStatus != OrderStatus.OPEN) {
            revert OrderHook__OrderAlreadyExecutedOrCancelled();
        }

        uint256[] memory poolPrice = getPoolPrice(order.pool);

        (, uint256 inTokenIndex) = i_vault.getPoolTokenCountAndIndexOfToken(
            order.pool,
            IERC20(order.tokenIn)
        );
        (, uint256 outTokenIndex) = i_vault.getPoolTokenCountAndIndexOfToken(
            order.pool,
            IERC20(order.tokenOut)
        );

        if (_shouldExecuteOrder(order, poolPrice[inTokenIndex])) {
            uint256 limit = _calculateLimit(
                order.amountIn,
                poolPrice[inTokenIndex],
                poolPrice[outTokenIndex],
                order.slippageTolerance
            );

            _swap(order, limit, data);

            emit OrderExecuted(orderId, msg.sender);
        } else {
            revert OrderHook__OrderUnableToExecute(
                orderId,
                msg.sender,
                poolPrice[inTokenIndex],
                order.triggerPrice,
                order.orderType
            );
        }
    }

    /*///////////////////////////////////
    //////   INTERNAL FUNCTIONS    //////
    ///////////////////////////////////*/

    /// @notice Swaps tokens in a pool, called by executeOrder
    /// @dev The i_permit2 contract is used to approve tokens for the router on behalf of this contract
    /// @param order The order to execute
    /// @param limit Amount of minimum tokenOut to receive
    /// @param data The data to pass to the router
    function _swap(
        Order storage order,
        uint256 limit,
        bytes calldata data
    ) internal {
        IERC20(order.tokenIn).approve(address(i_permit2), order.amountIn);
        i_permit2.approve(
            order.tokenIn,
            address(i_trustedRouter),
            uint160(order.amountIn),
            type(uint48).max
        );

        uint256 amountOut = IRouter(payable(i_trustedRouter))
            .swapSingleTokenExactIn(
                order.pool,
                IERC20(order.tokenIn),
                IERC20(order.tokenOut),
                order.amountIn,
                limit,
                block.timestamp + 1 hours,
                false,
                data
            );

        IERC20(order.tokenIn).approve(address(i_permit2), 0);
        IERC20(order.tokenOut).safeTransfer(order.trader, amountOut);
        order.orderStatus = OrderStatus.EXECUTED;
    }

    /// @notice Checks if the order should be executed
    /// @dev If the order is a stop loss and the tokenIn price is less than or equal to the trigger price, the order should be executed
    /// @dev If the order is a buy stop and the tokenIn price is greater than or equal to the trigger price, the order should be executed
    /// @dev If the order is a buy limit and the tokenIn price is less than or equal to the trigger price, the order should be executed
    /// @dev If the order is a take profit and the tokenIn price is greater than or equal to the trigger price, the order should be executed
    /// @param order The order to check
    /// @param tokenInlPrice The price of the tokenIn in the pool where order is placed
    function _shouldExecuteOrder(
        Order storage order,
        uint256 tokenInlPrice
    ) internal view returns (bool) {
        if (
            order.orderType == OrderType.STOP_LOSS &&
            tokenInlPrice <= order.triggerPrice
        ) {
            return true;
        } else if (
            order.orderType == OrderType.BUY_STOP &&
            tokenInlPrice >= order.triggerPrice
        ) {
            return true;
        } else if (
            order.orderType == OrderType.BUY_LIMIT &&
            tokenInlPrice <= order.triggerPrice
        ) {
            return true;
        } else if (
            order.orderType == OrderType.TAKE_PROFIT &&
            tokenInlPrice >= order.triggerPrice
        ) {
            return true;
        }
        return false;
    }

    /// @notice Calculate the limit of the tokenOut for a swap
    /// @dev The limit is calculated based on the slippage tolerance
    /// @param amountIn Amount of tokenIn
    /// @param tokenInPrice Current price of tokenIn
    /// @param tokenOutPrice Current price of tokenOut
    /// @param slippageTolerance Slippage tolerance
    /// @return limit The minimum amount of tokenOut to receive
    function _calculateLimit(
        uint256 amountIn,
        uint256 tokenInPrice,
        uint256 tokenOutPrice,
        uint8 slippageTolerance
    ) internal pure returns (uint256 limit) {
        uint256 estimatedAmountOut = (amountIn * tokenOutPrice) / tokenInPrice;
        limit = ((estimatedAmountOut * (100 - slippageTolerance)) / 100);
    }

    /*////////////////////////////////////////////////
    ///////   PUBLIC, VIEW, GETTER FUNCTIONS   ///////
    ////////////////////////////////////////////////*/

    /// @notice Get the current prices of the tokens in a pool
    /// @param pool The pool address
    function getPoolPrice(
        address pool
    ) public view returns (uint256[] memory balancesLiveScaled18) {
        balancesLiveScaled18 = i_vault.getCurrentLiveBalances(pool);
    }

    /// @notice Get the tokens in a pool
    /// @param pool The pool address
    function getPoolTokens(
        address pool
    ) public view returns (IERC20[] memory tokens) {
        tokens = i_vault.getPoolTokens(pool);
    }

    /// @notice Get an order by id
    /// @param orderId The id of the order
    function getOrderById(bytes32 orderId) public view returns (Order memory) {
        return orders[orderId];
    }

    /// @notice Get all orders of a user
    /// @dev The userOrders mapping stores the order ids of a user
    /// @dev We use this mapping to get all the orders of a user
    /// @return userOrdersNew An array of orders of the user
    function getUserOrders()
        public
        view
        returns (Order[] memory userOrdersNew)
    {
        bytes32[] memory orderIds = userOrders[msg.sender];
        userOrdersNew = new Order[](orderIds.length);
        for (uint256 i = 0; i < userOrdersNew.length; i++) {
            userOrdersNew[i] = orders[orderIds[i]];
        }
    }
}
