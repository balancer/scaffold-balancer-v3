// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Balancer/BaseHooks.sol";
import "Balancer/VaultGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CommitMinerHook is BaseHooks, VaultGuard, ReentrancyGuard {
    struct Commit {
        bytes32 hash;         // The commit hash
        uint256 blockNumber;  // The block number when the commit was created
        address pool;         // The pool that generated the commit
        address swapper;      // Address of the user who performed the swap
    }

    IERC20 public immutable paymentToken;  // The ERC20 token used for both payments and rewards
    address private immutable hookDeployer;  // Address of the hook deployer
    Commit[] public commitBacklog;  // Array storing all commits
    uint256 public feePercentage = 10;  // 10% fee to hook deployer, 30% swappers, 60% pool LPs

    event CommitGenerated(address indexed pool, address indexed swapper, bytes32 commitHash, uint256 blockNumber);
    event RandomnessRequested(address indexed requester, uint256 amountPaid, uint256 commitCount);
    event FeeDistributed(address indexed pool, address indexed recipient, uint256 amount);

    constructor(IVault vault, IERC20 _paymentToken) VaultGuard(vault) {
        hookDeployer = msg.sender;
        paymentToken = _paymentToken;  // The specified ERC20 token for all payments and rewards
    }

    function getHookFlags() public pure override returns (IHooks.HookFlags memory hookFlags) {
        hookFlags.shouldCallBeforeSwap = true;
    }

    /// @inheritdoc IHooks
    function onRegister(address factory, address pool, ...) public override onlyVault returns (bool) {
        return true;
    }

    // Hook triggered before a swap to create a commit
    function onBeforeSwap(
        address pool,
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address user
    ) external override onlyVault {
        bytes32 commitHash = keccak256(abi.encodePacked(block.timestamp, user, amountIn, amountOut, pool, gasleft()));
        commitBacklog.push(Commit(commitHash, block.number, pool, user));

        emit CommitGenerated(pool, user, commitHash, block.number);
    }

    // Randomness requester pays for a batch of commits using the specified paymentToken
    function requestRandomness(uint256 commitCount, uint256 amountPaid) external nonReentrant {
        require(commitCount <= commitBacklog.length, "Not enough commits available");

        // Transfer payment from requester
        require(paymentToken.transferFrom(msg.sender, address(this), amountPaid), "Payment transfer failed");

        // Generate randomness based on the selected number of commits
        bytes32 finalRandomness = aggregateCommits(commitCount);

        // Emit event for randomness request
        emit RandomnessRequested(msg.sender, amountPaid, commitCount);

        // Distribute fees
        distributeFees(amountPaid, commitCount);
    }

    // Function to aggregate commits into randomness
    function aggregateCommits(uint256 commitCount) internal view returns (bytes32) {
        bytes32 randomness;
        for (uint256 i = commitBacklog.length - commitCount; i < commitBacklog.length; i++) {
            randomness = keccak256(abi.encodePacked(randomness, commitBacklog[i].hash, block.number, gasleft()));
        }
        return randomness;
    }

    // Function to distribute fees among swappers, LPs, and the hook deployer
    function distributeFees(uint256 amountPaid, uint256 commitCount) internal nonReentrant {
        uint256 hookFee = (amountPaid * 10) / 100;  // 10% to hook deployer
        uint256 swapperFee = (amountPaid * 30) / 100;  // 30% to swappers
        uint256 lpFee = amountPaid - hookFee - swapperFee;  // 60% to pool LPs

        // Transfer 10% to hook deployer
        require(paymentToken.transfer(hookDeployer, hookFee), "Hook deployer fee transfer failed");

        // Distribute 30% to the swappers
        uint256 perSwapperFee = swapperFee / commitCount;
        for (uint256 i = commitBacklog.length - commitCount; i < commitBacklog.length; i++) {
            require(paymentToken.transfer(commitBacklog[i].swapper, perSwapperFee), "Swapper fee transfer failed");
            emit FeeDistributed(commitBacklog[i].pool, commitBacklog[i].swapper, perSwapperFee);
        }

        // Distribute 60% to the LPs
        uint256 perPoolFee = lpFee / commitCount;
        for (uint256 i = commitBacklog.length - commitCount; i < commitBacklog.length; i++) {
            require(paymentToken.transfer(commitBacklog[i].pool, perPoolFee), "LP fee transfer failed");  // Simplified; could route to LPs via pool logic
            emit FeeDistributed(commitBacklog[i].pool, msg.sender, perPoolFee);
        }
    }

    // Use quadratic pricing model for commit pricing
    function calculateFeeForCommits(uint256 commitCount) internal view returns (uint256) {
        uint256 basePrice = 1e18;  // 1 token as base price per commit
        return commitCount ** 2 * basePrice;  // Quadratic pricing
    }

    // Allow the user to pay more for more commits to improve randomness quality
    function payMoreForMoreCommits(uint256 commitWindowSize, uint256 additionalAmount) external nonReentrant {
        uint256 amountRequired = calculateFeeForCommits(commitWindowSize);
        require(additionalAmount >= amountRequired, "Insufficient payment");

        // Proceed with larger batch of commits
        requestRandomness(commitWindowSize, additionalAmount);
    }
}
