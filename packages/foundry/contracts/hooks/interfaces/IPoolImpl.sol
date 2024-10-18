// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "./IERC4626.sol";

interface IPoolImpl is IERC20, IERC4626 {
    error ErrZeroValue();
    error ErrMaxDepositExceeded();
    error ErrMaxMintExceeded();
    error ErrRequiredWithdrawRequest();
    error ErrWithdrawDelayed(uint256 timestamp);
    error ErrRedeemDelayed(uint256 timestamp);
    error ErrTooBigAmount(uint256 allowedAmount);
    error ErrWithdrawRequestExpired();
    error ErrAmountExceedsAvailableAssets();
    error ErrOnlyAssetToken(address assetToken);
    error ErrInsufficientAllowance(address recipient, uint256 currentAllowance, uint256 value);
    error ErrInsufficientBalance(address sender, uint256 currentBalance, uint256 value);
    error ErrMaxInflowDropTokens(uint256);
    error ErrDepositSlippageProtection(uint256 shares, uint256 minShares);
    error ErrMintSlippageProtection(uint256 assets, uint256 maxAssets);
    error ErrWithdrawSlippageProtection(uint256 shares, uint256 maxShares);
    error ErrRedeemSlippageProtection(uint256 assets, uint256 maxAssets_);

    event LogOutflow(address token, uint256 amount, address recipient);
    event LogInflowDrop(
        uint256 sourceId,
        address sender,
        address token,
        uint256 bucketId,
        uint256 amount,
        uint256 fee,
        bool airdrop
    );
    event LogInflowDropClaimed(address erc20, address account, address recipient, uint256 amount);

    function updateAccount(address account) external;

    function accumulatedInflowDrop(address account, address erc20) external view returns (uint256);

    function pullOutflow(address erc20, uint256 amount, address recipient) external returns (uint256 transferredAmount);

    function pushAirdropAsInflowDrop(uint256 sourceId, address erc20) external;

    function pushInflowDrop(uint256 sourceId, address erc20, uint256 amount) external;

    function claimAllInflowDrops(address account, address recipient) external;

    function claimInflowDrop(address erc20, address account, address recipient) external;

    function createWithdrawRequest(uint256 assets) external returns (uint256);

    function createRedeemRequest(uint256 shares) external returns (uint256);

    function inflowDropTokenSupported(address erc20) external view returns (bool);

    function deposit(uint256 assets, address receiver, uint256 minShares) external returns (uint256);

    function mint(uint256 shares, address receiver, uint256 maxAssets) external returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxShares
    ) external returns (uint256);

    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets) external returns (uint256);

    function depositWithErc2612Permit(
        uint256 assets,
        address receiver,
        uint256 minShares,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);

    function mintWithErc2612Permit(
        uint256 shares,
        address receiver,
        uint256 maxAssets,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 assets);
}