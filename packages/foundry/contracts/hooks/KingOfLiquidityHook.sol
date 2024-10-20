// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Epoch.sol";
import {BaseHooks} from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {TokenConfig, LiquidityManagement, HookFlags, AddLiquidityKind, RemoveLiquidityKind, AfterSwapParams, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IBasePoolFactory} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {VaultGuard} from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import {IRouterCommon} from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableMap} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/EnumerableMap.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title King Of Liquidity Hook
 * @notice Tracks and rewards top liquidity providers periodically
 */
contract KingOfLiquidityHook is BaseHooks, VaultGuard, Epoch, Ownable {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.IERC20ToUint256Map;

    struct LiquidityProvider {
        uint256 totalLiquidity;
        uint256 lastUpdateTime;
        uint256 timeWeightedLiquidity;
    }

    address private immutable _allowedFactory;
    address private immutable _trustedRouter;

    uint256 public swapFeePercentage;

    EnumerableMap.IERC20ToUint256Map private _tokensWithAccruedFees;

    mapping(address user => mapping(uint256 epoch => LiquidityProvider))
        public liquidityProviders;
    address public kingOfLiquidity;

    event FeesCollected(
        address indexed swapper,
        IERC20 indexed token,
        uint256 fee
    );
    event RewardsDistributed(
        address indexed winner,
        IERC20 indexed token,
        uint256 amount
    );
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event KingUpdated(address indexed king);

    constructor(
        IVault vault,
        address allowedFactory,
        address trustedRouter,
        uint256 hookSwapFeePercentage
    ) VaultGuard(vault) Ownable(msg.sender) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        swapFeePercentage = hookSwapFeePercentage;
    }

    // Return true to allow pool registration or false to revert
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public view override returns (bool) {
        // Only pools deployed by an allowed factory may use this hook
        return
            factory == _allowedFactory &&
            IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    // Return HookFlags struct that indicates which hooks this contract supports
    function getHookFlags()
        public
        pure
        override
        returns (HookFlags memory hookFlags)
    {
        hookFlags.shouldCallAfterAddLiquidity = true; // Calculate user points
        hookFlags.shouldCallAfterRemoveLiquidity = true; // Calculate user points
        hookFlags.shouldCallAfterSwap = true; // Collect fees for rewards
    }

    // Balancer hook function
    function onAfterAddLiquidity(
        address router,
        address /*_pool*/,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256 bptAmountOut,
        uint256[] memory,
        bytes memory
    )
        public
        override
        returns (bool success, uint256[] memory hookAdjustedAmountsInRaw)
    {
        // If the router is not trusted, do not count user contribution
        if (router != _trustedRouter) {
            return (true, amountsInRaw);
        }

        _tryRewardAndStartNewEpoch();
        _updateLiquidityProvider(router, bptAmountOut, true);

        return (true, amountsInRaw);
    }

    // Balancer hook function
    function onAfterRemoveLiquidity(
        address router,
        address /*_pool*/,
        RemoveLiquidityKind,
        uint256 bptAmountIn,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        bytes memory /*userData*/
    )
        public
        override
        returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw)
    {
        // If the router is not trusted, do not count user contribution
        if (router != _trustedRouter) {
            return (true, hookAdjustedAmountsOutRaw);
        }

        _tryRewardAndStartNewEpoch();
        _updateLiquidityProvider(router, bptAmountIn, false);

        return (true, hookAdjustedAmountsOutRaw);
    }

    // Balancer hook function
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool, uint256) {
        // If the router is not trusted or swap fee not configured, do not use custom logic
        if (params.router != _trustedRouter || swapFeePercentage <= 0) {
            return (true, params.amountCalculatedRaw);
        }

        _tryRewardAndStartNewEpoch();

        uint256 hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;
        uint256 fee = hookAdjustedAmountCalculatedRaw.mulDown(
            swapFeePercentage
        );

        if (params.kind == SwapKind.EXACT_IN) {
            // For EXACT_IN swaps, the `amountCalculated` is the amount of `tokenOut`. The fee must be taken
            // from `amountCalculated`, so we decrease the amount of tokens the Vault will send to the caller.
            //
            // The preceding swap operation has already credited the original `amountCalculated`. Since we're
            // returning `amountCalculated - feeToPay` here, it will only register debt for that reduced amount
            // on settlement. This call to `sendTo` pulls `feeToPay` tokens of `tokenOut` from the Vault to this
            // contract, and registers the additional debt, so that the total debits match the credits and
            // settlement succeeds.
            bool paidTheFee = _collectSwapFee(
                params.router,
                params.tokenOut,
                fee
            );
            if (paidTheFee) {
                hookAdjustedAmountCalculatedRaw -= fee;
            }
        } else {
            // For EXACT_OUT swaps, the `amountCalculated` is the amount of `tokenIn`. The fee must be taken
            // from `amountCalculated`, so we increase the amount of tokens the Vault will ask from the user.
            //
            // The preceding swap operation has already registered debt for the original `amountCalculated`.
            // Since we're returning `amountCalculated + feeToPay` here, it will supply credit for that increased
            // amount on settlement. This call to `sendTo` pulls `feeToPay` tokens of `tokenIn` from the Vault to
            // this contract, and registers the additional debt, so that the total debits match the credits and
            // settlement succeeds.
            bool paidTheFee = _collectSwapFee(
                params.router,
                params.tokenIn,
                fee
            );
            if (paidTheFee) {
                hookAdjustedAmountCalculatedRaw += fee;
            }
        }

        return (true, hookAdjustedAmountCalculatedRaw);
    }

    function _collectSwapFee(
        address router,
        IERC20 token,
        uint256 fee
    ) private returns (bool) {
        if (fee > 0) {
            // Collect fees from the vault, the user will pay them when the Router settles the swap
            _vault.sendTo(token, address(this), fee);
            emit FeesCollected(IRouterCommon(router).getSender(), token, fee);
            return true;
        }
        return false;
    }

    function _updateLiquidityProvider(
        address router,
        uint256 amount,
        bool isAdding
    ) internal {
        uint256 epoch = getCurrentEpoch();

        address provider = IRouterCommon(router).getSender();
        LiquidityProvider storage lp = liquidityProviders[provider][epoch];

        if (lp.lastUpdateTime == 0) {
            lp.lastUpdateTime = block.timestamp;
        } else {
            _updateTimeWeightedLiquidity(lp);
        }

        if (isAdding) {
            lp.totalLiquidity += amount;
            emit LiquidityAdded(provider, amount);
        } else {
            lp.totalLiquidity = lp.totalLiquidity > amount
                ? lp.totalLiquidity - amount
                : 0;
            emit LiquidityRemoved(provider, amount);
        }

        _updateKingOfLp(provider, epoch, lp);
    }

    function _updateTimeWeightedLiquidity(
        LiquidityProvider storage lp
    ) internal {
        uint256 timePassed = block.timestamp - lp.lastUpdateTime;

        if (timePassed > 0) {
            lp.timeWeightedLiquidity += lp.totalLiquidity * timePassed;
            lp.lastUpdateTime = block.timestamp;
        }
    }

    function _updateKingOfLp(
        address sender,
        uint256 epoch,
        LiquidityProvider memory lp
    ) internal {
        if (kingOfLiquidity != address(0)) {
            LiquidityProvider storage kingLP = liquidityProviders[
                kingOfLiquidity
            ][epoch];

            _updateTimeWeightedLiquidity(kingLP); // making sure the old king has up to date values to compare

            if (lp.timeWeightedLiquidity > kingLP.timeWeightedLiquidity) {
                kingOfLiquidity = sender;
                emit KingUpdated(sender);
            }
        } else {
            kingOfLiquidity = sender;
            emit KingUpdated(sender);
        }
    }

    function _tryRewardAndStartNewEpoch() internal {
        if (!isNewEpoch()) return;

        _distributeRewards();

        delete kingOfLiquidity;
        emit KingUpdated(address(0));

        startNewEpoch();
    }

    function _distributeRewards() internal {
        if (kingOfLiquidity == address(0)) {
            return;
        }

        // Iterating backwards is more efficient, since the last element is removed from the map on each iteration.
        for (uint256 i = _tokensWithAccruedFees.size; i > 0; i--) {
            (IERC20 feeToken, ) = _tokensWithAccruedFees.at(i - 1);
            _tokensWithAccruedFees.remove(feeToken);

            uint256 amount = feeToken.balanceOf(address(this));

            if (amount > 0) {
                feeToken.safeTransfer(kingOfLiquidity, amount);
                emit RewardsDistributed(kingOfLiquidity, feeToken, amount);
            }
        }
    }

    function getProviderInfo(
        address providerAddress
    ) public view returns (uint256, uint256) {
        return getProviderInfo(providerAddress, getCurrentEpoch());
    }

    function getProviderInfo(
        address providerAddress,
        uint256 epoch
    ) public view returns (uint256, uint256) {
        LiquidityProvider memory provider = liquidityProviders[providerAddress][
            epoch
        ];
        return (provider.totalLiquidity, provider.timeWeightedLiquidity);
    }
}
