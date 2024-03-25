export const routerInfo = {
  _format: "hh-sol-artifact-1",
  contractName: "Router",
  sourceName: "contracts/Router.sol",
  abi: [
    {
      inputs: [
        {
          internalType: "contract IVault",
          name: "vault",
          type: "address",
        },
        {
          internalType: "contract IWETH",
          name: "weth",
          type: "address",
        },
      ],
      stateMutability: "nonpayable",
      type: "constructor",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "account",
          type: "address",
        },
      ],
      name: "AddressInsufficientBalance",
      type: "error",
    },
    {
      inputs: [],
      name: "EthTransfer",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "limit",
          type: "uint256",
        },
      ],
      name: "ExitBelowMin",
      type: "error",
    },
    {
      inputs: [],
      name: "FailedInnerCall",
      type: "error",
    },
    {
      inputs: [],
      name: "InsufficientEth",
      type: "error",
    },
    {
      inputs: [],
      name: "ReentrancyGuardReentrantCall",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "sender",
          type: "address",
        },
      ],
      name: "SenderIsNotVault",
      type: "error",
    },
    {
      inputs: [],
      name: "SwapDeadline",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256[]",
          name: "maxAmountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "minBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "addLiquidityCustom",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "uint256[]",
              name: "maxAmountsIn",
              type: "uint256[]",
            },
            {
              internalType: "uint256",
              name: "minBptAmountOut",
              type: "uint256",
            },
            {
              internalType: "enum AddLiquidityKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.AddLiquidityHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "addLiquidityHook",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "maxAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "addLiquiditySingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "amountIn",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256[]",
          name: "exactAmountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "minBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "addLiquidityUnbalanced",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20[]",
          name: "tokens",
          type: "address[]",
        },
        {
          internalType: "uint256[]",
          name: "exactAmountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "minBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "initialize",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "contract IERC20[]",
              name: "tokens",
              type: "address[]",
            },
            {
              internalType: "uint256[]",
              name: "exactAmountsIn",
              type: "uint256[]",
            },
            {
              internalType: "uint256",
              name: "minBptAmountOut",
              type: "uint256",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.InitializeHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "initializeHook",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256[]",
          name: "maxAmountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "minBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryAddLiquidityCustom",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "uint256[]",
              name: "maxAmountsIn",
              type: "uint256[]",
            },
            {
              internalType: "uint256",
              name: "minBptAmountOut",
              type: "uint256",
            },
            {
              internalType: "enum AddLiquidityKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.AddLiquidityHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "queryAddLiquidityHook",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsIn",
          type: "uint256[]",
        },
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryAddLiquiditySingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "amountIn",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256[]",
          name: "exactAmountsIn",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryAddLiquidityUnbalanced",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountOut",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "maxBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "minAmountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryRemoveLiquidityCustom",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "uint256[]",
              name: "minAmountsOut",
              type: "uint256[]",
            },
            {
              internalType: "uint256",
              name: "maxBptAmountIn",
              type: "uint256",
            },
            {
              internalType: "enum RemoveLiquidityKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.RemoveLiquidityHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "queryRemoveLiquidityHook",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryRemoveLiquidityProportional",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
      ],
      name: "queryRemoveLiquidityRecovery",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "address",
          name: "sender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
      ],
      name: "queryRemoveLiquidityRecoveryHook",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryRemoveLiquiditySingleTokenExactIn",
      outputs: [
        {
          internalType: "uint256",
          name: "amountOut",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "queryRemoveLiquiditySingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "enum SwapKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "contract IERC20",
              name: "tokenIn",
              type: "address",
            },
            {
              internalType: "contract IERC20",
              name: "tokenOut",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "amountGiven",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "limit",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "deadline",
              type: "uint256",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.SwapSingleTokenHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "querySwapHook",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountIn",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "querySwapSingleTokenExactIn",
      outputs: [
        {
          internalType: "uint256",
          name: "amountCalculated",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountOut",
          type: "uint256",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "querySwapSingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "amountCalculated",
          type: "uint256",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "maxBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "minAmountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "removeLiquidityCustom",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "uint256[]",
              name: "minAmountsOut",
              type: "uint256[]",
            },
            {
              internalType: "uint256",
              name: "maxBptAmountIn",
              type: "uint256",
            },
            {
              internalType: "enum RemoveLiquidityKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.RemoveLiquidityHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "removeLiquidityHook",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bytes",
          name: "returnData",
          type: "bytes",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256[]",
          name: "minAmountsOut",
          type: "uint256[]",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "removeLiquidityProportional",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
      ],
      name: "removeLiquidityRecovery",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "address",
          name: "sender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
      ],
      name: "removeLiquidityRecoveryHook",
      outputs: [
        {
          internalType: "uint256[]",
          name: "amountsOut",
          type: "uint256[]",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "minAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "removeLiquiditySingleTokenExactIn",
      outputs: [
        {
          internalType: "uint256",
          name: "amountOut",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "maxBptAmountIn",
          type: "uint256",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountOut",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "removeLiquiditySingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "bptAmountIn",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "minAmountOut",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "deadline",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "swapSingleTokenExactIn",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "exactAmountOut",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "maxAmountIn",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "deadline",
          type: "uint256",
        },
        {
          internalType: "bool",
          name: "wethIsEth",
          type: "bool",
        },
        {
          internalType: "bytes",
          name: "userData",
          type: "bytes",
        },
      ],
      name: "swapSingleTokenExactOut",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "sender",
              type: "address",
            },
            {
              internalType: "enum SwapKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "contract IERC20",
              name: "tokenIn",
              type: "address",
            },
            {
              internalType: "contract IERC20",
              name: "tokenOut",
              type: "address",
            },
            {
              internalType: "uint256",
              name: "amountGiven",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "limit",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "deadline",
              type: "uint256",
            },
            {
              internalType: "bool",
              name: "wethIsEth",
              type: "bool",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct IRouter.SwapSingleTokenHookParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "swapSingleTokenHook",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      stateMutability: "payable",
      type: "receive",
    },
  ],
  bytecode:
    "0x60c06040523480156200001157600080fd5b5060405162005e4038038062005e408339810160408190526200003491620000e7565b6001600160a01b03828116608081905290821660a081905260405163095ea7b360e01b815260048101929092526000196024830152839183919063095ea7b3906044016020604051808303816000875af115801562000097573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620000bd919062000126565b505060016000555062000151915050565b6001600160a01b0381168114620000e457600080fd5b50565b60008060408385031215620000fb57600080fd5b82516200010881620000ce565b60208401519092506200011b81620000ce565b809150509250929050565b6000602082840312156200013957600080fd5b815180151581146200014a57600080fd5b9392505050565b60805160a051615b1762000329600039600081816101e101528181610876015281816108eb0152818161098a01528181611821015281816118960152818161193501528181611dee01528181612562015281816125cb0152818161268901528181614080015281816140be0152818161418c0152818161422e0152818161437e015261448501526000818161058b0152818161070b015281816109c401528181610a3301528181610b2801528181610cab01528181610e6f01528181611011015281816110c00152818161113f0152818161124e015281816113fa01528181611541015281816117010152818161196f015281816119de01528181611b2101528181611bc501528181611e5f01528181612013015281816121e9015281816123ac015281816126000152818161270101528181612804015281816129ef01528181612aec01528181612c6e01528181612e0801528181612e8301528181612fbe015281816131af0152818161335801528181613439015281816135a301528181613634015281816137970152818161392f01528181613b1c01528181613cad01528181613db601528181613ed80152818161415d0152818161425601528181614310015281816143fc015261454b0152615b176000f3fe6080604052600436106101d15760003560e01c80637ccb4325116100f7578063be5ae84111610095578063e7326def11610064578063e7326def1461052e578063ecb2182c14610541578063efd85f1414610554578063fbe985d51461056757600080fd5b8063be5ae841146104c8578063c08bc851146104db578063df145a4f146104ee578063e6b51e8f1461050e57600080fd5b806387a6c9ff116100d157806387a6c9ff1461045557806394e86ef814610475578063b037ed3614610488578063b24bd571146104a857600080fd5b80637ccb4325146103f55780637d245e901461041557806382bf2b241461043557600080fd5b8063516827501161016f57806368a24fe01161013e57806368a24fe01461039c57806372657d17146103af578063750283bc146103c25780637b03c7ba146103d557600080fd5b806351682750146103365780635b343791146103495780635f9815ff1461035c5780636193d47d1461037c57600080fd5b80632d90b0dd116101ab5780632d90b0dd1461029a5780633ae97603146102ba57806343112672146102da578063479249801461030757600080fd5b8063026b3d951461023f578063086fad66146102655780630ca078ec1461027857600080fd5b3661023a57336001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001614610238576040517f0540ddf600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b005b600080fd5b61025261024d366004614805565b610587565b6040519081526020015b60405180910390f35b610252610273366004614931565b6106ef565b61028b610286366004614966565b610b20565b60405161025c93929190614a86565b3480156102a657600080fd5b5061028b6102b5366004614abb565b610ca3565b3480156102c657600080fd5b506102526102d5366004614b3b565b610e22565b3480156102e657600080fd5b506102fa6102f5366004614b9b565b610fb8565b60405161025c9190614bdc565b34801561031357600080fd5b50610327610322366004614bef565b611247565b60405161025c93929190614c56565b6102fa610344366004614c81565b6113b5565b61028b610357366004614931565b611529565b34801561036857600080fd5b506102fa610377366004614b9b565b611ac8565b34801561038857600080fd5b50610252610397366004614b3b565b611b9e565b6102526103aa366004614ce6565b611d58565b6102526103bd366004614d22565b611e47565b6102526103d0366004614de5565b611ff7565b3480156103e157600080fd5b506103276103f0366004614931565b6121d2565b34801561040157600080fd5b50610252610410366004614e93565b6127e8565b34801561042157600080fd5b50610252610430366004614e93565b6129d3565b34801561044157600080fd5b50610327610450366004614c81565b612ae5565b34801561046157600080fd5b50610252610470366004614f18565b612c55565b610252610483366004614de5565b612dec565b34801561049457600080fd5b506102fa6104a3366004614f6c565b612e5e565b3480156104b457600080fd5b506103276104c3366004614931565b612fa7565b6102526104d6366004614ce6565b61317e565b6102526104e9366004614966565b6131ab565b3480156104fa57600080fd5b506102fa610509366004614f98565b61331a565b34801561051a57600080fd5b506102fa610529366004614f6c565b61357e565b61025261053c366004614ff1565b6135f6565b61025261054f366004614ff1565b61377f565b61028b610562366004614931565b613917565b34801561057357600080fd5b50610252610582366004615043565b613aed565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663815483193463086fad6660e01b6040518060e00160405280336001600160a01b031681526020018c6001600160a01b031681526020018b81526020018a815260200189815260200188151581526020018781525060405160240161061891906150e8565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b909216825261068a9160040161518a565b60006040518083038185885af11580156106a8573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f191682016040526106d191908101906151e2565b8060200190518101906106e49190615217565b979650505050505050565b60006106f9613c5f565b610701613ca2565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ba8a2be06107406040850160208601615230565b61074d6020860186615230565b61075a604087018761524d565b610767606089018961524d565b60808a013561077960c08c018c6152b5565b6040518a63ffffffff1660e01b815260040161079d99989796959493929190615390565b6020604051808303816000875af11580156107bc573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107e09190615217565b90506000805b6107f3604085018561524d565b9050811015610af957600061080b604086018661524d565b8381811061081b5761081b61542c565b90506020020160208101906108309190615230565b90506000610841606087018761524d565b848181106108515761085161542c565b9050602002013590508560a001602081019061086d919061545b565b80156108aa57507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316826001600160a01b0316145b15610a2957803410156108e9576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0826040518263ffffffff1660e01b81526004016000604051808303818588803b15801561094457600080fd5b505af1158015610958573d6000803e3d6000fd5b50506040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301523060248301526044820186905294975087947f000000000000000000000000000000000000000000000000000000000000000016935063ed2438cd92506064019050600060405180830381600087803b158015610a0c57600080fd5b505af1158015610a20573d6000803e3d6000fd5b50505050610ae6565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ed2438cd83610a6660208a018a615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101849052606401600060405180830381600087803b158015610acd57600080fd5b505af1158015610ae1573d6000803e3d6000fd5b505050505b505080610af2906154a7565b90506107e6565b50610b10610b0a6020850185615230565b82613d08565b50610b1b6001600055565b919050565b6060600060607f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018d6001600160a01b031681526020018c81526020018b8152602001600280811115610ba557610ba56154df565b81526020018a1515815260200189815250604051602401610bc69190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b9092168252610c389160040161518a565b60006040518083038185885af1158015610c56573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f19168201604052610c7f91908101906151e2565b806020019051810190610c929190615601565b925092509250955095509592505050565b6060600060607f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863efd85f1460e01b6040518060e00160405280306001600160a01b031681526020018b6001600160a01b031681526020018a8152602001898152602001600280811115610d2757610d276154df565b815260006020820152604090810189905251610d469190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252610db89160040161518a565b6000604051808303816000875af1158015610dd7573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052610dff91908101906151e2565b806020019051810190610e129190615601565b9250925092509450945094915050565b600080610e30868686613d6e565b506040805160e0810182523081526001600160a01b0389811660208301529181018390526fffffffffffffffffffffffffffffffff60608201529192507f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fb24bd5710000000000000000000000000000000000000000000000000000000090608081016002815260006020820152604090810188905251610edd9190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252610f4f9160040161518a565b6000604051808303816000875af1158015610f6e573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052610f9691908101906151e2565b806020019051810190610fa991906156d0565b5090925050505b949350505050565b6060610fc2613c5f565b610fca613ca2565b6040517f3a2d133b0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528481166024830152604482018490527f00000000000000000000000000000000000000000000000000000000000000001690633a2d133b906064016000604051808303816000875af115801561105a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526110829190810190615726565b6040517fca4f28030000000000000000000000000000000000000000000000000000000081526001600160a01b0386811660048301529192506000917f0000000000000000000000000000000000000000000000000000000000000000169063ca4f280390602401600060405180830381865afa158015611107573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261112f919081019061575b565b905060005b8151811015611234577f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663ae63932983838151811061117e5761117e61542c565b6020026020010151878685815181106111995761119961542c565b60209081029190910101516040517fffffffff0000000000000000000000000000000000000000000000000000000060e086901b1681526001600160a01b0393841660048201529290911660248301526044820152606401600060405180830381600087803b15801561120b57600080fd5b505af115801561121f573d6000803e3d6000fd5b505050508061122d906154a7565b9050611134565b50506112406001600055565b9392505050565b60006060807f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863b24bd57160e01b6040518060e00160405280306001600160a01b031681526020018b6001600160a01b031681526020018981526020018a81526020016003808111156112ca576112ca6154df565b8152600060208201526040908101899052516112e99190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b909216825261135b9160040161518a565b6000604051808303816000875af115801561137a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526113a291908101906151e2565b806020019051810190610e1291906156d0565b6040805160e0810182523381526001600160a01b03878116602083015281830186905260608083018890526000608084015285151560a084015260c0830185905292517f0000000000000000000000000000000000000000000000000000000000000000909116916381548319917f7b03c7ba000000000000000000000000000000000000000000000000000000009161145191602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526114c39160040161518a565b6000604051808303816000875af11580156114e2573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261150a91908101906151e2565b80602001905181019061151d91906156d0565b50979650505050505050565b606060006060611537613c5f565b61153f613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316634af29ec46040518060c0016040528087602001602081019061158c9190615230565b6001600160a01b031681526020908101906115a990890189615230565b6001600160a01b031681526020016115c4604089018961524d565b808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152505050908252506060880135602082015260400161161560a0890160808a016157ea565b6002811115611626576116266154df565b815260200161163860c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526116a7919060040161580b565b6000604051808303816000875af11580156116c6573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526116ee9190810190615601565b9194509250905060006001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ca4f28036117366040880160208901615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526001600160a01b039091166004820152602401600060405180830381865afa158015611792573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526117ba919081019061575b565b90506000805b8251811015611aa45760008382815181106117dd576117dd61542c565b6020026020010151905060008783815181106117fb576117fb61542c565b602002602001015190508860a0016020810190611818919061545b565b801561185557507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316826001600160a01b0316145b156119d45780341015611894576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0826040518263ffffffff1660e01b81526004016000604051808303818588803b1580156118ef57600080fd5b505af1158015611903573d6000803e3d6000fd5b50506040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301523060248301526044820186905294975087947f000000000000000000000000000000000000000000000000000000000000000016935063ed2438cd92506064019050600060405180830381600087803b1580156119b757600080fd5b505af11580156119cb573d6000803e3d6000fd5b50505050611a91565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ed2438cd83611a1160208d018d615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101849052606401600060405180830381600087803b158015611a7857600080fd5b505af1158015611a8c573d6000803e3d6000fd5b505050505b505080611a9d906154a7565b90506117c0565b50611ab5610b0a6020880188615230565b5050611ac16001600055565b9193909250565b6060611ad2613c5f565b611ada613ca2565b6040517f3a2d133b0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528481166024830152604482018490527f00000000000000000000000000000000000000000000000000000000000000001690633a2d133b906064016000604051808303816000875af1158015611b6a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052611b929190810190615726565b90506112406001600055565b60008080611bbd87876fffffffffffffffffffffffffffffffff613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863efd85f1460e01b6040518060e00160405280306001600160a01b031681526020018c6001600160a01b031681526020018781526020018a815260200160016002811115611c4257611c426154df565b81526000602082015260409081018a905251611c619190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252611cd39160040161518a565b6000604051808303816000875af1158015611cf2573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052611d1a91908101906151e2565b806020019051810190611d2d9190615601565b50509050808281518110611d4357611d4361542c565b60200260200101519350505050949350505050565b6000611d62613c5f565b611d6a613ca2565b6000806000611d7885613e93565b919450925090506000611d916080870160608801615230565b90506000611da76101208801610100890161545b565b90506000611dc3611dbb60208a018a615230565b848785614074565b9050611dec611dd560208a018a615230565b611de560a08b0160808c01615230565b8685614374565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b031603611e3557611e35610b0a60208a018a615230565b5093945050505050610b1b6001600055565b6000806000611e57898989613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018f6001600160a01b031681526020018881526020018c815260200160016002811115611edd57611edd6154df565b81526020018b151581526020018a815250604051602401611efe9190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b9092168252611f709160040161518a565b60006040518083038185885af1158015611f8e573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f19168201604052611fb791908101906151e2565b806020019051810190611fca9190615601565b50509050808281518110611fe057611fe061542c565b602002602001015193505050509695505050505050565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063815483199034907f68a24fe0000000000000000000000000000000000000000000000000000000009060208101865b81526020018f6001600160a01b031681526020018e6001600160a01b031681526020018d6001600160a01b031681526020018c81526020018b81526020018a8152602001891515815260200188888080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040516120f89190602401615892565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b909216825261216a9160040161518a565b60006040518083038185885af1158015612188573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f191682016040526121b191908101906151e2565b8060200190518101906121c49190615217565b9a9950505050505050505050565b60006060806121df613c5f565b6121e7613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663214578976040518060c001604052808760200160208101906122349190615230565b6001600160a01b0316815260209081019061225190890189615230565b6001600160a01b0316815260200187606001358152602001878060400190612279919061524d565b808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152505050908252506020016122c060a0890160808a01615952565b60038111156122d1576122d16154df565b81526020016122e360c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526123529190600401615973565b6000604051808303816000875af1158015612371573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261239991908101906156d0565b9194509250905060006001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ca4f28036123e16040880160208901615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526001600160a01b039091166004820152602401600060405180830381865afa15801561243d573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612465919081019061575b565b90506000805b82518110156127c75760008582815181106124885761248861542c565b6020026020010151905060008483815181106124a6576124a661542c565b602002602001015190508880604001906124c0919061524d565b848181106124d0576124d061542c565b9050602002013582101561254957816124ec60408b018b61524d565b858181106124fc576124fc61542c565b905060200201356040517f2361f44b000000000000000000000000000000000000000000000000000000008152600401612540929190918252602082015260400190565b60405180910390fd5b61255960c08a0160a08b0161545b565b801561259657507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b0316145b156126f7576040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b037f000000000000000000000000000000000000000000000000000000000000000081166004830152306024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561264457600080fd5b505af1158015612658573d6000803e3d6000fd5b50506040517f2e1a7d4d000000000000000000000000000000000000000000000000000000008152600481018590527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169250632e1a7d4d9150602401600060405180830381600087803b1580156126d757600080fd5b505af11580156126eb573d6000803e3d6000fd5b505050508193506127b4565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ae6393298261273460208d018d615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101859052606401600060405180830381600087803b15801561279b57600080fd5b505af11580156127af573d6000803e3d6000fd5b505050505b5050806127c0906154a7565b905061246b565b50611ab5816127d96020890189615230565b6001600160a01b0316906145ae565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fbe5ae841000000000000000000000000000000000000000000000000000000009060208101600181526020018b6001600160a01b031681526020018a6001600160a01b03168152602001896001600160a01b031681526020018881526020016fffffffffffffffffffffffffffffffff801681526020017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff815260200160001515815260200187878080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250505091525060405161291a9190602401615892565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b909216825261298c9160040161518a565b6000604051808303816000875af11580156129ab573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526106d191908101906151e2565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fbe5ae8410000000000000000000000000000000000000000000000000000000090602081018581526020018b6001600160a01b031681526020018a6001600160a01b03168152602001896001600160a01b03168152602001888152602001600081526020016fffffffffffffffffffffffffffffffff8016815260200160001515815260200187878080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250505091525060405161291a9190602401615892565b60006060807f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03166381548319637b03c7ba60e01b6040518060e00160405280336001600160a01b031681526020018c6001600160a01b031681526020018a81526020018b8152602001600380811115612b6857612b686154df565b8152602001891515815260200188815250604051602401612b899190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612bfb9160040161518a565b6000604051808303816000875af1158015612c1a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612c4291908101906151e2565b806020019051810190610c9291906156d0565b6000806000612c6687866001613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863b24bd57160e01b6040518060e00160405280306001600160a01b031681526020018c6001600160a01b031681526020018781526020018b815260200160016003811115612ceb57612ceb6154df565b81526000602082015260409081018a905251612d0a9190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612d7c9160040161518a565b6000604051808303816000875af1158015612d9b573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612dc391908101906151e2565b806020019051810190612dd691906156d0565b50915050808281518110611d4357611d4361542c565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063815483199034907f68a24fe00000000000000000000000000000000000000000000000000000000090602081016001612064565b6040516001600160a01b038381166024830152306044830152606482018390526060917f00000000000000000000000000000000000000000000000000000000000000009091169063edfa3568907f5f9815ff00000000000000000000000000000000000000000000000000000000906084015b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612f449160040161518a565b6000604051808303816000875af1158015612f63573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612f8b91908101906151e2565b806020019051810190612f9e9190615726565b90505b92915050565b6000606080612fb4613c5f565b612fbc613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663214578976040518060c001604052808760200160208101906130099190615230565b6001600160a01b0316815260209081019061302690890189615230565b6001600160a01b031681526020018760600135815260200187806040019061304e919061524d565b8080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525050509082525060200161309560a0890160808a01615952565b60038111156130a6576130a66154df565b81526020016130b860c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526131279190600401615973565b6000604051808303816000875af1158015613146573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261316e91908101906156d0565b925092509250611ac16001600055565b6000613188613c5f565b613190613ca2565b600061319b83613e93565b509092505050610b1b6001600055565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018b6001600160a01b031681526020018a81526020018981526020016000600281111561322d5761322d6154df565b815260200188151581526020018781525060405160240161324e9190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b90921682526132c09160040161518a565b60006040518083038185885af11580156132de573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f1916820160405261330791908101906151e2565b80602001905181019061151d9190615601565b6040517fca4f28030000000000000000000000000000000000000000000000000000000081526001600160a01b0384811660048301526060916000917f0000000000000000000000000000000000000000000000000000000000000000169063ca4f280390602401600060405180830381865afa15801561339f573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526133c7919081019061575b565b5167ffffffffffffffff8111156133e0576133e061468f565b604051908082528060200260200182016040528015613409578160200160208202803683370190505b506040805160e0810182523081526001600160a01b038881166020830152918101839052606081018790529192507f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fb24bd57100000000000000000000000000000000000000000000000000000000906080810160008152600060208201526040908101889052516134a79190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526135199160040161518a565b6000604051808303816000875af1158015613538573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261356091908101906151e2565b80602001905181019061357391906156d0565b509695505050505050565b6040516001600160a01b038381166024830152336044830152606482018390526060917f0000000000000000000000000000000000000000000000000000000000000000909116906381548319907f431126720000000000000000000000000000000000000000000000000000000090608401612ed2565b600080613604888787613d6e565b506040805160e0810182523381526001600160a01b038b81166020830152918101839052606081018a90529192507f000000000000000000000000000000000000000000000000000000000000000016906381548319907f7b03c7ba000000000000000000000000000000000000000000000000000000009060808101600281526020018815158152602001878152506040516024016136a49190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526137169160040161518a565b6000604051808303816000875af1158015613735573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261375d91908101906151e2565b80602001905181019061377091906156d0565b50909998505050505050505050565b600080600061378f898888613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03166381548319637b03c7ba60e01b6040518060e00160405280336001600160a01b031681526020018e6001600160a01b031681526020018781526020018d815260200160016003811115613814576138146154df565b81526020018a15158152602001898152506040516024016138359190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526138a79160040161518a565b6000604051808303816000875af11580156138c6573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526138ee91908101906151e2565b80602001905181019061390191906156d0565b50915050808281518110611fe057611fe061542c565b606060006060613925613c5f565b61392d613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316634af29ec46040518060c0016040528087602001602081019061397a9190615230565b6001600160a01b0316815260209081019061399790890189615230565b6001600160a01b031681526020016139b2604089018961524d565b8080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525050509082525060608801356020820152604001613a0360a0890160808a016157ea565b6002811115613a1457613a146154df565b8152602001613a2660c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b168152613a95919060040161580b565b6000604051808303816000875af1158015613ab4573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052613adc9190810190615601565b91945092509050611ac16001600055565b6040805160e0810182523081526001600160a01b038581166020830152918101849052600060608201819052917f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fefd85f1400000000000000000000000000000000000000000000000000000000906080810185815260006020820152604090810187905251613b899190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252613bfb9160040161518a565b6000604051808303816000875af1158015613c1a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052613c4291908101906151e2565b806020019051810190613c559190615601565b5095945050505050565b600260005403613c9b576040517f3ee5aeb500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6002600055565b336001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001614613d06576040517f089676d5000000000000000000000000000000000000000000000000000000008152336004820152602401612540565b565b80341015613d42576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000613d4e82346159ce565b90508015613d6957613d696001600160a01b038416826145ae565b505050565b6040517fc9c1661b0000000000000000000000000000000000000000000000000000000081526001600160a01b038481166004830152838116602483015260609160009182917f00000000000000000000000000000000000000000000000000000000000000009091169063c9c1661b906044016040805180830381865afa158015613dfe573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613e2291906159e1565b925090508067ffffffffffffffff811115613e3f57613e3f61468f565b604051908082528060200260200182016040528015613e68578160200160208202803683370190505b50925083838381518110613e7e57613e7e61542c565b60200260200101818152505050935093915050565b60008060008360e00135421115613ed6576040517fe08b8af000000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632bfb780c6040518060e00160405280876020016020810190613f239190615a05565b6001811115613f3457613f346154df565b8152602001613f496060890160408a01615230565b6001600160a01b03168152602001613f676080890160608a01615230565b6001600160a01b03168152602001613f8560a0890160808a01615230565b6001600160a01b0316815260a0880135602082015260c08801356040820152606001613fb56101208901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526140249190600401615a26565b6060604051808303816000875af1158015614043573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906140679190615a96565b9196909550909350915050565b60008180156140b457507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316846001600160a01b0316145b156142c9578290507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0846040518263ffffffff1660e01b81526004016000604051808303818588803b15801561411757600080fd5b505af115801561412b573d6000803e3d6000fd5b50506040517fa9059cbb0000000000000000000000000000000000000000000000000000000081526001600160a01b037f000000000000000000000000000000000000000000000000000000000000000081166004830152602482018890527f000000000000000000000000000000000000000000000000000000000000000016935063a9059cbb925060440190506020604051808303816000875af11580156141d9573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906141fd9190615ac4565b506040517f6a256b290000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301527f00000000000000000000000000000000000000000000000000000000000000001690636a256b29906024016020604051808303816000875af115801561429f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906142c39190615217565b50610fb0565b6040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528681166024830152604482018590527f0000000000000000000000000000000000000000000000000000000000000000169063ed2438cd90606401600060405180830381600087803b15801561435457600080fd5b505af1158015614368573d6000803e3d6000fd5b50505050949350505050565b8080156143b257507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b0316145b15614504576040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b038481166004830152306024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561444057600080fd5b505af1158015614454573d6000803e3d6000fd5b50506040517f2e1a7d4d000000000000000000000000000000000000000000000000000000008152600481018590527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169250632e1a7d4d9150602401600060405180830381600087803b1580156144d357600080fd5b505af11580156144e7573d6000803e3d6000fd5b506144ff925050506001600160a01b038516836145ae565b6145a8565b6040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b0384811660048301528581166024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561458f57600080fd5b505af11580156145a3573d6000803e3d6000fd5b505050505b50505050565b804710156145ea576040517fcd786059000000000000000000000000000000000000000000000000000000008152306004820152602401612540565b6000826001600160a01b03168260405160006040518083038185875af1925050503d8060008114614637576040519150601f19603f3d011682016040523d82523d6000602084013e61463c565b606091505b5050905080613d69576040517f1425ea4200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6001600160a01b038116811461468c57600080fd5b50565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff811182821017156146e7576146e761468f565b604052919050565b600067ffffffffffffffff8211156147095761470961468f565b5060051b60200190565b600082601f83011261472457600080fd5b81356020614739614734836146ef565b6146be565b82815260059290921b8401810191818101908684111561475857600080fd5b8286015b84811015613573578035835291830191830161475c565b801515811461468c57600080fd5b8035610b1b81614773565b600067ffffffffffffffff8211156147a6576147a661468f565b50601f01601f191660200190565b600082601f8301126147c557600080fd5b81356147d36147348261478c565b8181528460208386010111156147e857600080fd5b816020850160208301376000918101602001919091529392505050565b60008060008060008060c0878903121561481e57600080fd5b863561482981614677565b955060208781013567ffffffffffffffff8082111561484757600080fd5b818a0191508a601f83011261485b57600080fd5b8135614869614734826146ef565b81815260059190911b8301840190848101908d83111561488857600080fd5b938501935b828510156148af5784356148a081614677565b8252938501939085019061488d565b9950505060408a01359250808311156148c757600080fd5b6148d38b848c01614713565b965060608a013595506148e860808b01614781565b945060a08a01359250808311156148fe57600080fd5b505061490c89828a016147b4565b9150509295509295509295565b600060e0828403121561492b57600080fd5b50919050565b60006020828403121561494357600080fd5b813567ffffffffffffffff81111561495a57600080fd5b610fb084828501614919565b600080600080600060a0868803121561497e57600080fd5b853561498981614677565b9450602086013567ffffffffffffffff808211156149a657600080fd5b6149b289838a01614713565b955060408801359450606088013591506149cb82614773565b909250608087013590808211156149e157600080fd5b506149ee888289016147b4565b9150509295509295909350565b600081518084526020808501945080840160005b83811015614a2b57815187529582019590820190600101614a0f565b509495945050505050565b60005b83811015614a51578181015183820152602001614a39565b50506000910152565b60008151808452614a72816020860160208601614a36565b601f01601f19169290920160200192915050565b606081526000614a9960608301866149fb565b8460208401528281036040840152614ab18185614a5a565b9695505050505050565b60008060008060808587031215614ad157600080fd5b8435614adc81614677565b9350602085013567ffffffffffffffff80821115614af957600080fd5b614b0588838901614713565b9450604087013593506060870135915080821115614b2257600080fd5b50614b2f878288016147b4565b91505092959194509250565b60008060008060808587031215614b5157600080fd5b8435614b5c81614677565b93506020850135614b6c81614677565b925060408501359150606085013567ffffffffffffffff811115614b8f57600080fd5b614b2f878288016147b4565b600080600060608486031215614bb057600080fd5b8335614bbb81614677565b92506020840135614bcb81614677565b929592945050506040919091013590565b602081526000612f9e60208301846149fb565b60008060008060808587031215614c0557600080fd5b8435614c1081614677565b935060208501359250604085013567ffffffffffffffff80821115614c3457600080fd5b614c4088838901614713565b93506060870135915080821115614b2257600080fd5b838152606060208201526000614c6f60608301856149fb565b8281036040840152614ab18185614a5a565b600080600080600060a08688031215614c9957600080fd5b8535614ca481614677565b945060208601359350604086013567ffffffffffffffff80821115614cc857600080fd5b614cd489838a01614713565b9450606088013591506149cb82614773565b600060208284031215614cf857600080fd5b813567ffffffffffffffff811115614d0f57600080fd5b8201610140818503121561124057600080fd5b60008060008060008060c08789031215614d3b57600080fd5b8635614d4681614677565b95506020870135614d5681614677565b945060408701359350606087013592506080870135614d7481614773565b915060a087013567ffffffffffffffff811115614d9057600080fd5b61490c89828a016147b4565b60008083601f840112614dae57600080fd5b50813567ffffffffffffffff811115614dc657600080fd5b602083019150836020828501011115614dde57600080fd5b9250929050565b60008060008060008060008060006101008a8c031215614e0457600080fd5b8935614e0f81614677565b985060208a0135614e1f81614677565b975060408a0135614e2f81614677565b965060608a0135955060808a0135945060a08a0135935060c08a0135614e5481614773565b925060e08a013567ffffffffffffffff811115614e7057600080fd5b614e7c8c828d01614d9c565b915080935050809150509295985092959850929598565b60008060008060008060a08789031215614eac57600080fd5b8635614eb781614677565b95506020870135614ec781614677565b94506040870135614ed781614677565b935060608701359250608087013567ffffffffffffffff811115614efa57600080fd5b614f0689828a01614d9c565b979a9699509497509295939492505050565b60008060008060808587031215614f2e57600080fd5b8435614f3981614677565b9350602085013592506040850135614f5081614677565b9150606085013567ffffffffffffffff811115614b8f57600080fd5b60008060408385031215614f7f57600080fd5b8235614f8a81614677565b946020939093013593505050565b600080600060608486031215614fad57600080fd5b8335614fb881614677565b925060208401359150604084013567ffffffffffffffff811115614fdb57600080fd5b614fe7868287016147b4565b9150509250925092565b60008060008060008060c0878903121561500a57600080fd5b863561501581614677565b955060208701359450604087013561502c81614677565b9350606087013592506080870135614d7481614773565b60008060006060848603121561505857600080fd5b833561506381614677565b9250602084013567ffffffffffffffff8082111561508057600080fd5b61508c87838801614713565b935060408601359150808211156150a257600080fd5b50614fe7868287016147b4565b600081518084526020808501945080840160005b83811015614a2b5781516001600160a01b0316875295820195908201906001016150c3565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526151266101008401826150af565b90506060840151601f198085840301608086015261514483836149fb565b9250608086015160a086015260a0860151915061516560c086018315159052565b60c08601519150808584030160e0860152506151818282614a5a565b95945050505050565b602081526000612f9e6020830184614a5a565b600082601f8301126151ae57600080fd5b81516151bc6147348261478c565b8181528460208386010111156151d157600080fd5b610fb0826020830160208701614a36565b6000602082840312156151f457600080fd5b815167ffffffffffffffff81111561520b57600080fd5b610fb08482850161519d565b60006020828403121561522957600080fd5b5051919050565b60006020828403121561524257600080fd5b813561124081614677565b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe184360301811261528257600080fd5b83018035915067ffffffffffffffff82111561529d57600080fd5b6020019150600581901b3603821315614dde57600080fd5b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe18436030181126152ea57600080fd5b83018035915067ffffffffffffffff82111561530557600080fd5b602001915036819003821315614dde57600080fd5b81835260007f07ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff83111561534c57600080fd5b8260051b80836020870137939093016020019392505050565b818352818160208501375060006020828401015260006020601f19601f840116840101905092915050565b600060c082016001600160a01b03808d1684526020818d168186015260c06040860152828b845260e0860190508c935060005b8c8110156153ea5784356153d681614677565b8416825293820193908201906001016153c3565b5085810360608701526153fe818b8d61531a565b935050505085608084015282810360a084015261541c818587615365565b9c9b505050505050505050505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60006020828403121561546d57600080fd5b813561124081614773565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036154d8576154d8615478565b5060010190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b6003811061551e5761551e6154df565b9052565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526155606101008401826149fb565b905060608401516080840152608084015161557e60a085018261550e565b5060a0840151151560c084015260c0840151601f198483030160e08501526151818282614a5a565b600082601f8301126155b757600080fd5b815160206155c7614734836146ef565b82815260059290921b840181019181810190868411156155e657600080fd5b8286015b8481101561357357805183529183019183016155ea565b60008060006060848603121561561657600080fd5b835167ffffffffffffffff8082111561562e57600080fd5b61563a878388016155a6565b945060208601519350604086015191508082111561565757600080fd5b50614fe78682870161519d565b6004811061551e5761551e6154df565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526156b26101008401826149fb565b905060608401516080840152608084015161557e60a0850182615664565b6000806000606084860312156156e557600080fd5b83519250602084015167ffffffffffffffff8082111561570457600080fd5b615710878388016155a6565b9350604086015191508082111561565757600080fd5b60006020828403121561573857600080fd5b815167ffffffffffffffff81111561574f57600080fd5b610fb0848285016155a6565b6000602080838503121561576e57600080fd5b825167ffffffffffffffff81111561578557600080fd5b8301601f8101851361579657600080fd5b80516157a4614734826146ef565b81815260059190911b820183019083810190878311156157c357600080fd5b928401925b828410156106e45783516157db81614677565b825292840192908401906157c8565b6000602082840312156157fc57600080fd5b81356003811061124057600080fd5b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160c0606084015261584860e08401826149fb565b905060608401516080840152608084015161586660a085018261550e565b5060a0840151601f198483030160c08501526151818282614a5a565b6002811061551e5761551e6154df565b602081526158ac6020820183516001600160a01b03169052565b600060208301516158c06040840182615882565b5060408301516001600160a01b03811660608401525060608301516001600160a01b03811660808401525060808301516001600160a01b03811660a08401525060a083015160c083015260c083015160e083015260e08301516101008181850152808501519150506101206159388185018315159052565b840151610140848101529050610fb0610160840182614a5a565b60006020828403121561596457600080fd5b81356004811061124057600080fd5b6020815260006001600160a01b038084511660208401528060208501511660408401525060408301516060830152606083015160c060808401526159ba60e08401826149fb565b9050608084015161586660a0850182615664565b81810381811115612fa157612fa1615478565b600080604083850312156159f457600080fd5b505080516020909101519092909150565b600060208284031215615a1757600080fd5b81356002811061124057600080fd5b60208152615a38602082018351615882565b600060208301516001600160a01b0380821660408501528060408601511660608501528060608601511660808501525050608083015160a083015260a083015160c083015260c083015160e080840152610fb0610100840182614a5a565b600080600060608486031215615aab57600080fd5b8351925060208401519150604084015190509250925092565b600060208284031215615ad657600080fd5b81516112408161477356fea26469706673582212207028703288432ac7d72b5a88168f32cd25eb674ea6926a06d3d050f03e07f47064736f6c63430008150033",
  deployedBytecode:
    "0x6080604052600436106101d15760003560e01c80637ccb4325116100f7578063be5ae84111610095578063e7326def11610064578063e7326def1461052e578063ecb2182c14610541578063efd85f1414610554578063fbe985d51461056757600080fd5b8063be5ae841146104c8578063c08bc851146104db578063df145a4f146104ee578063e6b51e8f1461050e57600080fd5b806387a6c9ff116100d157806387a6c9ff1461045557806394e86ef814610475578063b037ed3614610488578063b24bd571146104a857600080fd5b80637ccb4325146103f55780637d245e901461041557806382bf2b241461043557600080fd5b8063516827501161016f57806368a24fe01161013e57806368a24fe01461039c57806372657d17146103af578063750283bc146103c25780637b03c7ba146103d557600080fd5b806351682750146103365780635b343791146103495780635f9815ff1461035c5780636193d47d1461037c57600080fd5b80632d90b0dd116101ab5780632d90b0dd1461029a5780633ae97603146102ba57806343112672146102da578063479249801461030757600080fd5b8063026b3d951461023f578063086fad66146102655780630ca078ec1461027857600080fd5b3661023a57336001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001614610238576040517f0540ddf600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b005b600080fd5b61025261024d366004614805565b610587565b6040519081526020015b60405180910390f35b610252610273366004614931565b6106ef565b61028b610286366004614966565b610b20565b60405161025c93929190614a86565b3480156102a657600080fd5b5061028b6102b5366004614abb565b610ca3565b3480156102c657600080fd5b506102526102d5366004614b3b565b610e22565b3480156102e657600080fd5b506102fa6102f5366004614b9b565b610fb8565b60405161025c9190614bdc565b34801561031357600080fd5b50610327610322366004614bef565b611247565b60405161025c93929190614c56565b6102fa610344366004614c81565b6113b5565b61028b610357366004614931565b611529565b34801561036857600080fd5b506102fa610377366004614b9b565b611ac8565b34801561038857600080fd5b50610252610397366004614b3b565b611b9e565b6102526103aa366004614ce6565b611d58565b6102526103bd366004614d22565b611e47565b6102526103d0366004614de5565b611ff7565b3480156103e157600080fd5b506103276103f0366004614931565b6121d2565b34801561040157600080fd5b50610252610410366004614e93565b6127e8565b34801561042157600080fd5b50610252610430366004614e93565b6129d3565b34801561044157600080fd5b50610327610450366004614c81565b612ae5565b34801561046157600080fd5b50610252610470366004614f18565b612c55565b610252610483366004614de5565b612dec565b34801561049457600080fd5b506102fa6104a3366004614f6c565b612e5e565b3480156104b457600080fd5b506103276104c3366004614931565b612fa7565b6102526104d6366004614ce6565b61317e565b6102526104e9366004614966565b6131ab565b3480156104fa57600080fd5b506102fa610509366004614f98565b61331a565b34801561051a57600080fd5b506102fa610529366004614f6c565b61357e565b61025261053c366004614ff1565b6135f6565b61025261054f366004614ff1565b61377f565b61028b610562366004614931565b613917565b34801561057357600080fd5b50610252610582366004615043565b613aed565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663815483193463086fad6660e01b6040518060e00160405280336001600160a01b031681526020018c6001600160a01b031681526020018b81526020018a815260200189815260200188151581526020018781525060405160240161061891906150e8565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b909216825261068a9160040161518a565b60006040518083038185885af11580156106a8573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f191682016040526106d191908101906151e2565b8060200190518101906106e49190615217565b979650505050505050565b60006106f9613c5f565b610701613ca2565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ba8a2be06107406040850160208601615230565b61074d6020860186615230565b61075a604087018761524d565b610767606089018961524d565b60808a013561077960c08c018c6152b5565b6040518a63ffffffff1660e01b815260040161079d99989796959493929190615390565b6020604051808303816000875af11580156107bc573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107e09190615217565b90506000805b6107f3604085018561524d565b9050811015610af957600061080b604086018661524d565b8381811061081b5761081b61542c565b90506020020160208101906108309190615230565b90506000610841606087018761524d565b848181106108515761085161542c565b9050602002013590508560a001602081019061086d919061545b565b80156108aa57507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316826001600160a01b0316145b15610a2957803410156108e9576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0826040518263ffffffff1660e01b81526004016000604051808303818588803b15801561094457600080fd5b505af1158015610958573d6000803e3d6000fd5b50506040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301523060248301526044820186905294975087947f000000000000000000000000000000000000000000000000000000000000000016935063ed2438cd92506064019050600060405180830381600087803b158015610a0c57600080fd5b505af1158015610a20573d6000803e3d6000fd5b50505050610ae6565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ed2438cd83610a6660208a018a615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101849052606401600060405180830381600087803b158015610acd57600080fd5b505af1158015610ae1573d6000803e3d6000fd5b505050505b505080610af2906154a7565b90506107e6565b50610b10610b0a6020850185615230565b82613d08565b50610b1b6001600055565b919050565b6060600060607f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018d6001600160a01b031681526020018c81526020018b8152602001600280811115610ba557610ba56154df565b81526020018a1515815260200189815250604051602401610bc69190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b9092168252610c389160040161518a565b60006040518083038185885af1158015610c56573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f19168201604052610c7f91908101906151e2565b806020019051810190610c929190615601565b925092509250955095509592505050565b6060600060607f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863efd85f1460e01b6040518060e00160405280306001600160a01b031681526020018b6001600160a01b031681526020018a8152602001898152602001600280811115610d2757610d276154df565b815260006020820152604090810189905251610d469190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252610db89160040161518a565b6000604051808303816000875af1158015610dd7573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052610dff91908101906151e2565b806020019051810190610e129190615601565b9250925092509450945094915050565b600080610e30868686613d6e565b506040805160e0810182523081526001600160a01b0389811660208301529181018390526fffffffffffffffffffffffffffffffff60608201529192507f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fb24bd5710000000000000000000000000000000000000000000000000000000090608081016002815260006020820152604090810188905251610edd9190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252610f4f9160040161518a565b6000604051808303816000875af1158015610f6e573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052610f9691908101906151e2565b806020019051810190610fa991906156d0565b5090925050505b949350505050565b6060610fc2613c5f565b610fca613ca2565b6040517f3a2d133b0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528481166024830152604482018490527f00000000000000000000000000000000000000000000000000000000000000001690633a2d133b906064016000604051808303816000875af115801561105a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526110829190810190615726565b6040517fca4f28030000000000000000000000000000000000000000000000000000000081526001600160a01b0386811660048301529192506000917f0000000000000000000000000000000000000000000000000000000000000000169063ca4f280390602401600060405180830381865afa158015611107573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261112f919081019061575b565b905060005b8151811015611234577f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663ae63932983838151811061117e5761117e61542c565b6020026020010151878685815181106111995761119961542c565b60209081029190910101516040517fffffffff0000000000000000000000000000000000000000000000000000000060e086901b1681526001600160a01b0393841660048201529290911660248301526044820152606401600060405180830381600087803b15801561120b57600080fd5b505af115801561121f573d6000803e3d6000fd5b505050508061122d906154a7565b9050611134565b50506112406001600055565b9392505050565b60006060807f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863b24bd57160e01b6040518060e00160405280306001600160a01b031681526020018b6001600160a01b031681526020018981526020018a81526020016003808111156112ca576112ca6154df565b8152600060208201526040908101899052516112e99190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b909216825261135b9160040161518a565b6000604051808303816000875af115801561137a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526113a291908101906151e2565b806020019051810190610e1291906156d0565b6040805160e0810182523381526001600160a01b03878116602083015281830186905260608083018890526000608084015285151560a084015260c0830185905292517f0000000000000000000000000000000000000000000000000000000000000000909116916381548319917f7b03c7ba000000000000000000000000000000000000000000000000000000009161145191602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526114c39160040161518a565b6000604051808303816000875af11580156114e2573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261150a91908101906151e2565b80602001905181019061151d91906156d0565b50979650505050505050565b606060006060611537613c5f565b61153f613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316634af29ec46040518060c0016040528087602001602081019061158c9190615230565b6001600160a01b031681526020908101906115a990890189615230565b6001600160a01b031681526020016115c4604089018961524d565b808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152505050908252506060880135602082015260400161161560a0890160808a016157ea565b6002811115611626576116266154df565b815260200161163860c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526116a7919060040161580b565b6000604051808303816000875af11580156116c6573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526116ee9190810190615601565b9194509250905060006001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ca4f28036117366040880160208901615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526001600160a01b039091166004820152602401600060405180830381865afa158015611792573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526117ba919081019061575b565b90506000805b8251811015611aa45760008382815181106117dd576117dd61542c565b6020026020010151905060008783815181106117fb576117fb61542c565b602002602001015190508860a0016020810190611818919061545b565b801561185557507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316826001600160a01b0316145b156119d45780341015611894576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0826040518263ffffffff1660e01b81526004016000604051808303818588803b1580156118ef57600080fd5b505af1158015611903573d6000803e3d6000fd5b50506040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301523060248301526044820186905294975087947f000000000000000000000000000000000000000000000000000000000000000016935063ed2438cd92506064019050600060405180830381600087803b1580156119b757600080fd5b505af11580156119cb573d6000803e3d6000fd5b50505050611a91565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ed2438cd83611a1160208d018d615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101849052606401600060405180830381600087803b158015611a7857600080fd5b505af1158015611a8c573d6000803e3d6000fd5b505050505b505080611a9d906154a7565b90506117c0565b50611ab5610b0a6020880188615230565b5050611ac16001600055565b9193909250565b6060611ad2613c5f565b611ada613ca2565b6040517f3a2d133b0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528481166024830152604482018490527f00000000000000000000000000000000000000000000000000000000000000001690633a2d133b906064016000604051808303816000875af1158015611b6a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052611b929190810190615726565b90506112406001600055565b60008080611bbd87876fffffffffffffffffffffffffffffffff613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863efd85f1460e01b6040518060e00160405280306001600160a01b031681526020018c6001600160a01b031681526020018781526020018a815260200160016002811115611c4257611c426154df565b81526000602082015260409081018a905251611c619190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252611cd39160040161518a565b6000604051808303816000875af1158015611cf2573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052611d1a91908101906151e2565b806020019051810190611d2d9190615601565b50509050808281518110611d4357611d4361542c565b60200260200101519350505050949350505050565b6000611d62613c5f565b611d6a613ca2565b6000806000611d7885613e93565b919450925090506000611d916080870160608801615230565b90506000611da76101208801610100890161545b565b90506000611dc3611dbb60208a018a615230565b848785614074565b9050611dec611dd560208a018a615230565b611de560a08b0160808c01615230565b8685614374565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b031603611e3557611e35610b0a60208a018a615230565b5093945050505050610b1b6001600055565b6000806000611e57898989613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018f6001600160a01b031681526020018881526020018c815260200160016002811115611edd57611edd6154df565b81526020018b151581526020018a815250604051602401611efe9190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b9092168252611f709160040161518a565b60006040518083038185885af1158015611f8e573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f19168201604052611fb791908101906151e2565b806020019051810190611fca9190615601565b50509050808281518110611fe057611fe061542c565b602002602001015193505050509695505050505050565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063815483199034907f68a24fe0000000000000000000000000000000000000000000000000000000009060208101865b81526020018f6001600160a01b031681526020018e6001600160a01b031681526020018d6001600160a01b031681526020018c81526020018b81526020018a8152602001891515815260200188888080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040516120f89190602401615892565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b909216825261216a9160040161518a565b60006040518083038185885af1158015612188573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f191682016040526121b191908101906151e2565b8060200190518101906121c49190615217565b9a9950505050505050505050565b60006060806121df613c5f565b6121e7613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663214578976040518060c001604052808760200160208101906122349190615230565b6001600160a01b0316815260209081019061225190890189615230565b6001600160a01b0316815260200187606001358152602001878060400190612279919061524d565b808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152505050908252506020016122c060a0890160808a01615952565b60038111156122d1576122d16154df565b81526020016122e360c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526123529190600401615973565b6000604051808303816000875af1158015612371573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261239991908101906156d0565b9194509250905060006001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ca4f28036123e16040880160208901615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526001600160a01b039091166004820152602401600060405180830381865afa15801561243d573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612465919081019061575b565b90506000805b82518110156127c75760008582815181106124885761248861542c565b6020026020010151905060008483815181106124a6576124a661542c565b602002602001015190508880604001906124c0919061524d565b848181106124d0576124d061542c565b9050602002013582101561254957816124ec60408b018b61524d565b858181106124fc576124fc61542c565b905060200201356040517f2361f44b000000000000000000000000000000000000000000000000000000008152600401612540929190918252602082015260400190565b60405180910390fd5b61255960c08a0160a08b0161545b565b801561259657507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316816001600160a01b0316145b156126f7576040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b037f000000000000000000000000000000000000000000000000000000000000000081166004830152306024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561264457600080fd5b505af1158015612658573d6000803e3d6000fd5b50506040517f2e1a7d4d000000000000000000000000000000000000000000000000000000008152600481018590527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169250632e1a7d4d9150602401600060405180830381600087803b1580156126d757600080fd5b505af11580156126eb573d6000803e3d6000fd5b505050508193506127b4565b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001663ae6393298261273460208d018d615230565b6040517fffffffff0000000000000000000000000000000000000000000000000000000060e085901b1681526001600160a01b0392831660048201529116602482015260448101859052606401600060405180830381600087803b15801561279b57600080fd5b505af11580156127af573d6000803e3d6000fd5b505050505b5050806127c0906154a7565b905061246b565b50611ab5816127d96020890189615230565b6001600160a01b0316906145ae565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fbe5ae841000000000000000000000000000000000000000000000000000000009060208101600181526020018b6001600160a01b031681526020018a6001600160a01b03168152602001896001600160a01b031681526020018881526020016fffffffffffffffffffffffffffffffff801681526020017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff815260200160001515815260200187878080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250505091525060405161291a9190602401615892565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b909216825261298c9160040161518a565b6000604051808303816000875af11580156129ab573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526106d191908101906151e2565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fbe5ae8410000000000000000000000000000000000000000000000000000000090602081018581526020018b6001600160a01b031681526020018a6001600160a01b03168152602001896001600160a01b03168152602001888152602001600081526020016fffffffffffffffffffffffffffffffff8016815260200160001515815260200187878080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250505091525060405161291a9190602401615892565b60006060807f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03166381548319637b03c7ba60e01b6040518060e00160405280336001600160a01b031681526020018c6001600160a01b031681526020018a81526020018b8152602001600380811115612b6857612b686154df565b8152602001891515815260200188815250604051602401612b899190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612bfb9160040161518a565b6000604051808303816000875af1158015612c1a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612c4291908101906151e2565b806020019051810190610c9291906156d0565b6000806000612c6687866001613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663edfa356863b24bd57160e01b6040518060e00160405280306001600160a01b031681526020018c6001600160a01b031681526020018781526020018b815260200160016003811115612ceb57612ceb6154df565b81526000602082015260409081018a905251612d0a9190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612d7c9160040161518a565b6000604051808303816000875af1158015612d9b573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612dc391908101906151e2565b806020019051810190612dd691906156d0565b50915050808281518110611d4357611d4361542c565b6040805161014081019091523381526000906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063815483199034907f68a24fe00000000000000000000000000000000000000000000000000000000090602081016001612064565b6040516001600160a01b038381166024830152306044830152606482018390526060917f00000000000000000000000000000000000000000000000000000000000000009091169063edfa3568907f5f9815ff00000000000000000000000000000000000000000000000000000000906084015b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252612f449160040161518a565b6000604051808303816000875af1158015612f63573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052612f8b91908101906151e2565b806020019051810190612f9e9190615726565b90505b92915050565b6000606080612fb4613c5f565b612fbc613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663214578976040518060c001604052808760200160208101906130099190615230565b6001600160a01b0316815260209081019061302690890189615230565b6001600160a01b031681526020018760600135815260200187806040019061304e919061524d565b8080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525050509082525060200161309560a0890160808a01615952565b60038111156130a6576130a66154df565b81526020016130b860c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526131279190600401615973565b6000604051808303816000875af1158015613146573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261316e91908101906156d0565b925092509250611ac16001600055565b6000613188613c5f565b613190613ca2565b600061319b83613e93565b509092505050610b1b6001600055565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316638154831934635b34379160e01b6040518060e00160405280336001600160a01b031681526020018b6001600160a01b031681526020018a81526020018981526020016000600281111561322d5761322d6154df565b815260200188151581526020018781525060405160240161324e9190615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e085901b90921682526132c09160040161518a565b60006040518083038185885af11580156132de573d6000803e3d6000fd5b50505050506040513d6000823e601f3d908101601f1916820160405261330791908101906151e2565b80602001905181019061151d9190615601565b6040517fca4f28030000000000000000000000000000000000000000000000000000000081526001600160a01b0384811660048301526060916000917f0000000000000000000000000000000000000000000000000000000000000000169063ca4f280390602401600060405180830381865afa15801561339f573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526133c7919081019061575b565b5167ffffffffffffffff8111156133e0576133e061468f565b604051908082528060200260200182016040528015613409578160200160208202803683370190505b506040805160e0810182523081526001600160a01b038881166020830152918101839052606081018790529192507f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fb24bd57100000000000000000000000000000000000000000000000000000000906080810160008152600060208201526040908101889052516134a79190602401615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526135199160040161518a565b6000604051808303816000875af1158015613538573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261356091908101906151e2565b80602001905181019061357391906156d0565b509695505050505050565b6040516001600160a01b038381166024830152336044830152606482018390526060917f0000000000000000000000000000000000000000000000000000000000000000909116906381548319907f431126720000000000000000000000000000000000000000000000000000000090608401612ed2565b600080613604888787613d6e565b506040805160e0810182523381526001600160a01b038b81166020830152918101839052606081018a90529192507f000000000000000000000000000000000000000000000000000000000000000016906381548319907f7b03c7ba000000000000000000000000000000000000000000000000000000009060808101600281526020018815158152602001878152506040516024016136a49190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526137169160040161518a565b6000604051808303816000875af1158015613735573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261375d91908101906151e2565b80602001905181019061377091906156d0565b50909998505050505050505050565b600080600061378f898888613d6e565b9150915060007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03166381548319637b03c7ba60e01b6040518060e00160405280336001600160a01b031681526020018e6001600160a01b031681526020018781526020018d815260200160016003811115613814576138146154df565b81526020018a15158152602001898152506040516024016138359190615674565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b90921682526138a79160040161518a565b6000604051808303816000875af11580156138c6573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526138ee91908101906151e2565b80602001905181019061390191906156d0565b50915050808281518110611fe057611fe061542c565b606060006060613925613c5f565b61392d613ca2565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316634af29ec46040518060c0016040528087602001602081019061397a9190615230565b6001600160a01b0316815260209081019061399790890189615230565b6001600160a01b031681526020016139b2604089018961524d565b8080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525050509082525060608801356020820152604001613a0360a0890160808a016157ea565b6002811115613a1457613a146154df565b8152602001613a2660c08901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b168152613a95919060040161580b565b6000604051808303816000875af1158015613ab4573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052613adc9190810190615601565b91945092509050611ac16001600055565b6040805160e0810182523081526001600160a01b038581166020830152918101849052600060608201819052917f0000000000000000000000000000000000000000000000000000000000000000169063edfa3568907fefd85f1400000000000000000000000000000000000000000000000000000000906080810185815260006020820152604090810187905251613b899190602401615522565b60408051601f198184030181529181526020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff000000000000000000000000000000000000000000000000000000009485161790525160e084901b9092168252613bfb9160040161518a565b6000604051808303816000875af1158015613c1a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052613c4291908101906151e2565b806020019051810190613c559190615601565b5095945050505050565b600260005403613c9b576040517f3ee5aeb500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6002600055565b336001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001614613d06576040517f089676d5000000000000000000000000000000000000000000000000000000008152336004820152602401612540565b565b80341015613d42576040517fa01a9df600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000613d4e82346159ce565b90508015613d6957613d696001600160a01b038416826145ae565b505050565b6040517fc9c1661b0000000000000000000000000000000000000000000000000000000081526001600160a01b038481166004830152838116602483015260609160009182917f00000000000000000000000000000000000000000000000000000000000000009091169063c9c1661b906044016040805180830381865afa158015613dfe573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613e2291906159e1565b925090508067ffffffffffffffff811115613e3f57613e3f61468f565b604051908082528060200260200182016040528015613e68578160200160208202803683370190505b50925083838381518110613e7e57613e7e61542c565b60200260200101818152505050935093915050565b60008060008360e00135421115613ed6576040517fe08b8af000000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632bfb780c6040518060e00160405280876020016020810190613f239190615a05565b6001811115613f3457613f346154df565b8152602001613f496060890160408a01615230565b6001600160a01b03168152602001613f676080890160608a01615230565b6001600160a01b03168152602001613f8560a0890160808a01615230565b6001600160a01b0316815260a0880135602082015260c08801356040820152606001613fb56101208901896152b5565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050509152506040517fffffffff0000000000000000000000000000000000000000000000000000000060e084901b1681526140249190600401615a26565b6060604051808303816000875af1158015614043573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906140679190615a96565b9196909550909350915050565b60008180156140b457507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316846001600160a01b0316145b156142c9578290507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0846040518263ffffffff1660e01b81526004016000604051808303818588803b15801561411757600080fd5b505af115801561412b573d6000803e3d6000fd5b50506040517fa9059cbb0000000000000000000000000000000000000000000000000000000081526001600160a01b037f000000000000000000000000000000000000000000000000000000000000000081166004830152602482018890527f000000000000000000000000000000000000000000000000000000000000000016935063a9059cbb925060440190506020604051808303816000875af11580156141d9573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906141fd9190615ac4565b506040517f6a256b290000000000000000000000000000000000000000000000000000000081526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660048301527f00000000000000000000000000000000000000000000000000000000000000001690636a256b29906024016020604051808303816000875af115801561429f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906142c39190615217565b50610fb0565b6040517fed2438cd0000000000000000000000000000000000000000000000000000000081526001600160a01b0385811660048301528681166024830152604482018590527f0000000000000000000000000000000000000000000000000000000000000000169063ed2438cd90606401600060405180830381600087803b15801561435457600080fd5b505af1158015614368573d6000803e3d6000fd5b50505050949350505050565b8080156143b257507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b0316145b15614504576040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b038481166004830152306024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561444057600080fd5b505af1158015614454573d6000803e3d6000fd5b50506040517f2e1a7d4d000000000000000000000000000000000000000000000000000000008152600481018590527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169250632e1a7d4d9150602401600060405180830381600087803b1580156144d357600080fd5b505af11580156144e7573d6000803e3d6000fd5b506144ff925050506001600160a01b038516836145ae565b6145a8565b6040517fae6393290000000000000000000000000000000000000000000000000000000081526001600160a01b0384811660048301528581166024830152604482018490527f0000000000000000000000000000000000000000000000000000000000000000169063ae63932990606401600060405180830381600087803b15801561458f57600080fd5b505af11580156145a3573d6000803e3d6000fd5b505050505b50505050565b804710156145ea576040517fcd786059000000000000000000000000000000000000000000000000000000008152306004820152602401612540565b6000826001600160a01b03168260405160006040518083038185875af1925050503d8060008114614637576040519150601f19603f3d011682016040523d82523d6000602084013e61463c565b606091505b5050905080613d69576040517f1425ea4200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6001600160a01b038116811461468c57600080fd5b50565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff811182821017156146e7576146e761468f565b604052919050565b600067ffffffffffffffff8211156147095761470961468f565b5060051b60200190565b600082601f83011261472457600080fd5b81356020614739614734836146ef565b6146be565b82815260059290921b8401810191818101908684111561475857600080fd5b8286015b84811015613573578035835291830191830161475c565b801515811461468c57600080fd5b8035610b1b81614773565b600067ffffffffffffffff8211156147a6576147a661468f565b50601f01601f191660200190565b600082601f8301126147c557600080fd5b81356147d36147348261478c565b8181528460208386010111156147e857600080fd5b816020850160208301376000918101602001919091529392505050565b60008060008060008060c0878903121561481e57600080fd5b863561482981614677565b955060208781013567ffffffffffffffff8082111561484757600080fd5b818a0191508a601f83011261485b57600080fd5b8135614869614734826146ef565b81815260059190911b8301840190848101908d83111561488857600080fd5b938501935b828510156148af5784356148a081614677565b8252938501939085019061488d565b9950505060408a01359250808311156148c757600080fd5b6148d38b848c01614713565b965060608a013595506148e860808b01614781565b945060a08a01359250808311156148fe57600080fd5b505061490c89828a016147b4565b9150509295509295509295565b600060e0828403121561492b57600080fd5b50919050565b60006020828403121561494357600080fd5b813567ffffffffffffffff81111561495a57600080fd5b610fb084828501614919565b600080600080600060a0868803121561497e57600080fd5b853561498981614677565b9450602086013567ffffffffffffffff808211156149a657600080fd5b6149b289838a01614713565b955060408801359450606088013591506149cb82614773565b909250608087013590808211156149e157600080fd5b506149ee888289016147b4565b9150509295509295909350565b600081518084526020808501945080840160005b83811015614a2b57815187529582019590820190600101614a0f565b509495945050505050565b60005b83811015614a51578181015183820152602001614a39565b50506000910152565b60008151808452614a72816020860160208601614a36565b601f01601f19169290920160200192915050565b606081526000614a9960608301866149fb565b8460208401528281036040840152614ab18185614a5a565b9695505050505050565b60008060008060808587031215614ad157600080fd5b8435614adc81614677565b9350602085013567ffffffffffffffff80821115614af957600080fd5b614b0588838901614713565b9450604087013593506060870135915080821115614b2257600080fd5b50614b2f878288016147b4565b91505092959194509250565b60008060008060808587031215614b5157600080fd5b8435614b5c81614677565b93506020850135614b6c81614677565b925060408501359150606085013567ffffffffffffffff811115614b8f57600080fd5b614b2f878288016147b4565b600080600060608486031215614bb057600080fd5b8335614bbb81614677565b92506020840135614bcb81614677565b929592945050506040919091013590565b602081526000612f9e60208301846149fb565b60008060008060808587031215614c0557600080fd5b8435614c1081614677565b935060208501359250604085013567ffffffffffffffff80821115614c3457600080fd5b614c4088838901614713565b93506060870135915080821115614b2257600080fd5b838152606060208201526000614c6f60608301856149fb565b8281036040840152614ab18185614a5a565b600080600080600060a08688031215614c9957600080fd5b8535614ca481614677565b945060208601359350604086013567ffffffffffffffff80821115614cc857600080fd5b614cd489838a01614713565b9450606088013591506149cb82614773565b600060208284031215614cf857600080fd5b813567ffffffffffffffff811115614d0f57600080fd5b8201610140818503121561124057600080fd5b60008060008060008060c08789031215614d3b57600080fd5b8635614d4681614677565b95506020870135614d5681614677565b945060408701359350606087013592506080870135614d7481614773565b915060a087013567ffffffffffffffff811115614d9057600080fd5b61490c89828a016147b4565b60008083601f840112614dae57600080fd5b50813567ffffffffffffffff811115614dc657600080fd5b602083019150836020828501011115614dde57600080fd5b9250929050565b60008060008060008060008060006101008a8c031215614e0457600080fd5b8935614e0f81614677565b985060208a0135614e1f81614677565b975060408a0135614e2f81614677565b965060608a0135955060808a0135945060a08a0135935060c08a0135614e5481614773565b925060e08a013567ffffffffffffffff811115614e7057600080fd5b614e7c8c828d01614d9c565b915080935050809150509295985092959850929598565b60008060008060008060a08789031215614eac57600080fd5b8635614eb781614677565b95506020870135614ec781614677565b94506040870135614ed781614677565b935060608701359250608087013567ffffffffffffffff811115614efa57600080fd5b614f0689828a01614d9c565b979a9699509497509295939492505050565b60008060008060808587031215614f2e57600080fd5b8435614f3981614677565b9350602085013592506040850135614f5081614677565b9150606085013567ffffffffffffffff811115614b8f57600080fd5b60008060408385031215614f7f57600080fd5b8235614f8a81614677565b946020939093013593505050565b600080600060608486031215614fad57600080fd5b8335614fb881614677565b925060208401359150604084013567ffffffffffffffff811115614fdb57600080fd5b614fe7868287016147b4565b9150509250925092565b60008060008060008060c0878903121561500a57600080fd5b863561501581614677565b955060208701359450604087013561502c81614677565b9350606087013592506080870135614d7481614773565b60008060006060848603121561505857600080fd5b833561506381614677565b9250602084013567ffffffffffffffff8082111561508057600080fd5b61508c87838801614713565b935060408601359150808211156150a257600080fd5b50614fe7868287016147b4565b600081518084526020808501945080840160005b83811015614a2b5781516001600160a01b0316875295820195908201906001016150c3565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526151266101008401826150af565b90506060840151601f198085840301608086015261514483836149fb565b9250608086015160a086015260a0860151915061516560c086018315159052565b60c08601519150808584030160e0860152506151818282614a5a565b95945050505050565b602081526000612f9e6020830184614a5a565b600082601f8301126151ae57600080fd5b81516151bc6147348261478c565b8181528460208386010111156151d157600080fd5b610fb0826020830160208701614a36565b6000602082840312156151f457600080fd5b815167ffffffffffffffff81111561520b57600080fd5b610fb08482850161519d565b60006020828403121561522957600080fd5b5051919050565b60006020828403121561524257600080fd5b813561124081614677565b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe184360301811261528257600080fd5b83018035915067ffffffffffffffff82111561529d57600080fd5b6020019150600581901b3603821315614dde57600080fd5b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe18436030181126152ea57600080fd5b83018035915067ffffffffffffffff82111561530557600080fd5b602001915036819003821315614dde57600080fd5b81835260007f07ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff83111561534c57600080fd5b8260051b80836020870137939093016020019392505050565b818352818160208501375060006020828401015260006020601f19601f840116840101905092915050565b600060c082016001600160a01b03808d1684526020818d168186015260c06040860152828b845260e0860190508c935060005b8c8110156153ea5784356153d681614677565b8416825293820193908201906001016153c3565b5085810360608701526153fe818b8d61531a565b935050505085608084015282810360a084015261541c818587615365565b9c9b505050505050505050505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60006020828403121561546d57600080fd5b813561124081614773565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036154d8576154d8615478565b5060010190565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b6003811061551e5761551e6154df565b9052565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526155606101008401826149fb565b905060608401516080840152608084015161557e60a085018261550e565b5060a0840151151560c084015260c0840151601f198483030160e08501526151818282614a5a565b600082601f8301126155b757600080fd5b815160206155c7614734836146ef565b82815260059290921b840181019181810190868411156155e657600080fd5b8286015b8481101561357357805183529183019183016155ea565b60008060006060848603121561561657600080fd5b835167ffffffffffffffff8082111561562e57600080fd5b61563a878388016155a6565b945060208601519350604086015191508082111561565757600080fd5b50614fe78682870161519d565b6004811061551e5761551e6154df565b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160e060608401526156b26101008401826149fb565b905060608401516080840152608084015161557e60a0850182615664565b6000806000606084860312156156e557600080fd5b83519250602084015167ffffffffffffffff8082111561570457600080fd5b615710878388016155a6565b9350604086015191508082111561565757600080fd5b60006020828403121561573857600080fd5b815167ffffffffffffffff81111561574f57600080fd5b610fb0848285016155a6565b6000602080838503121561576e57600080fd5b825167ffffffffffffffff81111561578557600080fd5b8301601f8101851361579657600080fd5b80516157a4614734826146ef565b81815260059190911b820183019083810190878311156157c357600080fd5b928401925b828410156106e45783516157db81614677565b825292840192908401906157c8565b6000602082840312156157fc57600080fd5b81356003811061124057600080fd5b6020815260006001600160a01b0380845116602084015280602085015116604084015250604083015160c0606084015261584860e08401826149fb565b905060608401516080840152608084015161586660a085018261550e565b5060a0840151601f198483030160c08501526151818282614a5a565b6002811061551e5761551e6154df565b602081526158ac6020820183516001600160a01b03169052565b600060208301516158c06040840182615882565b5060408301516001600160a01b03811660608401525060608301516001600160a01b03811660808401525060808301516001600160a01b03811660a08401525060a083015160c083015260c083015160e083015260e08301516101008181850152808501519150506101206159388185018315159052565b840151610140848101529050610fb0610160840182614a5a565b60006020828403121561596457600080fd5b81356004811061124057600080fd5b6020815260006001600160a01b038084511660208401528060208501511660408401525060408301516060830152606083015160c060808401526159ba60e08401826149fb565b9050608084015161586660a0850182615664565b81810381811115612fa157612fa1615478565b600080604083850312156159f457600080fd5b505080516020909101519092909150565b600060208284031215615a1757600080fd5b81356002811061124057600080fd5b60208152615a38602082018351615882565b600060208301516001600160a01b0380821660408501528060408601511660608501528060608601511660808501525050608083015160a083015260a083015160c083015260c083015160e080840152610fb0610100840182614a5a565b600080600060608486031215615aab57600080fd5b8351925060208401519150604084015190509250925092565b600060208284031215615ad657600080fd5b81516112408161477356fea26469706673582212207028703288432ac7d72b5a88168f32cd25eb674ea6926a06d3d050f03e07f47064736f6c63430008150033",
  linkReferences: {},
  deployedLinkReferences: {},
};
