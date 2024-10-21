// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AddLiquidityParams,
    LiquidityManagement,
    RemoveLiquidityKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

interface IGovernanceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract StakedGovernanceHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    // Constants and state variables
    uint64 public constant NOT_VOTING = type(uint64).max;
    uint64 public governanceTokenPercentage = 10e16; // 10% - Initial percentage of governance tokens to mint
    uint64 public majorityThreshold = 51e16; // 51% - Threshold for passing governance updates
    IGovernanceToken public governanceToken;
    IERC20 public stableToken;

    // Struct to represent a user's stake and voting preferences
    struct Stake {
        uint256 amount;
        uint64 votedGovernancePercentage;
        uint64 votedMajorityThreshold;
    }

    // Mappings and state variables for tracking stakes and votes
    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    address[] public stakers; // Array to keep track of all stakers

    // Events for various actions
    event GovernanceTokensMinted(address indexed user, uint256 amount);
    event GovernanceTokensBurned(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount, uint64 votedGovernancePercentage, uint64 votedMajorityThreshold);
    event Unstaked(address indexed user, uint256 amount);
    event VoteChanged(address indexed user, uint64 newGovernancePercentage, uint64 newMajorityThreshold);
    event GovernanceTokenPercentageUpdated(uint64 newPercentage);
    event MajorityThresholdUpdated(uint64 newThreshold);

    constructor(IVault vault, IGovernanceToken _governanceToken, IERC20 _stableToken) 
        VaultGuard(vault) 
        Ownable(msg.sender) 
    {
        governanceToken = _governanceToken;
        stableToken = _stableToken;
    }

    // Hook function called after adding liquidity to the pool
    function onAfterAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory amountsIn,
        uint256,
        uint256,
        bytes memory
    ) public onlyVault returns (bool) {
        // Find the index of the stable token in the pool
        uint256 stableTokenIndex = getStableTokenIndex();
        uint256 stableTokenAmount = amountsIn[stableTokenIndex];
        
        // Calculate and mint governance tokens based on the stable token amount added
        uint256 governanceTokenAmount = stableTokenAmount.mulDown(governanceTokenPercentage);
        governanceToken.mint(msg.sender, governanceTokenAmount);
        emit GovernanceTokensMinted(msg.sender, governanceTokenAmount);
        
        return true;
    }
    function onBeforeRemoveLiquidity(
    address sender,
    address,
    RemoveLiquidityKind,
    uint256[] memory amountsOut,
    uint256,
    uint256,
    bytes memory
) public onlyVault returns (bool) {
    // Find the index of the stable token in the pool
    uint256 stableTokenIndex = getStableTokenIndex();
    
    // Get the amount of stable tokens being removed from the pool
    uint256 stableTokenAmount = amountsOut[stableTokenIndex];
    
    // Calculate the amount of governance tokens that need to be burned
    // This is proportional to the stable tokens being removed and the governance token percentage
    uint256 governanceTokensToBurn = stableTokenAmount.mulDown(governanceTokenPercentage);
    
    // Check if the user has enough governance tokens to burn
    // This ensures the user can't remove liquidity without having the corresponding governance tokens
    require(governanceToken.balanceOf(sender) >= governanceTokensToBurn, "Insufficient governance tokens");
    
    // Burn the required amount of governance tokens
    // This reduces the total supply of governance tokens proportionally to the liquidity removed
    governanceToken.burn(sender, governanceTokensToBurn);
    
    // Emit an event to log the burning of governance tokens
    emit GovernanceTokensBurned(sender, governanceTokensToBurn);
    
    // Return true to indicate the operation was successful
    return true;
}

    // Helper function to find the index of the stable token in the pool
    function getStableTokenIndex() internal view returns (uint256) {
        IERC20[] memory tokens = _vault.getPoolTokens(address(this));
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == stableToken) {
                return i;
            }
        }
        revert("Stable token not found in pool");
    }

    // Function for users to stake their governance tokens
    function stake(uint256 amount, uint64 votedGovernancePercentage, uint64 votedMajorityThreshold) external {
        require(amount > 0, "Amount must be > 0");
        require(votedGovernancePercentage <= 100e16 || votedGovernancePercentage == NOT_VOTING, "Invalid percentage");
        require(votedMajorityThreshold <= 100e16 || votedMajorityThreshold == NOT_VOTING, "Invalid threshold");
        
        // Transfer governance tokens from user to contract
        require(governanceToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update the user's vote
        updateVote(msg.sender, votedGovernancePercentage, votedMajorityThreshold);
        
        // Update stake amounts
        stakes[msg.sender].amount += amount;
        totalStaked += amount;
        
        // Add new staker to the list if this is their first stake
        if (stakes[msg.sender].amount == amount) {
            stakers.push(msg.sender);
        }
        
        emit Staked(msg.sender, amount, votedGovernancePercentage, votedMajorityThreshold);
    }

function unstake() external {
    uint256 amount = stakes[msg.sender].amount;
    require(amount > 0, "No stake to unstake");
    
    // Update total staked amount
    totalStaked -= amount;
    
    // Remove staker from the stakers array
    for (uint256 i = 0; i < stakers.length; i++) {
        if (stakers[i] == msg.sender) {
            stakers[i] = stakers[stakers.length - 1];
            stakers.pop();
            break;
        }
    }
    
    // Delete the user's stake entirely
    delete stakes[msg.sender];
    
    // Return governance tokens to user
    require(governanceToken.transfer(msg.sender, amount), "Transfer failed");
    emit Unstaked(msg.sender, amount);
}

    // Function to update a user's vote
    function updateVote(address user, uint64 newGovernancePercentage, uint64 newMajorityThreshold) public {
        require(newGovernancePercentage <= 100e16 || newGovernancePercentage == NOT_VOTING, "Invalid percentage");
        require(newMajorityThreshold <= 100e16 || newMajorityThreshold == NOT_VOTING, "Invalid threshold");
        Stake storage userStake = stakes[user];
        
        userStake.votedGovernancePercentage = newGovernancePercentage;
        userStake.votedMajorityThreshold = newMajorityThreshold;
        
        emit VoteChanged(user, newGovernancePercentage, newMajorityThreshold);
    }

    // Function to execute governance updates if voting thresholds are met
    function executeGovernanceUpdate() external {
        require(totalStaked > 0, "No stakes");
        uint256 currentMajorityThreshold = (totalStaked * majorityThreshold) / 100e16;
        
        bool updated = false;
        
        // Calculate votes for governance percentage and majority threshold
        uint256[101] memory governancePercentageVotes;
        uint256[101] memory majorityThresholdVotes;
        
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            Stake memory userStake = stakes[staker];
            
            if (userStake.votedGovernancePercentage != NOT_VOTING) {
                governancePercentageVotes[userStake.votedGovernancePercentage] += userStake.amount;
            }
            if (userStake.votedMajorityThreshold != NOT_VOTING) {
                majorityThresholdVotes[userStake.votedMajorityThreshold] += userStake.amount;
            }
        }
        
        // Update governance token percentage if threshold is met
        uint256 maxGovernancePercentageVotes = 0;
        uint64 newGovernancePercentage = governanceTokenPercentage;
        for (uint256 i = 0; i < governancePercentageVotes.length; i++) {
            uint256 votes = governancePercentageVotes[i];
            if (votes > maxGovernancePercentageVotes && votes > currentMajorityThreshold) {
                maxGovernancePercentageVotes = votes;
                newGovernancePercentage = uint64(i);
            }
        }
        if (newGovernancePercentage != governanceTokenPercentage) {
            governanceTokenPercentage = newGovernancePercentage;
            emit GovernanceTokenPercentageUpdated(newGovernancePercentage);
            updated = true;
        }
        
        // Update majority threshold if threshold is met
        uint256 maxMajorityThresholdVotes = 0;
        uint64 newMajorityThreshold = majorityThreshold;
        for (uint256 i = 0; i < majorityThresholdVotes.length; i++) {
            uint256 votes = majorityThresholdVotes[i];
            if (votes > maxMajorityThresholdVotes && votes > currentMajorityThreshold) {
                maxMajorityThresholdVotes = votes;
                newMajorityThreshold = uint64(i);
            }
        }
        if (newMajorityThreshold != majorityThreshold) {
            majorityThreshold = newMajorityThreshold;
            emit MajorityThresholdUpdated(newMajorityThreshold);
            updated = true;
        }

        // If any updates occurred, return staked tokens to users
        if (updated) {
            returnStakedTokens();
        }
    }

    // Internal function to return staked tokens to all users after a governance update
    function returnStakedTokens() internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 amount = stakes[staker].amount;
            if (amount > 0) {
                // Transfer tokens back to user
                require(governanceToken.transfer(staker, amount), "Transfer failed");
                emit Unstaked(staker, amount);
                
                // Delete the stake
                delete stakes[staker];
                
                // Remove staker from the array
                stakers[i] = stakers[stakers.length - 1];
                stakers.pop();
                i--; // Adjust index since we've removed an element
            }
        }
        // Reset total staked amount
        totalStaked = 0;
    }

   function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallBeforeRemoveLiquidity = true;
        return hookFlags;
    }
}
