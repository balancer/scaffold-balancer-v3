import "forge-std/Test.sol";
import "@balancer-labs/v3-vault/contracts/Vault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import "../contracts/hooks/DynamicBondHook/DynamicLoyaltyBondHook.sol";
import "../contracts/hooks/DynamicBondHook/LoyaltyBondStructure.sol";
import "../contracts/hooks/DynamicBondHook/AccessControl.sol";
import "../contracts/hooks/DynamicBondHook/BadgeToken";
import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

contract MockProtocolFeeController is IProtocolFeeController {
    function getProtocolFeePercentages(uint256) external pure returns (uint256, uint256) {
        return (0, 0);
    }

    function collectAggregateFees(address) external pure {}

    function computeAggregateFeePercentage(
        uint256 protocolFeePercentage,
        uint256 poolCreatorFeePercentage
    ) external pure returns (uint256) {
        // Mock implementation: simply return the sum of the two percentages
        return protocolFeePercentage + poolCreatorFeePercentage;
    }

    function registerPool(
        address pool,
        address poolCreator,
        bool protocolFeeExempt
    ) external pure returns (uint256, uint256) {
        return (0, 0);
    }

    function getGlobalProtocolSwapFeePercentage() external pure returns (uint256) {
        return 0;
    }
    function getGlobalProtocolYieldFeePercentage() external pure returns (uint256) {
        return 0;
    }
    function getPoolCreatorFeeAmounts(address) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }
    function getPoolProtocolSwapFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }
    function getPoolProtocolYieldFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }
}
contract DynamicBondHookTest is Test {
    DynamicLoyaltyBondHook public bondHook;
    RewardToken public rewardToken;
    MockProtocolFeeController public mockFeeController;
    address public user1;
    address public user2;

    function setUp() public {
        bondHook = new DynamicLoyaltyBondHook();
        rewardToken = new RewardToken(); // Assuming a constructor exists
        mockFeeController = new MockProtocolFeeController();
        user1 = address(0x1);
        user2 = address(0x2);
    }

    // Test for register function in DynamicLoyaltyBondHook
    function testRegister() public {
        bondHook.onRegister(user1);
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(user1);
        assertEq(bondAmount, 0, "Bond amount should be 0 after registration");
        assertEq(tier, 1, "Tier should be Bronze (1) after registration");
    }

    // Test for add liquidity function in DynamicLoyaltyBondHook
    function testAddLiquidity() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 1000 ether);
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(user1);
        assertEq(bondAmount, 1000 ether, "Bond amount should be 1000 after adding liquidity");
        assertEq(tier, 1, "Tier should still be Bronze (1) after adding liquidity");
    }

    // Test for remove liquidity function in DynamicLoyaltyBondHook
    function testRemoveLiquidity() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 1000 ether);
        bondHook.onBeforeRemoveLiquidity(user1, 500 ether);
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(user1);
        assertEq(bondAmount, 500 ether, "Bond amount should be 500 after removing liquidity");
    }

    // Test for dynamic swap fee calculation
    function testDynamicSwapFee() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 1000 ether);
        uint256 swapFee = bondHook.onComputeDynamicSwapFeePercentage(user1);
        assertEq(swapFee, 500, "Swap fee should reflect user loyalty tier");
    }

    // Test for tier upgrade based on bond amount
    function testTierUpgrade() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 10000 ether); // This should trigger a tier upgrade
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(user1);
        assertEq(tier, 2, "Tier should be Silver (2) after sufficient liquidity added");
    }

    // Test for loyalty bonus calculation
    function testLoyaltyBonus() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 2000 ether);
        uint256 loyaltyBonus = bondHook.calculateLoyaltyBonus(user1);
        assertEq(loyaltyBonus, 200, "Loyalty bonus should be calculated correctly based on bond amount");
    }

    // Test for the maximum bond limit
    function testMaxBondLimit() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 10000 ether); // Assume the max limit is set to a lower value
        (uint256 bondAmount, uint256 tier) = bondHook.getUserBond(user1);
        assertEq(bondAmount, 0, "Bond amount should not exceed max limit");
    }

    // Tests for RewardToken contract
    function testRewardDistribution() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 1000 ether);
        rewardToken.distributeRewards(user1, 100 ether); // Assuming a function exists
        uint256 rewardBalance = rewardToken.balanceOf(user1);
        assertEq(rewardBalance, 100 ether, "User should receive 100 rewards");
    }

    function testRewardClaim() public {
        bondHook.onRegister(user1);
        bondHook.onAfterAddLiquidity(user1, 1000 ether);
        rewardToken.distributeRewards(user1, 100 ether);
        rewardToken.claimRewards(user1); // Assuming a claim function exists
        uint256 userBalance = rewardToken.balanceOf(user1);
        assertEq(userBalance, 100 ether, "User should have claimed rewards");
    }
}
