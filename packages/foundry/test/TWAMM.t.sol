// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TWAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";

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
            1000 ether,
            1000 ether,
            block.timestamp,
            block.timestamp + 1 weeks,
            1 hours
        );

        tokenA.approve(address(twamm), type(uint256).max);
        tokenB.approve(address(twamm), type(uint256).max);
    }

    function testCreateOrder() public {
        uint256 amount = 100 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders.length, 1);
        assertEq(orders[0].amount, amount);
        assertEq(orders[0].isBuy, isBuy);
    }

    function testCancelOrder() public {
        uint256 amount = 100 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);
        twamm.cancelOrder(0);

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders.length, 0);
    }

    function testExecuteOrders() public {
        uint256 amount = 100 ether;
        uint256 duration = 1 days;
        bool isBuy = true;

        twamm.createOrder(amount, duration, isBuy);
        vm.warp(block.timestamp + 2 days); // Fast forward time

        twamm.executeOrders();

        TWAMM.Order[] memory orders = twamm.getOrders(user);
        assertEq(orders[0].amount, 0); // Order should be marked as executed
    }

    function testSwap() public {
        // Prepare the swap parameters
        TWAMM.VaultSwapParams memory vaultSwapParams = TWAMM.VaultSwapParams({
            kind: TWAMM.SwapKind.EXACT_IN,
            pool: address(twamm),
            tokenIn: tokenA,
            tokenOut: tokenB,
            amountGivenRaw: 100 ether,
            limitRaw: 0,
            userData: ""
        });
    
        uint256 limit = 0;
        uint256 deadline = block.timestamp + 1 hours;
    
        // Perform the swap
        (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw) = twamm.swap(vaultSwapParams, limit, deadline);
    
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

// Mock contracts for testing
contract MockVault is IVault {
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
        totalSupply = 1000000 ether;
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
