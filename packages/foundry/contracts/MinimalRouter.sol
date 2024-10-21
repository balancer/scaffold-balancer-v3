// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { RouterCommon } from "@balancer-labs/v3-vault/contracts/RouterCommon.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { FixedPointMathLib } from "permit2/lib/solmate/src/utils/FixedPointMathLib.sol";
import {
    ReentrancyGuardTransient
} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/ReentrancyGuardTransient.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {console} from "forge-std/console.sol";
/// @title Minimal Router
/// @notice This contract provides basic functionality for a minimal router
/// @dev This is an abstract contract that should be inherited and implemented
abstract contract MinimalRouter is RouterCommon, ReentrancyGuardTransient {
    /// @notice This router enables the following functionality:
    /// - Allows liquidity providers to add liquidity
    /// - Enables users to perform token swaps
    /// - Provides methods for users to query the exchange rate between tokens
    using SafeCast for *;

    using FixedPointMathLib for uint256;

    /**
    * @notice Data for the swap hook.
    * @param sender Account initiating the swap operation
    * @param kind Type of swap (exact in or exact out)
    * @param pool Address of the liquidity pool
    * @param tokenIn Token to be swapped from
    * @param tokenOut Token to be swapped to
    * @param amountGiven Amount given based on kind of the swap (e.g., tokenIn for exact in)
    * @param limit Maximum or minimum amount based on the kind of swap (e.g., maxAmountIn for exact out)
    * @param deadline Deadline for the swap, after which it will revert
    * @param wethIsEth If true, incoming ETH will be wrapped to WETH and outgoing WETH will be unwrapped to ETH
    * @param userData Additional (optional) data sent with the swap request
    */
    struct SwapSingleTokenHookParams {
        address sender;
        SwapKind kind;
        address pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountGiven;
        uint256 limit;
        uint256 deadline;
        bool wethIsEth;
        bytes userData;
    }

    /**
     * @notice Data for the pool initialization hook.
     * @param sender Account originating the pool initialization operation
     * @param pool Address of the liquidity pool
     * @param tokens Pool tokens, in token registration order
     * @param exactAmountsIn Exact amounts of tokens to be added, sorted in token registration order
     * @param minBptAmountOut Minimum amount of pool tokens to be received
     * @param wethIsEth If true, incoming ETH will be wrapped to WETH and outgoing WETH will be unwrapped to ETH
     * @param userData Additional (optional) data sent with the request to add initial liquidity
     */
    struct InitializeHookParams {
        address sender;
        address pool;
        IERC20[] tokens;
        uint256[] exactAmountsIn;
        uint256 minBptAmountOut;
        bool wethIsEth;
        bytes userData;
    }

    constructor(IVault vault, IWETH weth, IPermit2 permit2) RouterCommon(vault, weth, permit2) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*******************************************************************************
                                Pool Initialization
    *******************************************************************************/
    function initialize(
        address pool,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable returns (uint256 bptAmountOut) {
        return
            abi.decode(
                _vault.unlock(
                    abi.encodeCall(
                        MinimalRouter.initializeHook,
                        InitializeHookParams({
                            sender: msg.sender,
                            pool: pool,
                            tokens: tokens,
                            exactAmountsIn: exactAmountsIn,
                            minBptAmountOut: minBptAmountOut,
                            wethIsEth: wethIsEth,
                            userData: userData
                        })
                    )
                ),
                (uint256)
            );
    }

    /**
     * @notice Hook for initialization.
     * @dev Can only be called by the Vault.
     * @param params Initialization parameters (see IRouter for struct definition)
     * @return bptAmountOut BPT amount minted in exchange for the input tokens
     */
    function initializeHook(
        InitializeHookParams calldata params
    ) external nonReentrant onlyVault returns (uint256 bptAmountOut) {
        bptAmountOut = _vault.initialize(
            params.pool,
            params.sender,
            params.tokens,
            params.exactAmountsIn,
            params.minBptAmountOut,
            params.userData
        );

        for (uint256 i = 0; i < params.tokens.length; ++i) {
            IERC20 token = params.tokens[i];
            uint256 amountIn = params.exactAmountsIn[i];

            // There can be only one WETH token in the pool.
            if (params.wethIsEth && address(token) == address(_weth)) {
                if (address(this).balance < amountIn) {
                    revert InsufficientEth();
                }

                _weth.deposit{ value: amountIn }();
                // Transfer WETH from the router to the Vault.
                _weth.transfer(address(_vault), amountIn);
                _vault.settle(_weth, amountIn);
            } else {
                // Rransfer tokens from the user to the Vault.
                // Any value over MAX_UINT128 would revert above in `initialize`, so this SafeCast shouldn't be
                // necessary. Done out of an abundance of caution.
                _permit2.transferFrom(params.sender, address(_vault), amountIn.toUint160(), address(token));
                _vault.settle(token, amountIn);
            }
        }

        // Return ETH dust.
        _returnEth(params.sender);
    }

    /***************************************************************************
                                Swaps
    ***************************************************************************/
    function swapSingleTokenExactIn(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    ) external payable saveSender returns (uint256) {
       
        return
            abi.decode(
                _vault.unlock(
                    abi.encodeCall(
                        MinimalRouter.swapSingleTokenHook,
                        SwapSingleTokenHookParams({
                            sender: msg.sender,
                            kind: SwapKind.EXACT_IN,
                            pool: pool,
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amountGiven: exactAmountIn,
                            limit: minAmountOut,
                            deadline: deadline,
                            wethIsEth: wethIsEth,
                            userData: abi.encode(msg.sender)
                        })
                    )
                ),
                (uint256)
            );
    }

    function swapSingleTokenExactInMod(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    ) external payable saveSender returns (uint256) {
        console.log(msg.sender);

        console.log(234);
         console.log(address(_vault));
        console.log(234);
        return
            abi.decode(
                _vault.unlock(
                    abi.encodeCall(
                        MinimalRouter.swapSingleTokenHookMod,
                        SwapSingleTokenHookParams({
                            sender: msg.sender,
                            kind: SwapKind.EXACT_IN,
                            pool: pool,
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amountGiven: exactAmountIn,
                            limit: minAmountOut,
                            deadline: deadline,
                            wethIsEth: wethIsEth,
                            userData: abi.encode(msg.sender)
                        })
                    )
                ),
                (uint256)
            );
    }
    

    function swapSingleTokenHook(
        SwapSingleTokenHookParams calldata params
    ) external nonReentrant onlyVault returns (uint256) {
        (uint256 amountCalculated, uint256 amountIn, uint256 amountOut) = _swapHook(params);

        IERC20 tokenIn = params.tokenIn;

        _takeTokenIn(params.sender, tokenIn, amountIn, params.wethIsEth);
        _sendTokenOut(params.sender, params.tokenOut, amountOut, params.wethIsEth);

        if (tokenIn == _weth) {
            // Return the rest of ETH to sender
            _returnEth(params.sender);
        }

        return amountCalculated;
    }

    function swapSingleTokenHookMod(
        SwapSingleTokenHookParams calldata params
    ) external nonReentrant  onlyVault returns (uint256) {
        console.log("Who is sender");
        console.log(msg.sender);
        (uint256 amountCalculated, uint256 amountIn, uint256 amountOut) = _swapHook(params);
// swapSingleTokenExactInMod(params.pool, params.tokenIn, params.tokenOut, params.amountGiven, params.limit, params.deadline, params.wethIsEth, params.userData);
        IERC20 tokenIn = params.tokenIn;
console.log("amounts calculated", amountCalculated);
console.log("amounts Out", amountOut);
//         // 1. take token from user to router
//         // 2. take token from router to vault 
//         // 3. get token from vault to router 
//         // 4. get toekn from router to user
console.log(address(this));
// // console.log(msg.sender);
//         // change to router
        // _takeTokenIn(0x866D42D8f75700768694B7b0bF7Fd1348663B102, tokenIn, amountIn * 5, params.wethIsEth);
        // _sendTokenOut(0x866D42D8f75700768694B7b0bF7Fd1348663B102, params.tokenOut, amountOut, params.wethIsEth);

//         // return any balnaces used if used 
//         // _sendTokenOut(params.sender, params.tokenOut, 12, params.wethIsEth);

//         if (tokenIn == _weth) {
//             // Return the rest of ETH to sender
//             _returnEth(params.sender);
//         }

        return (0);
    }


        function _swapHook(
            SwapSingleTokenHookParams calldata params
        ) internal returns (uint256 amountCalculated, uint256 amountIn, uint256 amountOut) {
            // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp > params.deadline) {
                revert SwapDeadline();
            }

            (amountCalculated, amountIn, amountOut) = _vault.swap(
                VaultSwapParams({
                    kind: params.kind,
                    pool: params.pool,
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    amountGivenRaw: params.amountGiven,
                    limitRaw: params.limit,
                    userData: params.userData
                })
            );
        }

    function querySwapSingleTokenExactIn(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        bytes calldata userData
    ) external saveSender returns (uint256 amountCalculated) {
        return
            abi.decode(
                _vault.quote(
                    abi.encodeCall(
                        MinimalRouter.querySwapHook,
                        SwapSingleTokenHookParams({
                            sender: msg.sender,
                            kind: SwapKind.EXACT_IN,
                            pool: pool,
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            amountGiven: exactAmountIn,
                            limit: 0,
                            deadline: _MAX_AMOUNT,
                            wethIsEth: false,
                            userData: userData
                        })
                    )
                ),
                (uint256)
            );
    }

    function querySwapSingleTokenExactIns(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        bytes calldata userData
    ) external view returns (uint256 amountCalculated) {
        SwapSingleTokenHookParams memory params = SwapSingleTokenHookParams({
            sender: msg.sender,
            kind: SwapKind.EXACT_IN,
            pool: pool,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountGiven: exactAmountIn,
            limit: 0,
            deadline: _MAX_AMOUNT,
            wethIsEth: false,
            userData: userData
        });

        bytes memory encodedParams = abi.encodeCall(
            MinimalRouter.querySwapHook,
            params
        );

        (, bytes memory result)= address(_vault).staticcall(abi.encodeCall(_vault.quote, encodedParams));

        return abi.decode(result, (uint256));
    }

    /**
     * @notice Hook for swap queries.
     * @dev Can only be called by the Vault. Also handles native ETH.
     * @param params Swap parameters (see IRouter for struct definition)
     * @return amountCalculated Token amount calculated by the pool math (e.g., amountOut for a exact in swap)
     */
    function querySwapHook(
        SwapSingleTokenHookParams calldata params
    ) external payable nonReentrant onlyVault returns (uint256) {
        (uint256 amountCalculated, , ) = _swapHook(params);

        return amountCalculated;
    }

    function queryTokenRateXYYX(uint256 _balanceOfX, uint256 _balanceOfY) internal view returns (uint256 tokenRateXY, uint256 tokenRateYX) {
        if ( _balanceOfX == 0 && _balanceOfY == 0) {
            revert("Division by zero");
        }

        return (
            FixedPointMathLib.divWadDown(_balanceOfX, _balanceOfY),
            FixedPointMathLib.divWadDown(_balanceOfY, _balanceOfX)
        );
    }

    function _buildSwapSingleTokenHookParams(
        address pool,
        address sender, 
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn
    ) internal view returns (SwapSingleTokenHookParams memory) {
        return SwapSingleTokenHookParams({
            sender: sender,
            kind: SwapKind.EXACT_IN,
            pool: pool,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountGiven: exactAmountIn,
            limit: 0,
            deadline: _MAX_AMOUNT,
            wethIsEth: false,
            userData: abi.encode(address(this))
        });
    }
}


