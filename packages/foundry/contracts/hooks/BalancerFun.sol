// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AfterSwapParams,
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    RemoveLiquidityKind,
    HookFlags,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

/**
 * @title BalancerFun Hook Contract
 * @notice Implements custom hooks for Balancer V3 liquidity pools to enforce swap limits and prevent liquidity removal.
 */
contract BalancerFun is BaseHooks, VaultGuard {
    /// @notice The token that is managed by this hook.
    IERC20 public immutable token;

    /// @notice The maximum amount that can be swapped in a single block.
    uint public immutable maxSwapAmount;

    /// @notice A mapping that tracks the total amount of tokens sold per block.
    mapping(uint => uint) public blockToTotalSold;

    /// @notice Event emitted when the BalancerFun hook is registered.
    /// @param hooksContract The address of the hooks contract.
    /// @param pool The address of the pool where the hook is registered.
    event BalancerFunHookRegistered(address indexed hooksContract, address indexed pool);

    /// @notice Error thrown when a swap exceeds the maximum allowed swap amount.
    error MaximumSwapExceeded();

    /// @notice Error thrown when an attempt is made to remove liquidity, which is not allowed.
    error LiquidityIsLocked();

    /**
     * @notice Constructor for the BalancerFun contract.
     * @param vault The Balancer Vault contract.
     * @param _token The ERC20 token that is managed by this hook.
     */
    constructor(IVault vault, IERC20 _token) VaultGuard(vault) {
        token = _token;
        maxSwapAmount = 1_000_000 ether * 3 / 100; // 3% of total supply, could use token.totalSupply()
    }

    /**
     * @notice Returns the hook flags indicating which hook functions should be called.
     * @return hookFlags The HookFlags struct indicating which hook functions are enabled.
     */
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.shouldCallAfterSwap = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        return hookFlags;
    }

    /**
     * @notice Called when the hook is registered to a pool.
     * @param pool The address of the pool to which the hook is being registered.
     * @return success Boolean indicating whether the registration was successful.
     */
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        emit BalancerFunHookRegistered(address(this), pool);
        return true;
    }

    /**
     * @notice Called after a swap is performed in the pool.
     * @param params The parameters for the swap, including token addresses and amounts.
     * @return success Boolean indicating if the swap was successful.
     * @return amountCalculatedRaw The calculated amount after the swap.
     */
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool, uint) {
        if (address(params.tokenIn) == address(token)) {
            uint currentBlockSold = blockToTotalSold[block.number];
            if (currentBlockSold + params.amountInScaled18 > maxSwapAmount * 1e18) {
                revert MaximumSwapExceeded();
            }
            blockToTotalSold[block.number] = currentBlockSold + params.amountInScaled18;
        }
        return (true, params.amountCalculatedRaw);
    }

    /**
     * @notice Called after an attempt to remove liquidity from the pool.
     * @dev This function always reverts with `LiquidityIsLocked()` error to prevent liquidity removal.
     * @return success Boolean indicating if the function succeeded.
     * @return emptyArray An empty array to satisfy return requirements.
     */
    function onAfterRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint,
        uint[] memory,
        uint[] memory,
        uint[] memory,
        bytes memory
    ) public view override onlyVault returns (bool, uint[] memory) {
        revert LiquidityIsLocked();
    }
}