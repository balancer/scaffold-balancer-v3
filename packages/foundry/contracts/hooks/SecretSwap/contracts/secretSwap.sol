// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "./interfaces/IHooks.sol";
import { IRouterCommon } from "./interfaces/IRouterCommon.sol";
import { IVault } from "./interfaces/IVault.sol";
import { AfterSwapParams, LiquidityManagement, SwapKind, TokenConfig, HookFlags } from "./interfaces/VaultTypes.sol";

import { EnumerableMap } from "./interfaces/EnumerableMap.sol";
import { FixedPoint } from "./interfaces/FixedPoint.sol";
import { VaultGuard } from "./interfaces/VaultGuard.sol";
import { BaseHooks } from "./interfaces/BaseHooks.sol";

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";

/**
 * @title SecretSwapHook
 * @notice This contract implements a secret swap mechanism using Balancer V3 hooks and FHE (Fully Homomorphic Encryption).
 *         Users can deposit tokens, withdraw tokens, or perform a standard swap using this hook.
 *         The operations (deposit or withdraw) are encrypted using Zama's Co-Processor model for confidential transactions.
 */
contract SecretSwapHook is BaseHooks, VaultGuard, Ownable, GatewayCaller {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.IERC20ToUint256Map;
    using SafeERC20 for IERC20;

    // Router and factory addresses for swap validation
    address private immutable _trustedRouter;
    address private immutable _allowedFactory;

    // Tracks user credit balances (encrypted using TFHE) per token
    mapping(address => mapping(IERC20 => euint64)) private userAddressToCreditValue;

    // Division factor for scaling token amounts
    uint256 constant DIVISION_FACTOR = 10 ** 12;

    /**
     * @notice Event emitted when the SecretSwapHook is registered for a pool.
     */
    event SecretSwapHookRegistered(address indexed hooksContract, address indexed pool);

    /**
     * @notice Event emitted when tokens are deposited into the contract.
     */
    event TokenDeposited(address indexed hooksContract, IERC20 indexed token, uint256 amount);

    struct CallBackStruct {
        address userAddress;
        IERC20 token1;
        IERC20 token2;
    }

    // Map request ID to callback struct for handling decryption callbacks
    mapping(uint256 id => CallBackStruct) public requestIdToCallBackStruct;

    constructor(IVault vault, address router) VaultGuard(vault) Ownable(msg.sender) {
        _trustedRouter = router;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        emit SecretSwapHookRegistered(address(this), pool);
        return true;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallAfterSwap = true;
        return hookFlags;
    }

    /**
     * @notice Called after a swap operation, this function handles deposits, withdrawals, or standard swaps
     *         based on the user's selected operation (encoded in `params.userData`).
     * @param params Swap parameters, including tokens, amounts, and user data.
     */
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        uint256 operation = abi.decode(params.userData, (uint256));

        // Handle deposit operation (1)
        if (params.router == _trustedRouter && operation == 1) {
            hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;
            uint256 amount = params.amountCalculatedRaw.mulDown(1);
            
            if (params.kind == SwapKind.EXACT_IN) {
                uint256 feeToPay = _depositToken(params.router, params.tokenOut, amount);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw -= feeToPay;
                }
            } else {
                uint256 feeToPay = _depositToken(params.router, params.tokenIn, amount);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw += feeToPay;
                }
            }
            return (true, hookAdjustedAmountCalculatedRaw);
        }
        // Handle withdrawal operation (2)
        else if (params.router == _trustedRouter && operation == 2) {
            _withdrawToken(params.router, params.tokenIn, params.tokenOut);
        } else {
            // Default case: standard swap
            return (true, hookAdjustedAmountCalculatedRaw);
        }
    }

    /**
     * @notice Handles deposit of tokens into the contract. User receives encrypted credits.
     * @param router Address of the router that initiated the swap.
     * @param token Token to be deposited.
     * @param amount Amount of the token to be deposited.
     */
    function _depositToken(address router, IERC20 token, uint256 amount) private returns (uint256) {
        address user = IRouterCommon(router).getSender();
        if (amount > 0) {
            _vault.sendTo(token, address(this), amount);
            userAddressToCreditValue[user][token] = TFHE.add(
                userAddressToCreditValue[user][token],
                TFHE.asEuint64(amount / DIVISION_FACTOR)
            );
            TFHE.allow(userAddressToCreditValue[user][token], address(this));
            TFHE.allow(userAddressToCreditValue[user][token], owner());
            emit TokenDeposited(address(this), token, amount);
        }
        return amount;
    }

    /**
     * @notice Handles token withdrawal by decrypting user's credit balance and transferring tokens.
     * @param router Address of the router that initiated the swap.
     * @param token1 First token for withdrawal.
     * @param token2 Second token for withdrawal.
     */
    function _withdrawToken(address router, IERC20 token1, IERC20 token2) private returns (uint256) {
        address user = IRouterCommon(router).getSender();

        euint64 token1Amount = TFHE.isInitialized(userAddressToCreditValue[user][token1])
            ? userAddressToCreditValue[user][token1]
            : TFHE.asEuint64(0);

        euint64 token2Amount = TFHE.isInitialized(userAddressToCreditValue[user][token2])
            ? userAddressToCreditValue[user][token2]
            : TFHE.asEuint64(0);

        TFHE.allow(token1Amount, address(this));
        TFHE.allow(token2Amount, address(this));

        uint256[] memory cts = new uint256[](2);
        cts[0] = Gateway.toUint256(token1Amount);
        cts[1] = Gateway.toUint256(token2Amount);

        uint256 requestId = Gateway.requestDecryption(
            cts,
            this.callBackResolver.selector,
            0,
            block.timestamp + 100,
            false
        );

        requestIdToCallBackStruct[requestId] = CallBackStruct(user, token1, token2);

        return 0;
    }

    /**
     * @notice Callback function after decryption to transfer tokens to user.
     * @param requestID ID of the decryption request.
     * @param _token1Amount Decrypted amount of token1.
     * @param _token2Amount Decrypted amount of token2.
     */
    function callBackResolver(
        uint256 requestID,
        uint64 _token1Amount,
        uint64 _token2Amount
    ) external onlyGateway returns (bool) {
        CallBackStruct memory _callBackStruct = requestIdToCallBackStruct[requestID];

        if (_token1Amount > 0) {
            _callBackStruct.token1.safeTransfer(_callBackStruct.userAddress, _token1Amount * DIVISION_FACTOR);
        }
        if (_token2Amount > 0) {
            _callBackStruct.token2.safeTransfer(_callBackStruct.userAddress, _token2Amount * DIVISION_FACTOR);
        }

        userAddressToCreditValue[_callBackStruct.userAddress][_callBackStruct.token1] = TFHE.asEuint64(0);
        userAddressToCreditValue[_callBackStruct.userAddress][_callBackStruct.token2] = TFHE.asEuint64(0);

        return true;
    }

    /**
     * @notice Transfer encrypted credits between users.
     * @param to Recipient address.
     * @param token Token being transferred.
     * @param encryptedAmount Encrypted amount of the token.
     * @param inputProof Proof for the transfer.
     */
    function transferCredits(address to, IERC20 token, einput encryptedAmount, bytes calldata inputProof) public {
        euint64 amount = TFHE.asEuint64(encryptedAmount, inputProof);
        ebool canTransfer = TFHE.le(amount, userAddressToCreditValue[msg.sender][token]);
        _transfer(msg.sender, to, amount, canTransfer, token);
    }

    /**
     * @notice Internal function for transferring encrypted credits between users.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Encrypted amount.
     * @param isTransferable Boolean indicating if the transfer is allowed.
     * @param token Token being transferred.
     */
    function _transfer(address from, address to, euint64 amount, ebool isTransferable, IERC20 token) internal virtual {
        euint64 transferValue = TFHE.select(isTransferable, amount, TFHE.asEuint64(0));
        euint64 newBalanceTo = TFHE.add(userAddressToCreditValue[to][token], transferValue);
        userAddressToCreditValue[to][token] = newBalanceTo;

        TFHE.allow(newBalanceTo, address(this));
        TFHE.allow(newBalanceTo, to);

        euint64 newBalanceFrom = TFHE.sub(userAddressToCreditValue[from][token], transferValue);
        userAddressToCreditValue[from][token] = newBalanceFrom;

        TFHE.allow(newBalanceFrom, address(this));
        TFHE.allow(newBalanceFrom, from);

        emit Transfer(from, to);
    }

    // Event emitted when credits are transferred
    event Transfer(address, address);
}
