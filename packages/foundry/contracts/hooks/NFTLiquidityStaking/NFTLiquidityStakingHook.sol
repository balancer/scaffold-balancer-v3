// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IPoolInfo } from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { INFTLiquidityStakingHook } from "./Interfaces/INFTLiquidityStakingHook.sol";
import "./NFTMetadata.sol";
import "./NFTGovernor.sol";
import "./RewardToken.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract NFTLiquidityStakingHook is
    INFTLiquidityStakingHook,
    IHooks,
    BaseHooks,
    ERC721,
    Ownable,
    VaultGuard,
    ReentrancyGuard,
    IVotes
{
    NFTGovernor public governor;
    RewardToken public rewardToken;
    uint256 public constant REWARD_RATE = 1e18;

    mapping(address => mapping(address => StakingInfo)) private _stakingInfoMap;
    mapping(address => mapping(address => uint256)) public lastUnstakeTime;
    mapping(uint256 => address) private _tokenIdToPool;
    uint256 private _tokenIdCounter;

    mapping(uint256 => uint256) public nftTierToFeeDiscount;
    mapping(uint256 => uint256) public nftTierToVotingPower;
    mapping(uint256 => uint256) public nftTierToYieldBoost;
    mapping(uint256 => mapping(address => uint256)) private _votePowerCheckpoints;
    mapping(uint256 => uint256) private _totalSupplyCheckpoints;
    uint256 private _currentCheckpoint;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(address => uint256) private _ownedTokensCount;

    uint256 public constant COOLDOWN_PERIOD = 7 days;
    uint256 public constant UPGRADE_COOLDOWN_PERIOD = 7 days;

    uint256 public constant BRONZE_TIER_THRESHOLD = 30 days;
    uint256 public constant SILVER_TIER_THRESHOLD = 90 days;
    uint256 public constant GOLD_TIER_THRESHOLD = 180 days;

    uint256 public constant BRONZE_TIER_AMOUNT = 1000 ether;
    uint256 public constant SILVER_TIER_AMOUNT = 5000 ether;
    uint256 public constant GOLD_TIER_AMOUNT = 10000 ether;

    NFTMetadata public nftMetadata;

    event NFTUpgraded(address indexed user, address indexed pool, uint256 tokenId, uint256 newTier);
    event LiquidityAdded(address indexed user, address indexed pool, uint256 amount);
    event RewardsClaimed(address indexed user, address indexed pool, uint256 amount);
    constructor(
        IVault vaultInstance,
        address _factoryAddress,
        string memory name,
        string memory symbol,
        address _nftMetadata
    ) VaultGuard(vaultInstance) ERC721(name, symbol) Ownable(msg.sender) {
        nftMetadata = NFTMetadata(_nftMetadata);
        rewardToken = new RewardToken(address(this));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address owner = ownerOf(tokenId);
        address pool = _tokenIdToPool[tokenId];
        StakingInfo memory info = _stakingInfoMap[owner][pool];
        return nftMetadata.tokenURI(tokenId, info.currentTier);
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override(BaseHooks, IHooks) returns (bool) {
        return IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    function setGovernor(address _governor) external onlyOwner {
        governor = NFTGovernor(payable(_governor));
    }
    function stakingInfo(
        address user,
        address pool
    )
        external
        view
        override
        returns (
            uint256 stakedAmount,
            uint256 stakingStartTime,
            uint256 lastMilestoneTime,
            uint256 currentTier,
            uint256 lastRewardClaim
        )
    {
        StakingInfo memory info = _stakingInfoMap[user][pool];
        return (
            info.stakedAmount,
            info.stakingStartTime,
            info.lastMilestoneTime,
            info.currentTier,
            info.lastRewardClaim
        );
    }

    function setFeeDiscounts(uint256[] memory tiers, uint256[] memory discounts) external onlyOwner {
        require(tiers.length == discounts.length, "Arrays must have the same length");
        for (uint256 i = 0; i < tiers.length; i++) {
            nftTierToFeeDiscount[tiers[i]] = discounts[i];
        }
    }
    function getVotes(address account) public view returns (uint256) {
        uint256 totalVotingPower = 0;
        uint256 tokenId = 1;
        while (tokenId <= _tokenIdCounter) {
            try this.ownerOf(tokenId) returns (address owner) {
                if (owner == account) {
                    address pool = _tokenIdToPool[tokenId];
                    totalVotingPower += getVotingPower(account, pool);
                }
            } catch {
                // Token doesn't exist, continue to next token
            }
            tokenId++;
        }
        return totalVotingPower;
    }
    function claimRewards(address pool) external nonReentrant {
        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[msg.sender][pool];
        require(user_stakingInfoMap.stakedAmount > 0, "No staking position");

        uint256 rewards = calculateRewards(msg.sender, pool);
        user_stakingInfoMap.lastRewardClaim = block.timestamp;

        rewardToken.mint(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, pool, rewards);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _ownedTokensCount[owner], "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function _mintNFT(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownedTokensCount[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensCount[to]++;
    }
    function _updateVotePower(address account, uint256 newPower) internal {
        _currentCheckpoint++;
        _votePowerCheckpoints[_currentCheckpoint][account] = newPower;
        _totalSupplyCheckpoints[_currentCheckpoint] =
            _totalSupplyCheckpoints[_currentCheckpoint - 1] +
            newPower -
            _votePowerCheckpoints[_currentCheckpoint - 1][account];
    }

    function calculateRewards(address user, address pool) public view returns (uint256) {
        StakingInfo memory user_stakingInfoMap = _stakingInfoMap[user][pool];
        uint256 timeElapsed = block.timestamp - user_stakingInfoMap.lastRewardClaim;
        uint256 yieldBoost = getYieldBoost(user, pool);
        return ((user_stakingInfoMap.stakedAmount * timeElapsed * REWARD_RATE * (100 + yieldBoost)) / 100) / 1e18;
    }

    function setVotingPowers(uint256[] memory tiers, uint256[] memory votingPowers) external onlyOwner {
        require(tiers.length == votingPowers.length, "Arrays must have the same length");
        for (uint256 i = 0; i < tiers.length; i++) {
            nftTierToVotingPower[tiers[i]] = votingPowers[i];
        }
    }

    function setYieldBoosts(uint256[] memory tiers, uint256[] memory boosts) external onlyOwner {
        require(tiers.length == boosts.length, "Arrays must have the same length");
        for (uint256 i = 0; i < tiers.length; i++) {
            nftTierToYieldBoost[tiers[i]] = boosts[i];
        }
    }
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = RewardToken(_rewardToken);
    }

    function getFeeDiscount(address user, address pool) public view returns (uint256) {
        StakingInfo memory user_stakingInfoMap = _stakingInfoMap[user][pool];
        return nftTierToFeeDiscount[user_stakingInfoMap.currentTier];
    }
    function getFeeDiscounts() public view returns (uint256[] memory tiers, uint256[] memory discounts) {
        tiers = new uint256[](4);
        discounts = new uint256[](4);

        tiers[0] = 0;
        tiers[1] = 1;
        tiers[2] = 2;
        tiers[3] = 3;

        discounts[0] = nftTierToFeeDiscount[0];
        discounts[1] = nftTierToFeeDiscount[1];
        discounts[2] = nftTierToFeeDiscount[2];
        discounts[3] = nftTierToFeeDiscount[3];

        return (tiers, discounts);
    }

    function getVotingPower(address user, address pool) public view returns (uint256) {
        StakingInfo memory user_stakingInfoMap = _stakingInfoMap[user][pool];
        return nftTierToVotingPower[user_stakingInfoMap.currentTier];
    }

    function getYieldBoost(address user, address pool) public view returns (uint256) {
        StakingInfo memory user_stakingInfoMap = _stakingInfoMap[user][pool];
        return nftTierToYieldBoost[user_stakingInfoMap.currentTier];
    }
    /// @inheritdoc IHooks
    function getHookFlags() public pure override(BaseHooks, IHooks) returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
    }

    function onAfterAddLiquidity(
        address router,
        uint256[] memory amountsInScaled18,
        uint256 bptAmountOut,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success) {
        address user = router;
        address pool = msg.sender;

        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[user][pool];

        if (user_stakingInfoMap.stakedAmount == 0) {
            user_stakingInfoMap.stakingStartTime = block.timestamp;
            user_stakingInfoMap.lastMilestoneTime = block.timestamp;
            user_stakingInfoMap.lastRewardClaim = block.timestamp;
        }

        user_stakingInfoMap.stakedAmount += bptAmountOut;

        _checkAndMintNFT(user, pool);
        _updateVotePower(user, getVotingPower(user, pool));

        emit LiquidityAdded(user, pool, bptAmountOut);

        return true;
    }
    function _checkAndMintNFT(address user, address pool) internal {
        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[user][pool];
        uint256 stakingDuration = block.timestamp - user_stakingInfoMap.lastMilestoneTime;
        uint256 newTier = _calculateTier(user_stakingInfoMap.stakedAmount, stakingDuration);

        if (newTier > user_stakingInfoMap.currentTier) {
            uint256 newTokenId = _tokenIdCounter++;
            _mintNFT(user, newTokenId);
            _tokenIdToPool[newTokenId] = pool;

            user_stakingInfoMap.lastMilestoneTime = block.timestamp;
            user_stakingInfoMap.currentTier = newTier;

            emit NFTMinted(user, pool, newTokenId, newTier);
        }
    }

    function onAfterRemoveLiquidity(
        address router,
        uint256[] memory amountsOutScaled18,
        uint256 bptAmountIn,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success) {
        address user = router;
        address pool = msg.sender;

        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[user][pool];

        require(user_stakingInfoMap.stakedAmount >= bptAmountIn, "Insufficient staked amount");
        require(block.timestamp >= lastUnstakeTime[user][pool] + COOLDOWN_PERIOD, "Cooldown period not over");

        user_stakingInfoMap.stakedAmount -= bptAmountIn;
        lastUnstakeTime[user][pool] = block.timestamp;

        if (user_stakingInfoMap.stakedAmount == 0) {
            delete _stakingInfoMap[user][pool];
        } else {
            _adjustTier(user, pool);
        }
        uint256 rewards = calculateRewards(user, pool);
        if (rewards > 0) {
            rewardToken.mint(user, rewards);
            emit RewardsClaimed(user, pool, rewards);
        }
        emit LiquidityRemoved(user, pool, bptAmountIn);
        _updateVotePower(user, getVotingPower(user, pool));
        return true;
    }

    function _calculateTier(uint256 stakedAmount, uint256 stakingDuration) internal pure returns (uint256) {
        if (stakingDuration >= GOLD_TIER_THRESHOLD && stakedAmount >= GOLD_TIER_AMOUNT) {
            return 3;
        } else if (stakingDuration >= SILVER_TIER_THRESHOLD && stakedAmount >= SILVER_TIER_AMOUNT) {
            return 2;
        } else if (stakingDuration >= BRONZE_TIER_THRESHOLD && stakedAmount >= BRONZE_TIER_AMOUNT) {
            return 1;
        } else {
            return 0;
        }
    }
    function _adjustTier(address user, address pool) internal {
        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[user][pool];
        uint256 stakingDuration = block.timestamp - user_stakingInfoMap.stakingStartTime;
        user_stakingInfoMap.currentTier = _calculateTier(user_stakingInfoMap.stakedAmount, stakingDuration);
    }

    function getRemainingCooldownTime(address user, address pool) public view returns (uint256) {
        uint256 cooldownEndTime = lastUnstakeTime[user][pool] + COOLDOWN_PERIOD;
        if (block.timestamp >= cooldownEndTime) {
            return 0;
        }
        return cooldownEndTime - block.timestamp;
    }

    function upgradeNFT(uint256 tokenId) external nonReentrant {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not the owner of the NFT");
        require(
            block.timestamp >= lastUnstakeTime[msg.sender][_tokenIdToPool[tokenId]] + UPGRADE_COOLDOWN_PERIOD,
            "Upgrade cooldown period not over"
        );

        address pool = _tokenIdToPool[tokenId];
        StakingInfo storage user_stakingInfoMap = _stakingInfoMap[msg.sender][pool];

        uint256 newTier = _calculateTier(
            user_stakingInfoMap.stakedAmount,
            block.timestamp - user_stakingInfoMap.stakingStartTime
        );
        require(newTier > user_stakingInfoMap.currentTier, "No upgrade available");

        user_stakingInfoMap.currentTier = newTier;
        lastUnstakeTime[msg.sender][pool] = block.timestamp;

        emit NFTUpgraded(msg.sender, pool, tokenId, newTier);
    }

    function getPastTotalSupply(uint256 timepoint) external view override returns (uint256) {
        require(timepoint < block.timestamp, "ERC20Votes: future lookup");
        uint256 checkpoint = _findCheckpoint(timepoint);
        return _totalSupplyCheckpoints[checkpoint];
    }

    function getPastVotes(address account, uint256 timepoint) external view override returns (uint256) {
        require(timepoint < block.timestamp, "ERC20Votes: future lookup");
        uint256 checkpoint = _findCheckpoint(timepoint);
        return _votePowerCheckpoints[checkpoint][account];
    }

    function _findCheckpoint(uint256 timepoint) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = _currentCheckpoint;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (_totalSupplyCheckpoints[mid] > timepoint) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return low == 0 ? 0 : low - 1;
    }

    function delegates(address account) external view override returns (address) {
        return account;
    }

    function delegate(address delegatee) external override {
        // No-op, as we're using self-delegation
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // No-op, as we're using self-delegation
    }
}
