// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CommitMinerHook.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract CommitMinerHookTest is Test {
    CommitMinerHook public commitMinerHook;
    IERC20 public paymentToken;
    address public pool;
    address public swapper;
    address public lps;
    address public deployer;

    function setUp() public {
        // Mock addresses
        pool = address(0x123);
        swapper = address(0x456);
        lps = address(0x789);
        deployer = address(this);

        // Deploy a mock ERC20 payment token
        paymentToken = IERC20(address(new MockERC20()));
        
        // Deploy the CommitMinerHook contract
        IVault vault = IVault(address(0x111));
        commitMinerHook = new CommitMinerHook(vault, paymentToken);
    }

    // Test commit generation on a swap
    function testCommitGeneratedOnSwap() public {
        // Set up mock swap details
        uint256 amountIn = 1000 * 1e18;
        uint256 amountOut = 900 * 1e18;
        address tokenIn = address(0x222);
        address tokenOut = address(0x333);

        // Simulate a swap and trigger the onBeforeSwap hook
        vm.prank(swapper);
        commitMinerHook.onBeforeSwap(pool, amountIn, amountOut, tokenIn, tokenOut, swapper);

        // Verify that a commit has been generated
        (bytes32 hash, uint256 blockNumber, address poolAddress, address swapperAddress) = commitMinerHook.commitBacklog(0);
        assertEq(poolAddress, pool);
        assertEq(swapperAddress, swapper);
    }

    // Test randomness request and fee transfer
    function testRandomnessRequestAndFeeTransfer() public {
        // Set up mock commits
        createMockCommits(3);

        // Set up fee for requesting randomness
        uint256 commitCount = 2;
        uint256 fee = commitMinerHook.calculateFeeForCommits(commitCount);

        // Mint tokens to the randomness requester
        paymentToken.mint(address(this), fee);

        // Approve the contract to spend the tokens
        paymentToken.approve(address(commitMinerHook), fee);

        // Request randomness
        commitMinerHook.requestRandomness(commitCount, fee);

        // Verify the fee has been transferred and distributed
        assertEq(paymentToken.balanceOf(deployer), fee / 10);  // 10% to deployer
        // Further checks for swapper and LP distribution can be done here
    }

    // Test quadratic pricing model for commits
    function testQuadraticPricingForCommits() public {
        uint256 commitCount = 4;
        uint256 expectedFee = 16 * 1e18;  // 4^2 * 1e18
        uint256 calculatedFee = commitMinerHook.calculateFeeForCommits(commitCount);

        // Verify the calculated fee matches the quadratic pricing model
        assertEq(calculatedFee, expectedFee);
    }

    // Test fee distribution to swappers, LPs, and deployer
    function testFeeDistribution() public {
        // Set up mock commits and fees
        createMockCommits(3);
        uint256 commitCount = 2;
        uint256 fee = commitMinerHook.calculateFeeForCommits(commitCount);
        paymentToken.mint(address(this), fee);
        paymentToken.approve(address(commitMinerHook), fee);

        // Request randomness to trigger fee distribution
        commitMinerHook.requestRandomness(commitCount, fee);

        // Verify fee distribution to hook deployer, swappers, and LPs
        uint256 hookDeployerFee = (fee * 10) / 100;
        uint256 swapperFee = (fee * 30) / 100;
        uint256 lpFee = fee - hookDeployerFee - swapperFee;

        assertEq(paymentToken.balanceOf(deployer), hookDeployerFee);
        assertEq(paymentToken.balanceOf(swapper), swapperFee / commitCount);  // 30% split between swappers
        assertEq(paymentToken.balanceOf(pool), lpFee / commitCount);  // 60% to LPs
    }

    // Helper function to create mock commits
    function createMockCommits(uint256 numCommits) internal {
        for (uint256 i = 0; i < numCommits; i++) {
            vm.prank(swapper);
            commitMinerHook.onBeforeSwap(pool, 1000 * 1e18, 900 * 1e18, address(0x111), address(0x222), swapper);
        }
    }
}

// Mock ERC20 contract to simulate payment token behavior
contract MockERC20 is IERC20 {
    string public name = "Mock ERC20";
    string public symbol = "MERC20";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;
    }
}
