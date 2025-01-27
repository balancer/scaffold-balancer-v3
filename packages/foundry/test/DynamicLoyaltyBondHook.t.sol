pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@balancer-labs/v3-vault/contracts/Vault.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "../contracts/hooks/DynamicBondHook/DynamicLoyaltyBondHook.sol";
import "../contracts/hooks/DynamicBondHook/AccessControl.sol";
import "../contracts/hooks/DynamicBondHook/BadgeToken.sol";
import "../contracts/hooks/DynamicBondHook/LoyaltyBondStructure.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";



contract DynamicBondHookTest is Test {
    using FixedPoint for uint256;

    DynamicLoyaltyBondHook public bondHook;
    PoolMock public pool;
    PoolFactoryMock public factory;
    RouterMock public router;

    address public alice;
    address public bob;
    uint256 public constant STAKE_AMOUNT = 1000e18;

    // Setup function
    function setUp() public {
        console.log("Starting setUp()");

        address weth = 0x1D05f8153A0Dc80fB76fA728cFa3349624479ecb;
        address permit2 = address(0x5678);

        console.log("Creating PoolFactoryMock");
        factory = new PoolFactoryMock(IVault(address(0)), 0);
        console.log("PoolFactoryMock created at:", address(factory));

        console.log("Creating RouterMock");
        router = new RouterMock(IVault(address(0)), IWETH(weth), IPermit2(permit2));
        console.log("RouterMock created at:", address(router));

        console.log("Creating DynamicBondHook");
        hook = new DynamicBondHook(
            IVault(address(0)),
            address(factory),
            "Dynamic Bond Token",
            "DBOND"
        );
        console.log("DynamicBondHook created at:", address(hook));

        rewardToken = RewardToken(hook.rewardToken());

        console.log("Creating PoolMock");
        pool = new PoolMock(IVault(address(0)), "Bonded Liquidity Pool", "BLP");
        console.log("PoolMock created at:", address(pool));

        console.log("Registering pool with factory");
        try
            factory.registerPool(
                address(pool),
                new TokenConfig              PoolRoleAccounts({ 
                    pauseManager: address(0), 
                    swapFeeManager: address(0), 
                    poolCreator: address(0) 
                }),
                address(hook),
                LiquidityManagement({
                    disableUnbalancedLiquidity: false,
                    enableAddLiquidityCustom: true,
                    enableRemoveLiquidityCustom: true,
                    enableDonation: true
                })
            )
        {
            console.log("Pool registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to register pool. Reason:", reason);
            revert(reason);
        } catch (bytes memory lowLevelData) {
            console.log("Failed to register pool. Low-level error.");
            revert("Low-level error in pool registration");
        }

        alice = address(0x1);
        bob = address(0x2);

        vm.label(address(hook), "DynamicBondHook");
        vm.label(address(rewardToken), "RewardToken");
        vm.label(address(pool), "Pool");
        vm.label(address(factory), "Factory");

        console.log("Dealing tokens to Alice and Bob");
        deal(address(pool), alice, INITIAL_BALANCE);
        deal(address(pool), bob, INITIAL_BALANCE);

        console.log("setUp() completed");
    }

    // 1. Registration Tests
    function testRegisterUser() public {
        bondHook.onRegister(alice);
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(alice);
        assertEq(bondAmount, 0, "Initial bond amount should be 0");
        assertEq(tier, 1, "Initial tier should be Bronze");
    }

    // 2. Bond Management Tests
    function testCreateBond() public {
        bondHook.createBond(alice, STAKE_AMOUNT);
        (address holder, uint256 amount) = bondHook.getBondDetails(alice);
        assertEq(holder, alice, "Bond holder should be Alice");
        assertEq(amount, STAKE_AMOUNT, "Bond amount should match staked amount");
    }

    function testRedeemBond() public {
        bondHook.createBond(alice, STAKE_AMOUNT);
        bondHook.redeemBond(alice);
        (address holder, uint256 amount) = bondHook.getBondDetails(alice);
        assertEq(holder, address(0), "Bond should be removed");
        assertEq(amount, 0, "Bond amount should be 0 after redemption");
    }

    // 3. Liquidity Interaction Tests
    function testAddLiquidity() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(alice);
        assertEq(bondAmount, 1000 ether, "Bond amount should reflect added liquidity");
    }

    function testRemoveLiquidity() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
        bondHook.onBeforeRemoveLiquidity(alice, 500 ether);
        (uint256 bondAmount, ) = bondHook.getUserBond(alice);
        assertEq(bondAmount, 500 ether, "Bond amount should decrease after removal");
    }

    // 4. Reward Calculation Tests
    function testCalculateBondReward() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 2000 ether);
        uint256 reward = bondHook.calculateBondReward(alice, address(pool));
        assertEq(reward, 200 ether, "Reward should be correctly calculated");
    }

    function testTierUpgrade() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 10000 ether);
        ( , uint256 tier) = bondHook.getUserBond(alice);
        assertEq(tier, 2, "User should be upgraded to Silver tier");
    }

    function testLoyaltyBonus() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 3000 ether);
        uint256 bonus = bondHook.calculateLoyaltyBonus(alice);
        assertEq(bonus, 300 ether, "Loyalty bonus should be accurate");
    }

    // 5. Swap Fee Calculation Test
    function testDynamicSwapFee() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
        uint256 swapFee = bondHook.onComputeDynamicSwapFeePercentage(alice);
        assertEq(swapFee, 500, "Swap fee should match user tier");
    }

    // 6. Decay Mechanism Test
    function testBondDecay() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 2000 ether);
        vm.warp(block.timestamp + 60 days);
        uint256 decayedReward = bondHook.calculateBondReward(alice, address(pool));
        assertTrue(decayedReward < 2000 ether, "Reward should decay over time");
    }

    // 7. Multi-Tier Rewards Test
    function testMultiTierRewards() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 5000 ether);
        vm.warp(block.timestamp + 30 days);
        bondHook.upgradeToStrategicVeteran(alice);
        ( , uint256 tier) = bondHook.getUserBond(alice);
        assertEq(tier, 3, "User should upgrade to Strategic Veteran tier");
    }

    // 8. Maximum Bond Limit Test
    function testMaxBondLimit() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 100000 ether); // Exceeds limit
        (uint256 bondAmount, ) = bondHook.getUserBond(alice);
        assertEq(bondAmount, 0, "Bond amount should not exceed limit");
    }

    // 9. Reward Token Tests
    function testRewardDistribution() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
        bondHook.distributeRewards(alice, 100 ether);
        uint256 rewardBalance = bondHook.getRewardBalance(alice);
        assertEq(rewardBalance, 100 ether, "User should receive correct reward");
    }

    function testClaimRewards() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
        bondHook.distributeRewards(alice, 100 ether);
        bondHook.claimRewards(alice);
        uint256 rewardBalance = bondHook.getRewardBalance(alice);
        assertEq(rewardBalance, 0, "Rewards should be claimed successfully");
    }
    // 10. Test Invalid User Registration
    function testRegisterInvalidUser() public {
        address invalidUser = address(0); // Address zero as an invalid case
        vm.expectRevert("Invalid user address"); // Assuming revert message from the contract
        bondHook.onRegister(invalidUser);
    }
    
    // 11. Test Bond Creation with Insufficient Funds
    function testBondCreationInsufficientFunds() public {
        bondHook.onRegister(bob); 
        deal(address(pool), bob, 500 ether); // Bob has insufficient balance
        vm.startPrank(bob); 
        vm.expectRevert("Insufficient balance for bond creation");
        bondHook.createBond(bob, 1000 ether); // Trying to create a bond exceeding balance
        vm.stopPrank();
    }
    
    // 12. Test Bond Transfer Between Users
    function testBondTransfer() public {
        bondHook.onRegister(alice);
        bondHook.createBond(alice, STAKE_AMOUNT);
        
        // Transfer bond from Alice to Bob
        bondHook.transferBond(alice, bob);
        (address holder, uint256 amount) = bondHook.getBondDetails(bob);
        
        assertEq(holder, bob, "Bob should now hold the bond");
        assertEq(amount, STAKE_AMOUNT, "Transferred bond amount should be correct");
    }
    
    // 13. Test Reward Decay with Partial Withdrawal
    function testPartialWithdrawalWithDecay() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 5000 ether);
        
        // Simulate time passing and partial liquidity removal
        vm.warp(block.timestamp + 30 days);
        bondHook.onBeforeRemoveLiquidity(alice, 2500 ether);
        
        uint256 remainingBond = bondHook.getBondAmount(alice);
        uint256 decayedReward = bondHook.calculateBondReward(alice, address(pool));
        
        assertEq(remainingBond, 2500 ether, "Remaining bond should match the withdrawn amount");
        assertTrue(decayedReward < 5000 ether, "Reward should decay after 30 days");
    }
    
    // 14. Test Governance-Based Bonus Allocation
    function testGovernanceBonusAllocation() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 2000 ether);
    
        // Grant governance bonus
        bondHook.allocateGovernanceBonus(alice, 500 ether);
        uint256 totalReward = bondHook.calculateTotalReward(alice);
        
        assertEq(totalReward, 700 ether, "Total reward should include governance bonus");
    }
    
    // 15. Test Hook with Multiple Users and Liquidity Events
    function testMultipleUsersLiquidityInteraction() public {
        bondHook.onRegister(alice);
        bondHook.onRegister(bob);
    
        bondHook.onAfterAddLiquidity(alice, 3000 ether);
        bondHook.onAfterAddLiquidity(bob, 5000 ether);
    
        // Alice removes liquidity partially
        bondHook.onBeforeRemoveLiquidity(alice, 1000 ether);
    
        // Validate both users' bond amounts
        uint256 aliceBond = bondHook.getBondAmount(alice);
        uint256 bobBond = bondHook.getBondAmount(bob);
    
        assertEq(aliceBond, 2000 ether, "Alice's bond amount should be correct");
        assertEq(bobBond, 5000 ether, "Bob's bond amount should remain unchanged");
    }
    
    // 16. Test Swap Fee Adjustment Based on Tier Downgrade
    function testSwapFeeAdjustmentOnTierDowngrade() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 10000 ether); // User reaches Silver tier
    
        vm.warp(block.timestamp + 90 days); // Simulate inactivity for 3 months
        bondHook.downgradeUserTier(alice);  // Downgrade to Bronze
    
        uint256 newSwapFee = bondHook.onComputeDynamicSwapFeePercentage(alice);
        assertEq(newSwapFee, 300, "Swap fee should adjust to Bronze tier percentage");
    }
    
    // 17. Test Reward Claim by Unauthorized User
    function testUnauthorizedRewardClaim() public {
        bondHook.onRegister(alice);
        bondHook.onAfterAddLiquidity(alice, 1000 ether);
    
        vm.prank(bob); // Simulate Bob trying to claim Alice's reward
        vm.expectRevert("Unauthorized reward claim attempt");
        bondHook.claimRewards(alice);
    }

    //18. Bond Reward Calculation
    function getBondReward(address user) public view returns (uint256 reward, string memory tier) {
    uint256 bondAmount = getBondAmount(user);
    uint256 governanceBonus = governanceRewards[user];
    uint256 tierBonus = calculateTierBonus(user);

    reward = bondAmount + governanceBonus + tierBonus;

    // Determine user’s reward tier based on their bond amount
    if (bondAmount >= 10000 ether) {
        tier = "Veteran"; // Highest reward tier
    } else if (bondAmount >= 5000 ether) {
        tier = "Strategist"; // Mid-level reward tier
    } else {
        tier = "Explorer"; // Base reward tier
    }

    function testUserBondTier() public {
    console.log("Testing user reward tiers based on bond amount");

    // Alice adds 12,000 ETH (Veteran Tier)
    vm.startPrank(alice);
    pool.approve(address(hook), 12000 ether);
    hook.onAfterAddLiquidity(alice, 12000 ether);
    assertEq(hook.getUserTier(alice), "Veteran", "Alice should be in the Veteran tier");
    vm.stopPrank();

    // Bob adds 6,000 ETH (Strategic Tier)
    vm.startPrank(bob);
    pool.approve(address(hook), 6000 ether);
    hook.onAfterAddLiquidity(bob, 6000 ether);
    assertEq(hook.getUserTier(bob), "Strategic", "Bob should be in the Strategic tier");
    vm.stopPrank();

    // Alice removes some liquidity, moving her to the Strategic tier
    vm.startPrank(alice);
    hook.onBeforeRemoveLiquidity(alice, 3000 ether); // Alice now has 9,000 ETH
    assertEq(hook.getUserTier(alice), "Explorer", "Alice should be downgraded to Explorer tier");
    vm.stopPrank();
    }

}

