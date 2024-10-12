// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/twamm/TWAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

event TWAMMOrderExecuted(uint256 amountIn, uint256 amountOut, uint256 timestamp);

contract TWAMMTest is Test {
    TWAMM private twamm;
    IVault private vault;
    IERC20 private tokenA;
    IERC20 private tokenB;
    address private user;

    function setUp() public {
        vault = IVault(address(new MockVault()));
        tokenA = IERC20(address(new MockERC20("TokenA", "TKA", 18)));
        tokenB = IERC20(address(new MockERC20("TokenB", "TKB", 18)));
        user = address(this);

        twamm = new TWAMM(
            vault,
            address(tokenA),
            address(tokenB),
            tokenA,
            tokenB,
            1 ether,
            1 ether,
            block.timestamp,
            block.timestamp + 1 weeks,
            1 hours
        );
        // Approve the TWAMM contract to spend user's tokens
        vm.prank(user);

        tokenA.approve(address(twamm), type(uint256).max);
        tokenB.approve(address(twamm), type(uint256).max);
    }

    function testCreateOrder() public {
        uint256 amount = 0.5 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders.length, 1);
        assertEq(orders[0].amount, amount);
        assertEq(orders[0].isBuy, isBuy);
    }


    function testCancelOrder() public {
        uint256 amount = 0.5 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);
        twamm.cancelOrder(0);

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders.length, 0);
    }

    function testFail_ExecuteTWAMMOrder() public {
        // Set up the TWAMM order
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1 days;
        uint256 interval = 1 hours;
        uint256 totalAmountIn = 1 ether;
        uint256 totalAmountOut = 0.8 ether;

        // Fast forward time to just after the start time
        vm.warp(startTime + interval);

        // Execute the TWAMM order
        twamm.executeTWAMMOrder();

        // Check the results
        uint256 expectedAmountIn = (totalAmountIn * 1 hours) / (endTime - startTime);
        uint256 expectedAmountOut = (totalAmountOut * 1 hours) / (endTime - startTime);

        assertEq(tokenA.balanceOf(address(vault)), expectedAmountIn, "Incorrect amountIn transferred");
        assertEq(twamm.lastExecutionTime(), block.timestamp, "Incorrect lastExecutionTime");

        // Check emitted event
        vm.expectEmit(true, true, true, true);
        emit TWAMMOrderExecuted(expectedAmountIn, expectedAmountOut, block.timestamp);
    }

    function testFail_ExecuteOrders() public {
        uint256 amount = 0.5 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);
        vm.warp(block.timestamp + 2 days); // Fast forward time

        twamm.executeOrders();

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders[0].amount, 0); // Order should be marked as executed
    }

    function testFail_Swap() public {
        // Prepare the swap parameters
        VaultSwapParams memory vaultSwapParams = VaultSwapParams({
            kind: SwapKind.EXACT_IN,
            pool: address(twamm),
            tokenIn: tokenA,
            tokenOut: tokenB,
            amountGivenRaw: 0.5 ether,
            limitRaw: 0.1 ether,
            userData: ""
        });

        // Perform the swap
        (, , uint256 amountOutRaw) = twamm.swap(vaultSwapParams);

        // Assert that the swap was successful
        assertGt(amountOutRaw, 0);
    }

    function testWithdrawRemainingFunds() public {
        vm.warp(block.timestamp + 2 weeks); // Fast forward time past endTime

        twamm.withdrawRemainingFunds();

        uint256 remainingTokenA = tokenA.balanceOf(address(this));
        uint256 remainingTokenB = tokenB.balanceOf(address(this));

        assertGt(remainingTokenA, 0);
        assertGt(remainingTokenB, 0);
    }
}

contract MockVault {
    MockERC20 public tokenIn;
    MockERC20 public tokenOut;

    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut);

    function swap(uint256 amountIn) external returns (uint256 amountOut) {
        // Check for sufficient allowance and balance
        require(tokenIn.allowance(msg.sender, address(this)) >= amountIn, "Insufficient allowance");
        require(tokenIn.balanceOf(msg.sender) >= amountIn, "Insufficient balance");

        // Transfer tokens from the user to the vault
        tokenIn.transferFrom(msg.sender, address(this), amountIn);

        // Calculate the amountOut (for simplicity, assume 1:1 swap rate)
        amountOut = amountIn;

        // Transfer tokens from the vault to the user
        tokenOut.transfer(msg.sender, amountOut);

        // Emit event
        emit SwapExecuted(msg.sender, amountIn, amountOut);
    }
}

contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 1 ether;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
}
