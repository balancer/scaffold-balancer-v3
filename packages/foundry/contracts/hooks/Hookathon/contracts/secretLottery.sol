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
 * @notice Hook that randomly rewards accumulated fees to a user performing a swap.
 * @dev In this example, every time a swap is executed in a pool registered with this hook, a "random" number is drawn.
 * If the drawn number is not equal to the LUCKY_NUMBER, the user will pay fees to the hook contract. But, if the
 * drawn number is equal to LUCKY_NUMBER, the user won't pay hook fees and will receive all fees accrued by the hook.
 */
contract LotteryHookExample is BaseHooks, VaultGuard, Ownable, GatewayCaller {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.IERC20ToUint256Map;
    using SafeERC20 for IERC20;

    // Trusted router is needed since we rely on `getSender` to know which user should receive the prize.
    address private immutable _trustedRouter;
    address private immutable _allowedFactory;

    mapping(address => mapping(IERC20 => euint64)) private userAddressToThereCreditValue;
    uint256 constant DIVISION_FACTOR = 10 ** 12;
    uint256 private _counter = 0;

    /**
     * @notice A new `LotteryHookExample` contract has been registered successfully for a given factory and pool.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param pool The pool on which the hook was registered
     */
    event SecretSwapHookRegistered(address indexed hooksContract, address indexed pool);

    struct CallBackStruct {
        address userAddress;
        IERC20 token1;
        IERC20 token2;
    }
    mapping(uint256 id => CallBackStruct callBackStruct) public requestIdToCallBackStruct;

    /**
     * @notice Fee collected and added to the lottery pot.
     * @dev The current user did not win the lottery.
     * @param hooksContract This contract
     * @param token The token in which the fee was collected
     * @param amount The amount of the fee collected
     */
    event TokenDeposited(address indexed hooksContract, IERC20 indexed token, uint256 amount);

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

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        uint256 operation = abi.decode(params.userData, (uint256));

        // Do Deposit
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
        // Do Withdraw
        else if (params.router == _trustedRouter && operation == 2) {
            _withdrawToken(params.router, params.tokenIn, params.tokenOut);
        } else {
            return (true, hookAdjustedAmountCalculatedRaw);
        }
    }

    // If drawnNumber == LUCKY_NUMBER, user wins the pot and pays no fees. Otherwise, the hook fee adds to the pot.
    function _depositToken(address router, IERC20 token, uint256 amount) private returns (uint256) {
        address user = IRouterCommon(router).getSender();
        if (amount > 0) {
            _vault.sendTo(token, address(this), amount);
            userAddressToThereCreditValue[user][token] = TFHE.add(
                userAddressToThereCreditValue[user][token],
                TFHE.asEuint64(amount / DIVISION_FACTOR)
            );
            TFHE.allow(userAddressToThereCreditValue[user][token], address(this));
            TFHE.allow(userAddressToThereCreditValue[user][token], owner());
            emit TokenDeposited(address(this), token, amount);
        }
        return amount;
    }

    function _withdrawToken(address router, IERC20 token1, IERC20 token2) private returns (uint256) {
        address user = IRouterCommon(router).getSender();

        euint64 token1Amount = TFHE.asEuint64(0);
        if (TFHE.isInitialized(userAddressToThereCreditValue[user][token1])) {
            token1Amount = userAddressToThereCreditValue[user][token1];
        }

        euint64 token2Amount = TFHE.asEuint64(0);
        if (TFHE.isInitialized(userAddressToThereCreditValue[user][token2])) {
            token2Amount = userAddressToThereCreditValue[user][token2];
        }

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

        userAddressToThereCreditValue[_callBackStruct.userAddress][_callBackStruct.token1] = TFHE.asEuint64(0);
        userAddressToThereCreditValue[_callBackStruct.userAddress][_callBackStruct.token2] = TFHE.asEuint64(0);

        return true;
    }

    function transferCredits(address to, IERC20 token, einput encryptedAmount, bytes calldata inputProof) public {
        euint64 amount = TFHE.asEuint64(encryptedAmount, inputProof);
        ebool canTransfer = TFHE.le(amount, userAddressToThereCreditValue[msg.sender][token]);
        _transfer(msg.sender, to, amount, canTransfer, token);
    }

    // Transfers an encrypted amount.
    function _transfer(address from, address to, euint64 amount, ebool isTransferable, IERC20 token) internal virtual {
        // Add to the balance of `to` and subract from the balance of `from`.
        euint64 transferValue = TFHE.select(isTransferable, amount, TFHE.asEuint64(0));
        euint64 newBalanceTo = TFHE.add(userAddressToThereCreditValue[to][token], transferValue);
        userAddressToThereCreditValue[to][token] = newBalanceTo;
        TFHE.allow(newBalanceTo, address(this));
        TFHE.allow(newBalanceTo, to);
        euint64 newBalanceFrom = TFHE.sub(userAddressToThereCreditValue[from][token], transferValue);
        userAddressToThereCreditValue[from][token] = newBalanceFrom;
        TFHE.allow(newBalanceFrom, address(this));
        TFHE.allow(newBalanceFrom, from);
        emit Transfer(from, to);
    }

    event Transfer(address, address);
}
