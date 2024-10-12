// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
import "../contracts/hooks/NFTLiquidityStaking/NFTLiquidityStakingHook.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTMetadata.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTGovernor.sol";
import "../contracts/hooks/NFTLiquidityStaking/RewardToken.sol";
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

    function getGlobalProtocolSwapFeePercentage() external pure returns (uint256) { return 0; }
    function getGlobalProtocolYieldFeePercentage() external pure returns (uint256) { return 0; }
    function getPoolCreatorFeeAmounts(address) external pure returns (uint256[] memory) { return new uint256[](0); }
    function getPoolProtocolSwapFeeInfo(address) external pure returns (uint256, bool) { return (0, false); }
    function getPoolProtocolYieldFeeInfo(address) external pure returns (uint256, bool) { return (0, false); }
    function getProtocolFeeAmounts(address) external pure returns (uint256[] memory) { return new uint256[](0); }
    function setGlobalProtocolSwapFeePercentage(uint256) external pure {}
    function setGlobalProtocolYieldFeePercentage(uint256) external pure {}
    function setPoolCreatorSwapFeePercentage(address, uint256) external pure {}
    function setPoolCreatorYieldFeePercentage(address, uint256) external pure {}
    function setProtocolSwapFeePercentage(address, uint256) external pure {}
    function setProtocolYieldFeePercentage(address, uint256) external pure {}
    function updateProtocolSwapFeePercentage(address) external pure {}
    function updateProtocolYieldFeePercentage(address) external pure {}
    function vault() external pure returns (IVault) { return IVault(address(0)); }
    function withdrawPoolCreatorFees(address) external pure {}
    function withdrawPoolCreatorFees(address, address) external pure {}
    function withdrawProtocolFees(address, address) external pure {}
}


contract MockAuthorizer is IAuthorizer {
    function canPerform(bytes32, address, address) external pure override returns (bool) {
        return true;
    }
}

contract NFTLiquidityStakingHookTest is Test {
    using FixedPoint for uint256;

    NFTLiquidityStakingHook public hook;
    NFTMetadata public metadata;
    NFTGovernor public governor;
    RewardToken public rewardToken;
    PoolMock public pool;
    PoolFactoryMock public factory;
    RouterMock public router;

    address public alice;
    address public bob;

    uint256 public constant INITIAL_BALANCE = 1000000e18;
    uint256 public constant STAKE_AMOUNT = 1000e18;

    function setUp() public {
        console.log("Starting setUp()");
    
        address weth = 0x1D05f8153A0Dc80fB76fA728cFa3349624479ecb; 
        address permit2 = address(0x5678);

        console.log("Creating NFTMetadata");
        metadata = new NFTMetadata();
        console.log("NFTMetadata created at:", address(metadata));

        console.log("Creating PoolFactoryMock");
        factory = new PoolFactoryMock(IVault(address(0)), 0);
        console.log("PoolFactoryMock created at:", address(factory));

        console.log("Creating RouterMock");
        router = new RouterMock(IVault(address(0)), IWETH(weth), IPermit2(permit2));
        console.log("RouterMock created at:", address(router));

        console.log("Creating NFTLiquidityStakingHook");
        hook = new NFTLiquidityStakingHook(
            IVault(address(0)),
            address(factory),
            "Liquidity Staking NFT",
            "LSNFT",
            address(metadata)
        );
        console.log("NFTLiquidityStakingHook created at:", address(hook));

        governor = NFTGovernor(hook.governor());
        rewardToken = RewardToken(hook.rewardToken());

        console.log("Creating PoolMock");
        pool = new PoolMock(IVault(address(0)), "Test Pool", "TEST");
        console.log("PoolMock created at:", address(pool));

        console.log("Registering pool with factory");
    try factory.registerPool(
        address(pool),
        new TokenConfig[](0),
        PoolRoleAccounts({
            pauseManager: address(0),
            swapFeeManager: address(0),
            poolCreator: address(0)
        }),
        address(hook), 
        LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: false
        })
    ) {
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

        vm.label(address(hook), "NFTLiquidityStakingHook");
        vm.label(address(metadata), "NFTMetadata");
        vm.label(address(governor), "NFTGovernor");
        vm.label(address(rewardToken), "RewardToken");
        vm.label(address(pool), "Pool");
        vm.label(address(factory), "Factory");

        console.log("Dealing tokens to Alice and Bob");
        deal(address(pool), alice, INITIAL_BALANCE);
        deal(address(pool), bob, INITIAL_BALANCE);

        console.log("setUp() completed");
    }

    function simulateAddLiquidity(address user, address poolAddress, uint256 amount) internal {
        vm.prank(address(0));
        (bool success, ) = address(hook).call(
            abi.encodeWithSignature(
                "onAfterAddLiquidity(address,address,uint256,uint256,bytes)",
                user,
                poolAddress,
                amount,
                amount,
                ""
            )
        );
        require(success, "onAfterAddLiquidity call failed");
    }

    function simulateRemoveLiquidity(address user, address poolAddress, uint256 amount) internal {
        vm.prank(address(0));
        (bool success, ) = address(hook).call(
            abi.encodeWithSignature(
                "onAfterRemoveLiquidity(address,address,uint256,uint256,bytes)",
                user,
                poolAddress,
                amount,
                amount,
                ""
            )
        );
        require(success, "onAfterRemoveLiquidity call failed");
    }

    function testStakingAndNFTMinting() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(hook.balanceOf(alice), 1, "NFT not minted");
        assertEq(hook.ownerOf(1), alice, "Wrong NFT owner");

        (
            uint256 stakedAmount,
            uint256 stakingStartTime,
            uint256 lastMilestoneTime,
            uint256 currentTier,
            uint256 lastRewardClaim
        ) = hook.stakingInfo(alice, address(pool));

        assertEq(stakedAmount, STAKE_AMOUNT, "Wrong staked amount");
        assertEq(currentTier, 0, "Wrong initial tier");
        assertEq(lastRewardClaim, block.timestamp, "Wrong last reward claim time");
    }

    function testTierUpgrade() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.BRONZE_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        (, , , uint256 currentTier, ) = hook.stakingInfo(alice, address(pool));
        assertEq(currentTier, 1, "Failed to upgrade to Bronze tier");
    }

    function testFeeDiscount() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.BRONZE_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        uint256 discount = hook.getFeeDiscount(alice, address(pool));
        assertGt(discount, 0, "No fee discount applied");
    }

    function testVotingPower() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.BRONZE_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        uint256 votingPower = hook.getVotes(alice);
        assertGt(votingPower, 0, "No voting power assigned");
    }

    function testRewardClaiming() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        uint256 rewardsBefore = rewardToken.balanceOf(alice);

        vm.prank(alice);
        hook.claimRewards(address(pool));

        uint256 rewardsAfter = rewardToken.balanceOf(alice);
        assertGt(rewardsAfter, rewardsBefore, "No rewards claimed");
    }

    function testGovernanceProposal() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.GOLD_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        address[] memory targets = new address[](1);
        targets[0] = address(hook);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("setFeeDiscounts(uint256[],uint256[])", [uint256(1)], [uint256(10)]);
        string memory description = "Update fee discount for Bronze tier";

        vm.prank(alice);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertGt(proposalId, 0, "Proposal not created");
    }

    function testUnstaking() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + hook.COOLDOWN_PERIOD() + 1);

        uint256 balanceBefore = pool.balanceOf(alice);

        simulateRemoveLiquidity(alice, address(pool), STAKE_AMOUNT);

        uint256 balanceAfter = pool.balanceOf(alice);
        assertEq(balanceAfter, balanceBefore + STAKE_AMOUNT, "Unstaking failed");
    }

    function testYieldBoost() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.GOLD_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        uint256 yieldBoost = hook.getYieldBoost(alice, address(pool));
        assertGt(yieldBoost, 0, "No yield boost applied");
    }

    function testNFTMetadata() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.warp(block.timestamp + hook.GOLD_TIER_THRESHOLD());
        hook.upgradeNFT(1);
        vm.stopPrank();

        string memory tokenURI = hook.tokenURI(1);
        assertGt(bytes(tokenURI).length, 0, "Empty token URI");
    }

    function testGovernanceProposalCreationAndVoting() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        vm.startPrank(bob);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(bob, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        address[] memory targets = new address[](1);
        targets[0] = address(hook);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("setFeeDiscounts(uint256[],uint256[])", [uint256(1)], [uint256(10)]);
        string memory description = "Update fee discount for Bronze tier";

        vm.prank(alice);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + governor.votingDelay() + 1);
        vm.warp(block.timestamp + 13);

        vm.prank(alice);
        governor.castVote(proposalId, 1); 

        vm.prank(bob);
        governor.castVote(proposalId, 0); 

        vm.roll(block.number + governor.votingPeriod() + 1);
        vm.warp(block.timestamp + 7 days + 1);

        assertEq(uint(governor.state(proposalId)), uint(IGovernor.ProposalState.Succeeded));

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));

        vm.warp(block.timestamp + governor.votingDelay() + 1);

        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        (uint256[] memory tiers, uint256[] memory discounts) = hook.getFeeDiscounts();
        assertEq(tiers[0], 1);
        assertEq(discounts[0], 10);
    }

    function testUpgradeNFTBeforeCooldown() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        uint256 tokenId = hook.tokenOfOwnerByIndex(alice, 0);
        vm.stopPrank();

        vm.expectRevert("Upgrade cooldown period not over");
        hook.upgradeNFT(tokenId);
    }

    function testClaimRewardsWithNoStake() public {
        vm.expectRevert("No staking position");
        hook.claimRewards(address(pool));
    }

    function testFeeDiscountCalculation() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        uint256 tokenId = hook.tokenOfOwnerByIndex(alice, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + hook.BRONZE_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 bronzeDiscount = hook.getFeeDiscount(alice, address(pool));
        assertEq(bronzeDiscount, 10, "Incorrect Bronze tier discount");

        vm.warp(block.timestamp + hook.SILVER_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 silverDiscount = hook.getFeeDiscount(alice, address(pool));
        assertEq(silverDiscount, 20, "Incorrect Silver tier discount");

        vm.warp(block.timestamp + hook.GOLD_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 goldDiscount = hook.getFeeDiscount(alice, address(pool));
        assertEq(goldDiscount, 30, "Incorrect Gold tier discount");
    }

    function testYieldBoostCalculation() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        uint256 tokenId = hook.tokenOfOwnerByIndex(alice, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + hook.BRONZE_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 bronzeBoost = hook.getYieldBoost(alice, address(pool));
        assertEq(bronzeBoost, 10, "Incorrect Bronze tier yield boost");

        vm.warp(block.timestamp + hook.SILVER_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 silverBoost = hook.getYieldBoost(alice, address(pool));
        assertEq(silverBoost, 20, "Incorrect Silver tier yield boost");

        vm.warp(block.timestamp + hook.GOLD_TIER_THRESHOLD());
        hook.upgradeNFT(tokenId);
        uint256 goldBoost = hook.getYieldBoost(alice, address(pool));
        assertEq(goldBoost, 30, "Incorrect Gold tier yield boost");
    }

    function testMultipleStakingPositions() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT * 2);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        assertEq(hook.balanceOf(alice), 2, "Incorrect number of NFTs minted");

        (uint256 stakedAmount, , , , ) = hook.stakingInfo(alice, address(pool));
        assertEq(stakedAmount, STAKE_AMOUNT * 2, "Incorrect total staked amount");
    }

    function testUnstakingPartialAmount() public {
        vm.startPrank(alice);
        pool.approve(address(hook), STAKE_AMOUNT);
        simulateAddLiquidity(alice, address(pool), STAKE_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + hook.COOLDOWN_PERIOD() + 1);

        uint256 unstakeAmount = STAKE_AMOUNT / 2;
        simulateRemoveLiquidity(alice, address(pool), unstakeAmount);

        (uint256 remainingStake, , , , ) = hook.stakingInfo(alice, address(pool));
        assertEq(remainingStake, STAKE_AMOUNT - unstakeAmount, "Incorrect remaining stake");
    }
}