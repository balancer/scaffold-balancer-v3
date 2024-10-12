// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTLiquidityStakingHook.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTMetadata.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTGovernor.sol";
import "../contracts/hooks/NFTLiquidityStaking/RewardToken.sol";
import "@balancer-labs/v3-vault/contracts/Vault.sol";

contract DeployNFTLiquidityStakingHook is Script {
    function run(address _vaultAddress, address _factoryAddress) external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

       
        NFTMetadata metadata = new NFTMetadata();
        console.log("NFTMetadata deployed at:", address(metadata));


RewardToken rewardToken = new RewardToken(address(this)); 
console.log("RewardToken deployed at:", address(rewardToken));

    
       address vaultAddress = 0x7966FE92C59295EcE7FB5D9EfDB271967BFe2fbA; 
        address factoryAddress = 0x765ce16dbb3D7e89a9beBc834C5D6894e7fAA93c; 

       
        NFTLiquidityStakingHook hook = new NFTLiquidityStakingHook(
            IVault(vaultAddress),
            factoryAddress,
            "Liquidity Staking NFT",
            "LSNFT",
            address(metadata)
        );

        console.log("NFTLiquidityStakingHook deployed at:", address(hook));
      
        hook.setRewardToken(address(rewardToken));
        console.log("RewardToken set for NFTLiquidityStakingHook");

       
        NFTGovernor governor = new NFTGovernor(IVotes(address(hook)));
        console.log("NFTGovernor deployed at:", address(governor));

    
hook.setGovernor(payable(address(governor)));
console.log("Governor set for NFTLiquidityStakingHook");

      
        uint256[] memory tiers = new uint256[](3);
        tiers[0] = 1; 
        tiers[1] = 2; 
        tiers[2] = 3; 

        uint256[] memory feeDiscounts = new uint256[](3);
        feeDiscounts[0] = 10; // 10% discount for Bronze
        feeDiscounts[1] = 20; // 20% discount for Silver
        feeDiscounts[2] = 30; // 30% discount for Gold

        hook.setFeeDiscounts(tiers, feeDiscounts);
        console.log("Fee discounts set for NFTLiquidityStakingHook");

        uint256[] memory votingPowers = new uint256[](3);
        votingPowers[0] = 1; // 1x voting power for Bronze
        votingPowers[1] = 2; // 2x voting power for Silver
        votingPowers[2] = 3; // 3x voting power for Gold

        hook.setVotingPowers(tiers, votingPowers);
        console.log("Voting powers set for NFTLiquidityStakingHook");

        uint256[] memory yieldBoosts = new uint256[](3);
        yieldBoosts[0] = 10; // 10% yield boost for Bronze
        yieldBoosts[1] = 20; // 20% yield boost for Silver
        yieldBoosts[2] = 30; // 30% yield boost for Gold

        hook.setYieldBoosts(tiers, yieldBoosts);
        console.log("Yield boosts set for NFTLiquidityStakingHook");

        vm.stopBroadcast();
    }
}