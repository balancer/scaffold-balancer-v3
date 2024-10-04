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

// Interface for ERC721 NFT contract
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// Interface for the custom NFT contract
interface ICustomNFT is IERC721 {
    struct NFTData {
        string status;
        address linkedToken;
        string[] linkedTokenInterfaces;
        bool locked;
        bool paused;
    }

    function getNftData(uint256 tokenId) external view returns (NFTData memory);
}

contract NftCheckHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    address public nftContract;
    uint256 public nftId;
    address public firstDepositor;
    uint256 public initialToken1Amount;
    uint256 public initialToken2Amount;
    uint256 public redeemRatio;
    address public poolAddress;

    uint64 public exitFeePercentage;
    uint64 public constant MAX_EXIT_FEE_PERCENTAGE = 10e16;

    error DoesNotOwnRequiredNFT(address hook, address nftContract, uint256 nftId);
    error LinkedTokenNotInPool(address linkedToken);
    error InsufficientLiquidityToRemove(address user, uint256 currentAmount, uint256 initialAmount);
    error InsufficientStableForSettlement(uint256 required, uint256 available);
    error ExitFeeAboveLimit(uint256 feePercentage, uint256 limit);
    error PoolDoesNotSupportDonation();

    event NftCheckHookRegistered(address indexed hooksContract, address indexed pool);
    event ExitFeeCharged(address indexed pool, IERC20 indexed token, uint256 feeAmount);
    event ExitFeePercentageChanged(address indexed hookContract, uint256 exitFeePercentage);
    event NftContractUpdated(address indexed oldContract, address indexed newContract);
    event NftIdUpdated(uint256 oldId, uint256 newId);
    event InitialLiquidityRecorded(address indexed user, uint256 token1Amount, uint256 token2Amount);
    event LiquiditySettled(uint256 totalEscrowedAmount, address indexed originalDepositor);
    event Redeemed(address indexed user, uint256 poolTokenAmount, uint256 stableTokenAmount);

    constructor(IVault vault, address _nftContract, uint256 _nftId) VaultGuard(vault) Ownable(msg.sender) {
        nftContract = _nftContract;
        nftId = _nftId;
    }

    function onRegister(
        address,
        address pool,
        TokenConfig[] memory tokenConfigs,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        if (liquidityManagement.enableDonation == false) {
            revert PoolDoesNotSupportDonation();
        }

        // Check if the hook owns the required NFT
        if (IERC721(nftContract).ownerOf(nftId) != address(this)) {
            revert DoesNotOwnRequiredNFT(address(this), nftContract, nftId);
        }

        // save pool address for later use
        poolAddress = pool;

        // Get the linked token from the NFT - this requires the NFT
        address linkedToken = ICustomNFT(nftContract).getNftData(nftId).linkedToken;

        // Check if the linked token is one of the pool tokens
        bool linkedTokenFound = false;
        for (uint256 i = 0; i < tokenConfigs.length; i++) {
            if (address(tokenConfigs[i].token) == address(linkedToken)) {
                linkedTokenFound = true;
                break;
            }
        }

        if (!linkedTokenFound) {
            revert LinkedTokenNotInPool(linkedToken);
        }
        
        // Record the initial liquidity amounts for use in limiting the position from the depositor prematurely
        recordInitialLiquidity(tokenConfigs[0].token.balanceOf(pool), tokenConfigs[1].token.balanceOf(pool));

        emit NftCheckHookRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address,
        address pool,
        RemoveLiquidityKind kind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool, uint256[] memory hookAdjustedAmountsOutRaw) {
        
        // Ensure the first depositor has the same amount of both tokens after removal (no rug pulling allowed)
        if (msg.sender == firstDepositor) {
            IERC20[] memory poolTokens = _vault.getPoolTokens(pool);

            uint256 currentToken1Amount = poolTokens[0].balanceOf(msg.sender);
            uint256 currentToken2Amount = poolTokens[1].balanceOf(msg.sender);

            if (currentToken1Amount < initialToken1Amount) {
                revert InsufficientLiquidityToRemove(msg.sender, currentToken1Amount, initialToken1Amount);
            }
            if (currentToken2Amount < initialToken2Amount) {
                revert InsufficientLiquidityToRemove(msg.sender, currentToken2Amount, initialToken2Amount);
            }
        }

        // Our current architecture only supports fees on tokens. Since we must always respect exact `amountsOut`, and
        // non-proportional remove liquidity operations would require taking fees in BPT, we only support proportional
        // removeLiquidity.
        if (kind != RemoveLiquidityKind.PROPORTIONAL) {
            // Returning false will make the transaction revert, so the second argument does not matter.
            return (false, amountsOutRaw);
        }

        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256[] memory accruedFees = new uint256[](tokens.length);
        hookAdjustedAmountsOutRaw = amountsOutRaw;

        if (exitFeePercentage > 0) {
            // Charge fees proportional to the `amountOut` of each token.
            for (uint256 i = 0; i < amountsOutRaw.length; i++) {
                uint256 exitFee = amountsOutRaw[i].mulDown(exitFeePercentage);
                accruedFees[i] = exitFee;
                hookAdjustedAmountsOutRaw[i] -= exitFee;

                emit ExitFeeCharged(pool, tokens[i], exitFee);
                // Fees don't need to be transferred to the hook, because donation will redeposit them in the Vault.
                // In effect, we will transfer a reduced amount of tokensOut to the caller, and leave the remainder
                // in the pool balance.
            }

            // Donates accrued fees back to LPs
            _vault.addLiquidity(
                AddLiquidityParams({
                    pool: pool,
                    to: msg.sender, // It would mint BPTs to router, but it's a donation so no BPT is minted
                    maxAmountsIn: accruedFees, // Donate all accrued fees back to the pool (i.e. to the LPs)
                    minBptAmountOut: 0, // Donation does not return BPTs, any number above 0 will revert
                    kind: AddLiquidityKind.DONATION,
                    userData: bytes("") // User data is not used by donation, so we can set it to an empty string
                })
            );
        }

        return (true, hookAdjustedAmountsOutRaw);
    }

    // Permissioned functions

    /**
     * @notice Sets the hook remove liquidity fee percentage, charged on every remove liquidity operation.
     * @dev This function must be permissioned.
     */
    function setExitFeePercentage(uint64 newExitFeePercentage) external onlyOwner {
        if (newExitFeePercentage > MAX_EXIT_FEE_PERCENTAGE) {
            revert ExitFeeAboveLimit(newExitFeePercentage, MAX_EXIT_FEE_PERCENTAGE);
        }
        exitFeePercentage = newExitFeePercentage;

        emit ExitFeePercentageChanged(address(this), newExitFeePercentage);
    }

    // New function to update nftContract
    function setNftContract(address _newNftContract) external onlyOwner {
        address oldContract = nftContract;
        nftContract = _newNftContract;
        emit NftContractUpdated(oldContract, _newNftContract);
    }

    // New function to update nftId
    function setNftId(uint256 _newNftId) external onlyOwner {
        uint256 oldId = nftId;
        nftId = _newNftId;
        emit NftIdUpdated(oldId, _newNftId);
    }

    function recordInitialLiquidity(uint256 token1Amount, uint256 token2Amount) public onlyVault {
        require(firstDepositor == address(0), "Initial liquidity already recorded");
        firstDepositor = msg.sender;
        initialToken1Amount = token1Amount;
        initialToken2Amount = token2Amount;
        emit InitialLiquidityRecorded(msg.sender, token1Amount, token2Amount);
    }

    /**
    * @notice Allows the contract owner to settle and release the NFT to the original depositor.
    * @dev This function calculates outstanding shares and deposits the equivalent stable token amount in escrow.
    */
    function settle() external onlyOwner {
        require(firstDepositor != address(0), "Initial liquidity not recorded");
        require(firstDepositor != msg.sender, "Initial depositor is only one that can settle");

        // Calculate total outstanding shares in the pool
        IERC20 poolToken = IERC20(address(_vault.getPoolTokens(poolAddress)[0])); // Assuming the first token is the asset token
        IERC20 stableToken = IERC20(address(_vault.getPoolTokens(poolAddress)[1])); // Assuming the first token is the asset token
        uint256 totalSupply = poolToken.totalSupply();
        uint256 poolBalance = poolToken.balanceOf(address(this)) + poolToken.balanceOf(firstDepositor);
        uint256 outstandingShares = totalSupply - poolBalance;

        // Calculate the equivalent stable token amount using the current pool/stable ratio
        uint256 poolTokenBalance = poolToken.balanceOf(address(this));
        uint256 stableTokenBalance = stableToken.balanceOf(address(this));
        uint256 stablePoolRatio = poolTokenBalance / stableTokenBalance;
        // Ensure the stable pool ratio is not below what the initial price of asset was, which was 1:1
        // will need to refactor for 80/20 pools
        redeemRatio = stablePoolRatio > 1 ? stablePoolRatio : 1;

        // how much stable tokens are required to settle the outstanding shares
        uint256 stableAmountRequired = outstandingShares * redeemRatio;

        // Check if the contract holds enough stable tokens for settlement
        if (IERC20(stableToken).balanceOf(msg.sender) < stableAmountRequired) {
            revert InsufficientStableForSettlement(stableAmountRequired, IERC20(stableToken).balanceOf(msg.sender));
        }

        // Transfer the stableAmountRequired from the msg.sender to the hook contract
        IERC20(stableToken).transferFrom(msg.sender, address(this), stableAmountRequired);
        
        // Release the NFT back to the original depositor
        IERC721(nftContract).transferFrom(address(this), firstDepositor, nftId);
        
        // Remove the initial liquidity from the pool
        // _vault.removeLiquidity(
        //     poolAddress
        //     firstDepositor,
        //     initialToken1Amount,
        //     initialToken2Amount,
        //     0, // minBptAmountOut is set to 0 to allow the removal of all initial liquidity
        //     bytes("") // userData is not used in this context
        // );

        emit LiquiditySettled(stableAmountRequired, firstDepositor);
    }

    /**
    * @notice Allows users with linked tokens to redeem their tokens for the stable token in escrow.
    */
    function redeem() external {
        IERC20 poolToken = IERC20(address(_vault.getPoolTokens(poolAddress)[0])); // Assuming the first token is the asset token
        IERC20 stableToken = IERC20(address(_vault.getPoolTokens(poolAddress)[1]));
        uint256 redeemableBalance = poolToken.balanceOf(msg.sender);
        require(redeemableBalance > 0, "Sender has no redeemable tokens");

        // Calculate the stable token amount to be transferred based on the ratio
        uint256 stableAmountToTransfer = redeemableBalance * redeemRatio;

        // Transfer the stable tokens to the user
        IERC20(stableToken).transfer(msg.sender, stableAmountToTransfer);

        emit Redeemed(msg.sender, redeemableBalance, stableAmountToTransfer);
    }

}