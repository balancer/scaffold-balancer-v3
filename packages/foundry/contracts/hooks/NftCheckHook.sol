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

    function nftData(uint256 tokenId) external view returns (NFTData memory);
}

contract NftCheckHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    // Changed from immutable to public
    address public nftContract;
    uint256 public nftId;

    // Error to throw when the hook doesn't own the required NFT
    error DoesNotOwnRequiredNFT(address hook, address nftContract, uint256 nftId);

    // Error to throw when the NFT's linked token doesn't match any of the pool tokens
    error LinkedTokenNotInPool(address linkedToken);

    uint64 public exitFeePercentage;
    uint64 public constant MAX_EXIT_FEE_PERCENTAGE = 10e16;

    event NftCheckHookRegistered(address indexed hooksContract, address indexed pool);
    event ExitFeeCharged(address indexed pool, IERC20 indexed token, uint256 feeAmount);
    event ExitFeePercentageChanged(address indexed hookContract, uint256 exitFeePercentage);
    event NftContractUpdated(address indexed oldContract, address indexed newContract);
    event NftIdUpdated(uint256 oldId, uint256 newId);

    error ExitFeeAboveLimit(uint256 feePercentage, uint256 limit);
    error PoolDoesNotSupportDonation();

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

        // Get the linked token from the NFT
        ICustomNFT.NFTData memory data = ICustomNFT(nftContract).nftData(nftId);
        address linkedToken = data.linkedToken;

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

        emit NftCheckHookRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
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
}
