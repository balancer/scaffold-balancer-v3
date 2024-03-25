export const vaultInfo = {
  _format: "hh-sol-artifact-1",
  contractName: "Vault",
  sourceName: "contracts/Vault.sol",
  abi: [
    {
      inputs: [
        {
          internalType: "contract IVaultExtension",
          name: "vaultExtension",
          type: "address",
        },
        {
          internalType: "contract IAuthorizer",
          name: "authorizer",
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
          name: "target",
          type: "address",
        },
      ],
      name: "AddressEmptyCode",
      type: "error",
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
      name: "AfterAddLiquidityHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "AfterInitializeHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "AfterRemoveLiquidityHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "AfterSwapHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "AllZeroInputs",
      type: "error",
    },
    {
      inputs: [],
      name: "AmountGivenZero",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
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
      name: "AmountInAboveMax",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
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
      name: "AmountOutBelowMin",
      type: "error",
    },
    {
      inputs: [],
      name: "BalanceNotSettled",
      type: "error",
    },
    {
      inputs: [],
      name: "BalanceOverflow",
      type: "error",
    },
    {
      inputs: [],
      name: "BeforeAddLiquidityHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "BeforeInitializeHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "BeforeRemoveLiquidityHookFailed",
      type: "error",
    },
    {
      inputs: [],
      name: "BeforeSwapHookFailed",
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
      name: "BptAmountInAboveMax",
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
      name: "BptAmountOutBelowMin",
      type: "error",
    },
    {
      inputs: [],
      name: "CannotReceiveEth",
      type: "error",
    },
    {
      inputs: [],
      name: "CannotSwapSameToken",
      type: "error",
    },
    {
      inputs: [],
      name: "DoesNotSupportAddLiquidityCustom",
      type: "error",
    },
    {
      inputs: [],
      name: "DoesNotSupportRemoveLiquidityCustom",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "allowance",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "needed",
          type: "uint256",
        },
      ],
      name: "ERC20InsufficientAllowance",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "sender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "balance",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "needed",
          type: "uint256",
        },
      ],
      name: "ERC20InsufficientBalance",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "approver",
          type: "address",
        },
      ],
      name: "ERC20InvalidApprover",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "receiver",
          type: "address",
        },
      ],
      name: "ERC20InvalidReceiver",
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
      name: "ERC20InvalidSender",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
      ],
      name: "ERC20InvalidSpender",
      type: "error",
    },
    {
      inputs: [],
      name: "FailedInnerCall",
      type: "error",
    },
    {
      inputs: [],
      name: "InputLengthMismatch",
      type: "error",
    },
    {
      inputs: [],
      name: "InvalidAddLiquidityKind",
      type: "error",
    },
    {
      inputs: [],
      name: "InvalidRemoveLiquidityKind",
      type: "error",
    },
    {
      inputs: [],
      name: "InvalidToken",
      type: "error",
    },
    {
      inputs: [],
      name: "InvalidTokenConfiguration",
      type: "error",
    },
    {
      inputs: [],
      name: "InvalidTokenType",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "uint256",
          name: "index",
          type: "uint256",
        },
      ],
      name: "LockerOutOfBounds",
      type: "error",
    },
    {
      inputs: [],
      name: "MaxTokens",
      type: "error",
    },
    {
      inputs: [],
      name: "MinTokens",
      type: "error",
    },
    {
      inputs: [],
      name: "MultipleNonZeroInputs",
      type: "error",
    },
    {
      inputs: [],
      name: "NoLocker",
      type: "error",
    },
    {
      inputs: [],
      name: "NotStaticCall",
      type: "error",
    },
    {
      inputs: [],
      name: "NotVaultDelegateCall",
      type: "error",
    },
    {
      inputs: [],
      name: "OperationNotSupported",
      type: "error",
    },
    {
      inputs: [],
      name: "PauseBufferPeriodDurationTooLarge",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolAlreadyInitialized",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolAlreadyRegistered",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolInRecoveryMode",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolNotInRecoveryMode",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolNotInitialized",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolNotPaused",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolNotRegistered",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolPauseWindowExpired",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolPaused",
      type: "error",
    },
    {
      inputs: [],
      name: "ProtocolSwapFeePercentageTooHigh",
      type: "error",
    },
    {
      inputs: [],
      name: "ProtocolYieldFeePercentageTooHigh",
      type: "error",
    },
    {
      inputs: [],
      name: "QueriesDisabled",
      type: "error",
    },
    {
      inputs: [],
      name: "ReentrancyGuardReentrantCall",
      type: "error",
    },
    {
      inputs: [],
      name: "RouterNotTrusted",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "uint8",
          name: "bits",
          type: "uint8",
        },
        {
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "SafeCastOverflowedUintDowncast",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "SafeCastOverflowedUintToInt",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "token",
          type: "address",
        },
      ],
      name: "SafeERC20FailedOperation",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "SenderIsNotPauseManager",
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
      name: "SwapFeePercentageTooHigh",
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
      name: "SwapLimit",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
      ],
      name: "TokenAlreadyRegistered",
      type: "error",
    },
    {
      inputs: [],
      name: "TokenNotRegistered",
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
          internalType: "address",
          name: "expectedToken",
          type: "address",
        },
        {
          internalType: "address",
          name: "actualToken",
          type: "address",
        },
      ],
      name: "TokensMismatch",
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
      name: "TotalSupplyTooLow",
      type: "error",
    },
    {
      inputs: [],
      name: "UserDataNotSupported",
      type: "error",
    },
    {
      inputs: [],
      name: "VaultNotPaused",
      type: "error",
    },
    {
      inputs: [],
      name: "VaultPauseWindowDurationTooLarge",
      type: "error",
    },
    {
      inputs: [],
      name: "VaultPauseWindowExpired",
      type: "error",
    },
    {
      inputs: [],
      name: "VaultPaused",
      type: "error",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "locker",
          type: "address",
        },
        {
          internalType: "address",
          name: "caller",
          type: "address",
        },
      ],
      name: "WrongLocker",
      type: "error",
    },
    {
      inputs: [],
      name: "WrongVaultAdminDeployment",
      type: "error",
    },
    {
      inputs: [],
      name: "WrongVaultExtensionDeployment",
      type: "error",
    },
    {
      inputs: [],
      name: "ZeroDivision",
      type: "error",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "owner",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "Approval",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "contract IAuthorizer",
          name: "newAuthorizer",
          type: "address",
        },
      ],
      name: "AuthorizerChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "liquidityProvider",
          type: "address",
        },
        {
          indexed: false,
          internalType: "contract IERC20[]",
          name: "tokens",
          type: "address[]",
        },
        {
          indexed: false,
          internalType: "int256[]",
          name: "deltas",
          type: "int256[]",
        },
      ],
      name: "PoolBalanceChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "PoolInitialized",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: false,
          internalType: "bool",
          name: "paused",
          type: "bool",
        },
      ],
      name: "PoolPausedStateChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: false,
          internalType: "bool",
          name: "recoveryMode",
          type: "bool",
        },
      ],
      name: "PoolRecoveryModeStateChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "factory",
          type: "address",
        },
        {
          components: [
            {
              internalType: "contract IERC20",
              name: "token",
              type: "address",
            },
            {
              internalType: "enum TokenType",
              name: "tokenType",
              type: "uint8",
            },
            {
              internalType: "contract IRateProvider",
              name: "rateProvider",
              type: "address",
            },
            {
              internalType: "bool",
              name: "yieldFeeExempt",
              type: "bool",
            },
          ],
          indexed: false,
          internalType: "struct TokenConfig[]",
          name: "tokenConfig",
          type: "tuple[]",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "pauseWindowEndTime",
          type: "uint256",
        },
        {
          indexed: false,
          internalType: "address",
          name: "pauseManager",
          type: "address",
        },
        {
          components: [
            {
              internalType: "bool",
              name: "shouldCallBeforeInitialize",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallAfterInitialize",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallBeforeSwap",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallAfterSwap",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallBeforeAddLiquidity",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallAfterAddLiquidity",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallBeforeRemoveLiquidity",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "shouldCallAfterRemoveLiquidity",
              type: "bool",
            },
          ],
          indexed: false,
          internalType: "struct PoolHooks",
          name: "hooks",
          type: "tuple",
        },
        {
          components: [
            {
              internalType: "bool",
              name: "supportsAddLiquidityCustom",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "supportsRemoveLiquidityCustom",
              type: "bool",
            },
          ],
          indexed: false,
          internalType: "struct LiquidityManagement",
          name: "liquidityManagement",
          type: "tuple",
        },
      ],
      name: "PoolRegistered",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
        {
          indexed: true,
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "ProtocolFeeCollected",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "token",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "ProtocolSwapFeeCharged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "swapFeePercentage",
          type: "uint256",
        },
      ],
      name: "ProtocolSwapFeePercentageChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "token",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "ProtocolYieldFeeCharged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "yieldFeePercentage",
          type: "uint256",
        },
      ],
      name: "ProtocolYieldFeePercentageChanged",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "contract IERC20",
          name: "tokenIn",
          type: "address",
        },
        {
          indexed: true,
          internalType: "contract IERC20",
          name: "tokenOut",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "amountIn",
          type: "uint256",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "amountOut",
          type: "uint256",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "swapFeeAmount",
          type: "uint256",
        },
      ],
      name: "Swap",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "pool",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "value",
          type: "uint256",
        },
      ],
      name: "Transfer",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: false,
          internalType: "bool",
          name: "paused",
          type: "bool",
        },
      ],
      name: "VaultPausedStateChanged",
      type: "event",
    },
    {
      stateMutability: "payable",
      type: "fallback",
    },
    {
      inputs: [],
      name: "MAX_BUFFER_PERIOD_DURATION",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "MAX_PAUSE_WINDOW_DURATION",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "address",
              name: "to",
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
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct AddLiquidityParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "addLiquidity",
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
      inputs: [],
      name: "getAuthorizer",
      outputs: [
        {
          internalType: "contract IAuthorizer",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
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
          name: "token",
          type: "address",
        },
      ],
      name: "getPoolTokenCountAndIndexOfToken",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "getVaultExtension",
      outputs: [
        {
          internalType: "address",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "bytes",
          name: "data",
          type: "bytes",
        },
      ],
      name: "lock",
      outputs: [
        {
          internalType: "bytes",
          name: "result",
          type: "bytes",
        },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [],
      name: "reentrancyGuardEntered",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            {
              internalType: "address",
              name: "pool",
              type: "address",
            },
            {
              internalType: "address",
              name: "from",
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
              internalType: "enum RemoveLiquidityKind",
              name: "kind",
              type: "uint8",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct RemoveLiquidityParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "removeLiquidity",
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
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
        {
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "sendTo",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
      ],
      name: "settle",
      outputs: [
        {
          internalType: "uint256",
          name: "paid",
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
              name: "amountGivenRaw",
              type: "uint256",
            },
            {
              internalType: "uint256",
              name: "limitRaw",
              type: "uint256",
            },
            {
              internalType: "bytes",
              name: "userData",
              type: "bytes",
            },
          ],
          internalType: "struct SwapParams",
          name: "params",
          type: "tuple",
        },
      ],
      name: "swap",
      outputs: [
        {
          internalType: "uint256",
          name: "amountCalculated",
          type: "uint256",
        },
        {
          internalType: "uint256",
          name: "amountIn",
          type: "uint256",
        },
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
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
        {
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "takeFrom",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      stateMutability: "payable",
      type: "receive",
    },
  ],
  bytecode:
    "0x6101006040523480156200001257600080fd5b506040516200614a3803806200614a833981016040819052620000359162000260565b6001600c81905550306001600160a01b0316826001600160a01b031663fbfa77cf6040518163ffffffff1660e01b8152600401602060405180830381865afa15801562000086573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620000ac91906200029f565b6001600160a01b031614620000d4576040516301ab9d9d60e41b815260040160405180910390fd5b6001600160a01b038216608081905260408051634546891d60e11b81529051638a8d123a916004808201926020929091908290030181865afa1580156200011f573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001459190620002c6565b60a08181525050816001600160a01b03166320c1fb7a6040518163ffffffff1660e01b8152600401602060405180830381865afa1580156200018b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001b19190620002c6565b60e08181525050816001600160a01b031663cd51c12f6040518163ffffffff1660e01b8152600401602060405180830381865afa158015620001f7573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906200021d9190620002c6565b60c052600b80546001600160a01b0319166001600160a01b039290921691909117905550620002e0565b6001600160a01b03811681146200025d57600080fd5b50565b600080604083850312156200027457600080fd5b8251620002818162000247565b6020840151909250620002948162000247565b809150509250929050565b600060208284031215620002b257600080fd5b8151620002bf8162000247565b9392505050565b600060208284031215620002d957600080fd5b5051919050565b60805160a05160c05160e051615e2c6200031e60003960006146ca01526000612a2a0152600050506000818161028501526103400152615e2c6000f3fe6080604052600436106100d65760003560e01c8063aaabadc51161007f578063c9c1661b11610059578063c9c1661b146102a9578063d2c725e0146102de578063ed2438cd14610303578063fc5e93fe14610323576100f4565b8063aaabadc514610224578063ae63932914610256578063b9a8effa14610276576100f4565b80636a256b29116100b05780636a256b29146101bf57806381548319146101ed5780638b19548d1461020d576100f4565b8063214578971461011d5780632bfb780c146101555780634af29ec414610190576100f4565b366100f457604051637911c44b60e11b815260040160405180910390fd5b341561011357604051637911c44b60e11b815260040160405180910390fd5b61011b61033b565b005b34801561012957600080fd5b5061013d61013836600461520c565b610366565b60405161014c93929190615364565b60405180910390f35b34801561016157600080fd5b5061017561017036600461539e565b6105a1565b6040805193845260208401929092529082015260600161014c565b34801561019c57600080fd5b506101b06101ab366004615471565b610b06565b60405161014c9392919061550c565b3480156101cb57600080fd5b506101df6101da366004615537565b610d35565b60405190815260200161014c565b6102006101fb366004615554565b610e04565b60405161014c91906155c5565b34801561021957600080fd5b506101df6276a70081565b34801561023057600080fd5b50600b546001600160a01b03165b6040516001600160a01b03909116815260200161014c565b34801561026257600080fd5b5061011b6102713660046155d8565b610f22565b34801561028257600080fd5b507f000000000000000000000000000000000000000000000000000000000000000061023e565b3480156102b557600080fd5b506102c96102c4366004615619565b610f93565b6040805192835260208301919091520161014c565b3480156102ea57600080fd5b506102f3611012565b604051901515815260200161014c565b34801561030f57600080fd5b5061011b61031e3660046155d8565b611020565b34801561032f57600080fd5b506101df630755580081565b6103647f000000000000000000000000000000000000000000000000000000000000000061107e565b565b60006060806103736110a2565b835161037e81611138565b8451610388611169565b6103918161118f565b60006103a2876000015160016111c1565b90506103b88160200151518860600151516112e3565b60a0810151608082015160608901516000926103d392611307565b8251610100015160c00151909150156104c45787600001516001600160a01b0316631abe476289602001518a608001518b604001518587606001518e60a001516040518763ffffffff1660e01b815260040161043496959493929190615668565b6020604051808303816000875af1158015610453573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061047791906156d9565b151560000361049957604051631557c43360e11b815260040160405180910390fd5b87516104a790836001611406565b60a0820151608083015160608a01516104c1929091611307565b90505b60606104d1838a8461148d565b8651610100015160e00151939b5091995090975091501561059557885160208a0151606085015160a08c0151604051633c7faa1360e21b81526001600160a01b039094169363f1fea84c936105309390928e92889291906004016156fb565b6020604051808303816000875af115801561054f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061057391906156d9565b1515600003610595576040516303a6723b60e31b815260040160405180910390fd5b50505050509193909250565b60008060006105ae6110a2565b83602001516105bc81611138565b84602001516105c9611169565b6105d28161118f565b85608001516000036105f7576040516357a456b760e01b815260040160405180910390fd5b85606001516001600160a01b031686604001516001600160a01b0316036106315760405163a54b181d60e01b815260040160405180910390fd5b6000610642876020015160016111c1565b6020888101516001600160a01b03908116600090815260028084526040808320815160e081018352848152808701859052808301859052606081018590526080810185905260a0810185905260c08101859052828f01519095168452918201909452929020549293509091815260608901516001600160a01b031660009081526002830160205260409020546020820152805115806106e357506020810151155b156107015760405163259ba1ad60e01b815260040160405180910390fd5b805160001990810182526020820180519091019052610721818a85611c2b565b825161072c90611d0d565b60a0820181905215801590610753575060018951600181111561075157610751615652565b145b156107a257604081015160a082015161077c908290670de0b6b3a7640000818103911002611d32565b610786919061576b565b6080820181905260408201805161079e90839061577e565b9052505b82516101000151604001511561086c5788602001516001600160a01b031663b116ea9a6107d08b8487611d81565b6040518263ffffffff1660e01b81526004016107ec91906157a5565b6020604051808303816000875af115801561080b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061082f91906156d9565b15156000036108515760405163e91e17e760e01b815260040160405180910390fd5b6108618960200151846001611406565b61086c818a85611c2b565b610877898285611e39565b8551610100015160600151929a50909850965015610a2457600080808b5160018111156108a6576108a6615652565b146108ba57826060015183604001516108c5565b826040015183606001515b915091508a602001516001600160a01b0316633ac204876040518061012001604052808e6000015160018111156108fe576108fe615652565b81526020018e604001516001600160a01b031681526020018e606001516001600160a01b03168152602001858152602001848152602001886060015187600001518151811061094f5761094f615861565b60200260200101518152602001886060015187602001518151811061097657610976615861565b60200260200101518152602001336001600160a01b031681526020018e60c0015181525085606001516040518363ffffffff1660e01b81526004016109bc929190615877565b6020604051808303816000875af11580156109db573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906109ff91906156d9565b1515600003610a2157604051630568a77b60e21b815260040160405180910390fd5b50505b6000610a818460a00151836020015181518110610a4357610a43615861565b60200260200101518560800151846020015181518110610a6557610a65615861565b602002602001015184608001516121529092919063ffffffff16565b905089606001516001600160a01b03168a604001516001600160a01b03168b602001516001600160a01b03167fd6d34547c69c5ee3d2667625c188acf1006abb93e0ee7cf03925c67cf77604138b8b86604051610af1939291909283526020830191909152604082015260600190565b60405180910390a45050505050509193909250565b606060006060610b146110a2565b8351610b1f81611138565b8451610b29611169565b610b328161118f565b6000610b43876000015160006111c1565b9050610b598160200151518860400151516112e3565b60a081015160808201516040890151600092610b749261216f565b825161010001516080015190915015610c655787600001516001600160a01b03166328a6c4ab89602001518a60800151848c6060015187606001518e60a001516040518763ffffffff1660e01b8152600401610bd596959493929190615931565b6020604051808303816000875af1158015610bf4573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c1891906156d9565b1515600003610c3a576040516305975b2960e11b815260040160405180910390fd5b8751610c4890836000611406565b60a0820151608083015160408a0151610c6292909161216f565b90505b6060610c72838a84612262565b8651610100015160a00151939b50909950975091501561059557885160208a0151606085015160a08c015160405163428e650760e11b81526001600160a01b039094169363851cca0e93610cd093909287928e929190600401615981565b6020604051808303816000875af1158015610cef573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610d1391906156d9565b15156000036105955760405163e124916560e01b815260040160405180910390fd5b6000610d3f612830565b610d476110a2565b6001600160a01b038216600081815260076020526040908190205490516370a0823160e01b81523060048201529091906370a0823190602401602060405180830381865afa158015610d9d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610dc191906159bb565b6001600160a01b0384166000908152600760205260409020819055610de790829061576b565b9150610df483833361285a565b50610dff6001600c55565b919050565b600480546001810182556000919091527f8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b01805473ffffffffffffffffffffffffffffffffffffffff191633179055604080516020601f8401819004810282018101909252828152606091610e98919085908590819084018382808284376000920191909152503393925034915050612876565b9050600454600103610edb5760055415610ec5576040516320f1d86d60e01b815260040160405180910390fd5b610ed160046000614f39565b6000600555610f1c565b6004805480610eec57610eec6159d4565b6000828152602090208101600019908101805473ffffffffffffffffffffffffffffffffffffffff191690550190555b92915050565b610f2a612830565b610f326110a2565b610f3d838233612913565b6001600160a01b03831660009081526007602052604081208054839290610f6590849061576b565b90915550610f7f90506001600160a01b0384168383612920565b610f896001600c55565b505050565b905090565b60008083610fa081612994565b6001600160a01b038516600090815260026020526040812090610fc1825490565b6001600160a01b0387166000908152600284016020526040812054919250819003610fff5760405163259ba1ad60e01b815260040160405180910390fd5b909450600019019250505b509250929050565b6000610f8e600c5460021490565b611028612830565b6110306110a2565b61103b83823361285a565b6001600160a01b0383166000908152600760205260408120805483929061106390849061577e565b90915550610f7f90506001600160a01b0384168330846129c5565b3660008037600080366000845af43d6000803e80801561109d573d6000f35b3d6000fd5b6004546000036110c457604051625185ab60e41b815260040160405180910390fd5b60048054600091906110d89060019061576b565b815481106110e8576110e8615861565b6000918252602090912001546001600160a01b03169050338114611135576040516327c2144960e21b81523360048201526001600160a01b03821660248201526044015b60405180910390fd5b50565b61114181612a04565b61113557604051634bdace1360e01b81526001600160a01b038216600482015260240161112c565b611171612a26565b15610364576040516336a7e2cd60e21b815260040160405180910390fd5b61119881612a64565b156111355760405163d971f59760e01b81526001600160a01b038216600482015260240161112c565b6111c9614f57565b6111d1612830565b60606111dd8484612a78565b8051919350915060005b818110156112cc5760008460200151828151811061120757611207615861565b6020026020010151600001519050600084838151811061122957611229615861565b6020026020010151905060008111156112b9576001600160a01b0382166000908152600a60205260408120805483929061126490849061577e565b92505081905550816001600160a01b0316886001600160a01b03167f0954687c12bae94d7ea785882bbed7766e38d72b5bc620f7c34167edd4f2db75836040516112b091815260200190565b60405180910390a35b5050806112c5906159ea565b90506111e7565b506112d78584612cd3565b5050610f1c6001600c55565b8082146113035760405163aaad13f760e01b815260040160405180910390fd5b5050565b606060008451905061131c8185518551612d8d565b6000816001600160401b0381111561133657611336615047565b60405190808252806020026020018201604052801561135f578160200160208202803683370190505b50905060005b828110156113fa576113cd86828151811061138257611382615861565b602002602001015186838151811061139c5761139c615861565b60200260200101518984815181106113b6576113b6615861565b6020026020010151612dba9092919063ffffffff16565b8282815181106113df576113df615861565b60209081029190910101526113f3816159ea565b9050611365565b509150505b9392505050565b61140f82612dd0565b600061141a84613011565b505091505060005b8360200151518110156114865781818151811061144157611441615861565b60200260200101518460400151828151811061145f5761145f615861565b60200260200101818152505061147684848361325d565b61147f816159ea565b9050611422565b5050505050565b6000606080606061149c612830565b6000606081886080015160038111156114b7576114b7615652565b0361153d57876040015195508860600151516001600160401b038111156114e0576114e0615047565b604051908082528060200260200182016040528015611509578160200160208202803683370190505b5060608a015189516001600160a01b03166000908152600f60205260409020549192506115369188613315565b935061177e565b60018860800151600381111561155557611555615652565b036115e7578760400151955086935061157188606001516133da565b91506115c0896060015183886115a08c600001516001600160a01b03166000908152600f602052604090205490565b8d516115ab90611d0d565b8d516001600160a01b03166316a0b3e0613464565b8584815181106115d2576115d2615861565b6020026020010181935082815250505061177e565b6002886080015160038111156115ff576115ff615652565b036116865786935061161488606001516133da565b915061167c89606001518386858151811061163157611631615861565b602002602001015161165c8c600001516001600160a01b03166000908152600f602052604090205490565b8d5161166790611d0d565b8d516001600160a01b03166380de451d6135e6565b909650905061177e565b60038860800151600381111561169e5761169e615652565b036117655787516001600160a01b03166000908152602081905260409020546116c69061392a565b87600001516001600160a01b031663ab68e28c89602001518a604001518a8d606001518d60a001516040518663ffffffff1660e01b815260040161170e9594939291906156fb565b6000604051808303816000875af115801561172d573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526117559190810190615aa3565b929850909550909350905061177e565b60405163137a9a3960e01b815260040160405180910390fd5b87604001518611156117b4578588604001516040516331d38e0b60e01b815260040161112c929190918252602082015260400190565b6020890151516000816001600160401b038111156117d4576117d4615047565b6040519080825280602002602001820160405280156117fd578160200160208202803683370190505b509050816001600160401b0381111561181857611818615047565b604051908082528060200260200182016040528015611841578160200160208202803683370190505b50965060005b82811015611b6d5760008c60200151828151811061186757611867615861565b602002602001015160000151905060006118a18e87858151811061188d5761188d615861565b60200260200101518f600001518587613955565b9050808e6040015184815181106118ba576118ba615861565b602002602001018181516118ce919061576b565b915081815250506119036008548785815181106118ed576118ed615861565b6020026020010151613a6290919063ffffffff16565b89848151811061191557611915615861565b6020026020010151611927919061577e565b8e60600151848151811061193d5761193d615861565b60200260200101818151611951919061576b565b9052508351829085908590811061196a5761196a615861565b60200260200101906001600160a01b031690816001600160a01b0316815250506119f28e60a0015184815181106119a3576119a3615861565b60200260200101518f6080015185815181106119c1576119c1615861565b60200260200101518b86815181106119db576119db615861565b60200260200101516121529092919063ffffffff16565b8a8481518110611a0457611a04615861565b6020026020010181815250508c606001518381518110611a2657611a26615861565b60200260200101518a8481518110611a4057611a40615861565b60200260200101511015611ad557838381518110611a6057611a60615861565b60200260200101518a8481518110611a7a57611a7a615861565b60200260200101518e606001518581518110611a9857611a98615861565b60209081029190910101516040516317bc2f2360e11b81526001600160a01b0390931660048401526024830191909152604482015260640161112c565b611b12848481518110611aea57611aea615861565b60200260200101518b8581518110611b0457611b04615861565b60200260200101513361285a565b898381518110611b2457611b24615861565b60200260200101518e604001518481518110611b4257611b42615861565b60200260200101818151611b56919061576b565b905250611b6691508290506159ea565b9050611847565b508951611b7a908c612cd3565b600b54600160a01b900460ff16158015611b92575032155b15611baa57611baa8a600001518b602001518a613a8f565b611bbd8a600001518b602001518a613aef565b60208a01518a516001600160a01b0391821691167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c83611bfe8b6000613c93565b604051611c0c929190615b34565b60405180910390a350505050611c226001600c55565b93509350935093565b600082516001811115611c4057611c40615652565b14611ca557611ca08160a00151846020015181518110611c6257611c62615861565b60200260200101518260800151856020015181518110611c8457611c84615861565b60200260200101518460800151612dba9092919063ffffffff16565b611d00565b611d008160a00151846000015181518110611cc257611cc2615861565b60200260200101518260800151856000015181518110611ce457611ce4615861565b60200260200101518460800151613d649092919063ffffffff16565b6040909301929092525050565b6000816080015115611d2157506000919050565b5060a001516001600160401b031690565b600081600003611d5557604051630a0c22c760e01b815260040160405180910390fd5b6000611d69670de0b6b3a764000085615bb8565b90506001836001830304018115150291505092915050565b611dcb6040805160e0810190915280600081526020016000815260200160608152602001600081526020016000815260200160006001600160a01b03168152602001606081525090565b6040518060e0016040528085600001516001811115611dec57611dec615652565b815260200184604001518152602001836060015181526020018460000151815260200184602001518152602001336001600160a01b031681526020018560c0015181525090509392505050565b6000806000611e46612830565b85602001516001600160a01b03166372c98186611e64888888611d81565b6040518263ffffffff1660e01b8152600401611e8091906157a5565b6020604051808303816000875af1158015611e9f573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611ec391906159bb565b6060860152600086516001811115611edd57611edd615652565b03611fbd5760a085015115611f1b5760a08501516060860151611eff91613a62565b60808601819052606086018051611f1790839061576b565b9052505b611f768460a00151866020015181518110611f3857611f38615861565b60200260200101518560800151876020015181518110611f5a57611f5a615861565b602002602001015187606001516121529092919063ffffffff16565b608087015160a08801519194509250839150811015611fb85760a086015160405163e2ea151b60e01b815261112c918391600401918252602082015260400190565b61205a565b6120188460a00151866000015181518110611fda57611fda615861565b60200260200101518560800151876000015181518110611ffc57611ffc615861565b60200260200101518760600151613d7a9092919063ffffffff16565b608087015160a0880151919450849350915082111561205a5760a086015160405163e2ea151b60e01b815261112c918491600401918252602082015260400190565b612077848660800151886020015189606001518960200151613955565b60c086015260408401518551815184929190811061209757612097615861565b602002602001018181516120ab919061577e565b90525060c08501516040850151602087015181518492919081106120d1576120d1615861565b60200260200101516120e3919061576b565b6120ed919061576b565b846040015186602001518151811061210757612107615861565b602002602001018181525050612121866020015185612cd3565b61213086604001518333612913565b61213f8660600151823361285a565b6121496001600c55565b93509350939050565b6000612167846121628585613a62565b613d8f565b949350505050565b60606000845190506121848185518551612d8d565b6000816001600160401b0381111561219e5761219e615047565b6040519080825280602002602001820160405280156121c7578160200160208202803683370190505b50905060005b828110156113fa576122358682815181106121ea576121ea615861565b602002602001015186838151811061220457612204615861565b602002602001015189848151811061221e5761221e615861565b6020026020010151613d649092919063ffffffff16565b82828151811061224757612247615861565b602090810291909101015261225b816159ea565b90506121cd565b60608060006060612271612830565b602087015151606060008860800151600281111561229157612291615652565b036122ef578694506122e58960600151886122c58b600001516001600160a01b03166000908152600f602052604090205490565b8c516122d090611d0d565b8c516001600160a01b03166380de451d613db0565b9094509050612490565b60018860800151600281111561230757612307615652565b036123985787606001519350600061231e886133da565b90508795506123708a6060015182876123508d600001516001600160a01b03166000908152600f602052604090205490565b8e5161235b90611d0d565b8e516001600160a01b03166316a0b3e0614165565b87838151811061238257612382615861565b6020026020010181945082815250505050612490565b6002886080015160028111156123b0576123b0615652565b036124775787516001600160a01b03166000908152602081905260409020546123d8906142f5565b87600001516001600160a01b031663e4c436638960200151898b606001518d606001518d60a001516040518663ffffffff1660e01b8152600401612420959493929190615981565b6000604051808303816000875af115801561243f573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526124679190810190615bcf565b9297509095509093509050612490565b604051636c02b39560e01b815260040160405180910390fd5b87606001518410156124c5576060880151604051638d261d5d60e01b815261112c918691600401918252602082015260400190565b816001600160401b038111156124dd576124dd615047565b604051908082528060200260200182016040528015612506578160200160208202803683370190505b5095506000826001600160401b0381111561252357612523615047565b60405190808252806020026020018201604052801561254c578160200160208202803683370190505b50905060005b838110156127ac5760008b60200151828151811061257257612572615861565b60200260200101516000015190508083838151811061259357612593615861565b60200260200101906001600160a01b031690816001600160a01b03168152505060006125df8d8685815181106125cb576125cb615861565b60200260200101518e600001518587613955565b9050600061264b8e60a0015185815181106125fc576125fc615861565b60200260200101518f60800151868151811061261a5761261a615861565b60200260200101518c878151811061263457612634615861565b6020026020010151613d7a9092919063ffffffff16565b90508c60400151848151811061266357612663615861565b60200260200101518111156126c75782818e60400151868151811061268a5761268a615861565b60209081029190910101516040516323b6a17960e21b81526001600160a01b0390931660048401526024830191909152604482015260640161112c565b6126d2838233612913565b6126dc828261576b565b8e6040015185815181106126f2576126f2615861565b60200260200101818151612706919061577e565b915081815250506127256008548786815181106118ed576118ed615861565b8a858151811061273757612737615861565b6020026020010151612749919061576b565b8e60600151858151811061275f5761275f615861565b60200260200101818151612773919061577e565b9052508a5181908c908690811061278c5761278c615861565b602002602001018181525050505050806127a5906159ea565b9050612552565b5088516127b9908b612cd3565b6127cc89600001518a6020015187614320565b602089015189516001600160a01b0391821691167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c8361280d8b6001613c93565b60405161281b929190615b34565b60405180910390a3505050611c226001600c55565b6002600c540361285357604051633ee5aeb560e01b815260040160405180910390fd5b6002600c55565b610f898361286784614470565b61287090615c25565b836144ba565b60608147101561289b5760405163cd78605960e01b815230600482015260240161112c565b600080856001600160a01b031684866040516128b79190615c41565b60006040518083038185875af1925050503d80600081146128f4576040519150601f19603f3d011682016040523d82523d6000602084013e6128f9565b606091505b509150915061290986838361458e565b9695505050505050565b610f898361287084614470565b6040516001600160a01b03838116602483015260448201839052610f8991859182169063a9059cbb906064015b604051602081830303815290604052915060e01b6020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff83818316178352505050506145ea565b61299d8161464d565b611135576040516327946f5760e21b81526001600160a01b038216600482015260240161112c565b6040516001600160a01b0384811660248301528381166044830152606482018390526129fe9186918216906323b872dd9060840161294d565b50505050565b6001600160a01b038116600090815260208190526040812054610f1c90614675565b60007f00000000000000000000000000000000000000000000000000000000000000004211158015610f8e575050600b54600160a81b900460ff1690565b600080612a7083614691565b509392505050565b612a80614f57565b6060612a8b84613011565b855260a08501526040808501919091526020808501929092526001600160a01b03861660009081526002909252812090612ac3825490565b9050806001600160401b03811115612add57612add615047565b604051908082528060200260200182016040528015612b06578160200160208202803683370190505b509250806001600160401b03811115612b2157612b21615047565b604051908082528060200260200182016040528015612b4a578160200160208202803683370190505b506060850152600954612b5c85612dd0565b8451602001516000908015612b715750600082115b8015612b805750855160600151155b905060005b83811015612cc757600087602001518281518110612ba557612ba5615861565b6020026020010151602001519050612bbe888a8461325d565b60006002826002811115612bd457612bd4615652565b1480612c1e57506001826002811115612bef57612bef615652565b148015612c1e575088602001518381518110612c0d57612c0d615861565b602090810291909101015160600151155b9050838015612c2a5750805b15612cb45760008381526001888101602052604082200154612c52908b9060801c86896146fd565b90508015612cb25780898581518110612c6d57612c6d615861565b602002602001018181525050808a604001518581518110612c9057612c90615861565b60200260200101818151612ca4919061576b565b905250612cb28a8c8661325d565b505b505080612cc0906159ea565b9050612b85565b50505050509250929050565b6001600160a01b0382166000908152600260205260409081902060a08301516080840151928401519192612d0892919061216f565b606083015260005b8260400151518110156129fe57612d7d81612d6585604001518481518110612d3a57612d3a615861565b602002602001015186606001518581518110612d5857612d58615861565b602002602001015161478e565b60009182526001808601602052604090922090910155565b612d86816159ea565b9050612d10565b8183141580612d9c5750808214155b15610f895760405163aaad13f760e01b815260040160405180910390fd5b600061216782612dca8686613a62565b90613a62565b602081015151806001600160401b03811115612dee57612dee615047565b604051908082528060200260200182016040528015612e17578160200160208202803683370190505b50608083015260005b81811015610f8957600083602001518281518110612e4057612e40615861565b602002602001015160200151905060006002811115612e6157612e61615652565b816002811115612e7357612e73615652565b03612ea857670de0b6b3a764000084608001518381518110612e9757612e97615861565b602002602001018181525050613000565b6001816002811115612ebc57612ebc615652565b03612f5a5783602001518281518110612ed757612ed7615861565b6020026020010151604001516001600160a01b031663679aefce6040518163ffffffff1660e01b8152600401602060405180830381865afa158015612f20573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612f4491906159bb565b84608001518381518110612e9757612e97615861565b6002816002811115612f6e57612f6e615652565b03612fe75783602001518281518110612f8957612f89615861565b6020026020010151600001516001600160a01b03166307a2d13a670de0b6b3a76400006040518263ffffffff1660e01b8152600401612fca91815260200190565b602060405180830381865afa158015612f20573d6000803e3d6000fd5b604051636fa2831960e11b815260040160405180910390fd5b5061300a816159ea565b9050612e20565b606080606061301e614f93565b6001600160a01b038516600090815260026020908152604080832060039092528220909161304a835490565b6001600160a01b03891660009081526020819052604090205490915061306f906147e5565b9350806001600160401b0381111561308957613089615047565b6040519080825280602002602001820160405280156130db57816020015b6040805160808101825260008082526020808301829052928201819052606082015282526000199092019101816130a75790505b509650806001600160401b038111156130f6576130f6615047565b60405190808252806020026020018201604052801561311f578160200160208202803683370190505b50955061312c848261494c565b945060008060005b838110156132505760008181526001808801602052604090912080549101546001600160a01b0390911690935091506fffffffffffffffffffffffffffffffff831689828151811061318857613188615861565b6020908102919091018101919091526001600160a01b038381166000908152878352604090819020815160808101909252805492831682529092909190830190600160a01b900460ff1660028111156131e3576131e3615652565b60028111156131f4576131f4615652565b8152600191909101546001600160a01b0381166020830152600160a01b900460ff1615156040909101528a518b908390811061323257613232615861565b60200260200101819052508080613248906159ea565b915050613134565b5050505050509193509193565b61502a600083600181111561327457613274615652565b1461328157613d64613285565b612dba5b90506132ed846040015183815181106132a0576132a0615861565b60200260200101518560a0015184815181106132be576132be615861565b6020026020010151866080015185815181106132dc576132dc615861565b60200260200101518463ffffffff16565b8460600151838151811061330357613303615861565b60200260200101818152505050505050565b606060006133238385613d8f565b905084516001600160401b0381111561333e5761333e615047565b604051908082528060200260200182016040528015613367578160200160208202803683370190505b50915060005b85518110156133d1576133a28287838151811061338c5761338c615861565b6020026020010151614a1c90919063ffffffff16565b8382815181106133b4576133b4615861565b6020908102919091010152806133c9816159ea565b91505061336d565b50509392505050565b80518060005b8181101561343d578381815181106133fa576133fa615861565b602002602001015160001461342d5781831461342957604051636b8c3be560e01b815260040160405180910390fd5b8092505b613436816159ea565b90506133e0565b5080821061345e57604051631f91af7760e21b815260040160405180910390fd5b50919050565b6000606081613473888861576b565b9050600085858c8c613485868d611d32565b6040518463ffffffff1660e01b81526004016134a393929190615c5d565b602060405180830381865afa1580156134c0573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906134e491906159bb565b90506000818c8c815181106134fb576134fb615861565b602002602001015161350d919061576b565b905060006135478a6135418f8f8151811061352a5761352a615861565b602002602001015187613a6290919063ffffffff16565b90613d8f565b90506000613555848361576b565b90506000613563828c613a62565b90508e516001600160401b0381111561357e5761357e615047565b6040519080825280602002602001820160405280156135a7578160200160208202803683370190505b50965080878f815181106135bd576135bd615861565b60209081029190910101526135d2818561576b565b975050505050505097509795505050505050565b865160009060609082816001600160401b0381111561360757613607615047565b604051908082528060200260200182016040528015613630578160200160208202803683370190505b50905060005b8b51811015613688578b818151811061365157613651615861565b602002602001015182828151811061366b5761366b615861565b602090810291909101015280613680816159ea565b915050613636565b5088818b8151811061369c5761369c615861565b60200260200101516136ae919061576b565b818b815181106136c0576136c0615861565b602002602001018181525050600086868d6040518263ffffffff1660e01b81526004016136ed9190615c82565b602060405180830381865afa15801561370a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061372e91906159bb565b90506000828c8151811061374457613744615861565b60200260200101516137d38e8e8151811061376157613761615861565b6020026020010151612dca858c8c896040518263ffffffff1660e01b815260040161378c9190615c82565b602060405180830381865afa1580156137a9573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906137cd91906159bb565b90611d32565b6137dd919061576b565b90506000816137fd670de0b6b3a76400008c8103908d10025b8490611d32565b613807919061576b565b905080848e8151811061381c5761381c615861565b602002602001015161382e919061576b565b848e8151811061384057613840615861565b60200260200101818152505060008989866040518263ffffffff1660e01b815260040161386d9190615c82565b602060405180830381865afa15801561388a573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906138ae91906159bb565b9050856001600160401b038111156138c8576138c8615047565b6040519080825280602002602001820160405280156138f1578160200160208202803683370190505b50965081878f8151811061390757613907615861565b60209081029190910101526135d284613541613923848361576b565b8f90613a62565b61393381614a3d565b15156000036111355760405163033c2a5760e61b815260040160405180910390fd5b6000808511801561396857506000600854115b80156139775750855160600151155b15613a59576139d78660a00151838151811061399557613995615861565b6020026020010151876080015184815181106139b3576139b3615861565b60200260200101516139d060085489613a6290919063ffffffff16565b9190612152565b6001600160a01b0384166000908152600a6020526040812080549293508392909190613a0490849061577e565b92505081905550826001600160a01b0316846001600160a01b03167f7ed2189f578f040de476a40b0677b8f117d19e127bcd551586055aca4823661483604051613a5091815260200190565b60405180910390a35b95945050505050565b600080613a6f8385615bb8565b90506001670de0b6b3a76400006001830304018115150291505092915050565b3215613aae576040516333fc255960e11b815260040160405180910390fd5b6001600160a01b038084166000908152600d6020908152604080832093861683529290529081208054839290613ae590849061577e565b9091555050505050565b6001600160a01b038216613b2157604051634b637e8f60e11b81526001600160a01b038316600482015260240161112c565b6001600160a01b038084166000908152600d602090815260408083209386168352929052205480821115613b815760405163391434e360e21b81526001600160a01b0384166004820152602481018290526044810183905260640161112c565b6001600160a01b038085166000818152600d6020908152604080832094881683529381528382208686039055918152600f90915290812054613bc490849061576b565b9050613bcf81614adc565b6001600160a01b038581166000818152600f60209081526040808320869055518781529193881692917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b03858116600483015260006024830152604482018590528616906323de665190606401600060405180830381600087803b158015613c7457600080fd5b505af1158015613c88573d6000803e3d6000fd5b505050505050505050565b606082516001600160401b03811115613cae57613cae615047565b604051908082528060200260200182016040528015613cd7578160200160208202803683370190505b50905060005b8351811015613d5d5782613d1357838181518110613cfd57613cfd615861565b6020026020010151613d0e90615c25565b613d2e565b838181518110613d2557613d25615861565b60200260200101515b828281518110613d4057613d40615861565b602090810291909101015280613d55816159ea565b915050613cdd565b5092915050565b600061216782613d748686614a1c565b90614a1c565b600061216784613d8a8585614a1c565b611d32565b600080613da4670de0b6b3a764000085615bb8565b90506121678382615c95565b855160009060609082816001600160401b03811115613dd157613dd1615047565b604051908082528060200260200182016040528015613dfa578160200160208202803683370190505b509050816001600160401b03811115613e1557613e15615047565b604051908082528060200260200182016040528015613e3e578160200160208202803683370190505b50925060005b8a51811015613eba57898181518110613e5f57613e5f615861565b60200260200101518b8281518110613e7957613e79615861565b6020026020010151613e8b919061577e565b828281518110613e9d57613e9d615861565b602090810291909101015280613eb2816159ea565b915050613e44565b50600086868c6040518263ffffffff1660e01b8152600401613edc9190615c82565b602060405180830381865afa158015613ef9573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613f1d91906159bb565b905060008787846040518263ffffffff1660e01b8152600401613f409190615c82565b602060405180830381865afa158015613f5d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613f8191906159bb565b90506000613f8f8284613d8f565b905060005b8d518110156140d557613fc98e8281518110613fb257613fb2615861565b602002602001015183613a6290919063ffffffff16565b858281518110613fdb57613fdb615861565b602002602001015111156140c35760006140178f838151811061400057614000615861565b602002602001015184613a6290919063ffffffff16565b86838151811061402957614029615861565b602002602001015161403b919061576b565b9050614047818d613a62565b88838151811061405957614059615861565b60200260200101818152505087828151811061407757614077615861565b602002602001015186838151811061409157614091615861565b60200260200101516140a3919061576b565b8683815181106140b5576140b5615861565b602002602001018181525050505b806140cd816159ea565b915050613f94565b5060008989866040518263ffffffff1660e01b81526004016140f79190615c82565b602060405180830381865afa158015614114573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061413891906159bb565b905061415261414b85613541818561576b565b8d90614a1c565b9750505050505050965096945050505050565b6000606081614174878961577e565b9050600085858c8c614186868d611d32565b6040518463ffffffff1660e01b81526004016141a493929190615c5d565b602060405180830381865afa1580156141c1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906141e591906159bb565b905060008b8b815181106141fb576141fb615861565b60200260200101518261420e919061576b565b9050600061422b8a6135418f8f8151811061352a5761352a615861565b90506000818e8e8151811061424257614242615861565b602002602001015184614255919061577e565b61425f919061576b565b905060008161427c670de0b6b3a76400008d8103908e10026137f6565b614286919061576b565b90508e516001600160401b038111156142a1576142a1615047565b6040519080825280602002602001820160405280156142ca578160200160208202803683370190505b50965080878f815181106142e0576142e0615861565b60209081029190910101526135d2818561577e565b6142fe81614b0c565b15156000036111355760405163121db02f60e21b815260040160405180910390fd5b6001600160a01b0382166143525760405163ec442f0560e01b81526001600160a01b038316600482015260240161112c565b6001600160a01b0383166000908152600f602052604081205461437690839061577e565b6001600160a01b038086166000908152600d6020908152604080832093881683529290522080548401905590506143ac81614adc565b6001600160a01b038481166000818152600f6020908152604080832086905551868152938716939192917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b8152600060048201526001600160a01b038481166024830152604482018490528516906323de665190606401600060405180830381600087803b15801561445257600080fd5b505af1158015614466573d6000803e3d6000fd5b5050505050505050565b60007f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8211156144b65760405163123baf0360e11b81526004810183905260240161112c565b5090565b816000036144c757505050565b6001600160a01b0381163314614501576040516327c2144960e21b81526001600160a01b038216600482015233602482015260440161112c565b6001600160a01b038082166000908152600660209081526040808320938716835292905290812054906145348483615cb7565b90508060000361454d576005805460001901905561455f565b8160000361455f576005805460010190555b6001600160a01b0392831660009081526006602090815260408083209790951682529590955291909320555050565b6060826145a35761459e82614b1c565b6113ff565b81511580156145ba57506001600160a01b0384163b155b156145e357604051639996b31560e01b81526001600160a01b038516600482015260240161112c565b50806113ff565b60006145ff6001600160a01b03841683614b45565b9050805160001415801561462457508080602001905181019061462291906156d9565b155b15610f8957604051635274afe760e01b81526001600160a01b038416600482015260240161112c565b6001600160a01b038116600090815260208190526040812054610f1c90600060018216610f1c565b6000610f1c614685826001615cdf565b839060ff161c60011690565b6001600160a01b0381166000908152602081905260408120548190819081906146b990614b53565b915091508180156146f357506146ef7f00000000000000000000000000000000000000000000000000000000000000008261577e565b4211155b9590945092505050565b6000808560600151848151811061471657614716615861565b602002602001015190508481111561478557600085820390506147818760a00151868151811061474857614748615861565b60200260200101518860800151878151811061476657614766615861565b60200260200101516139d08785614a1c90919063ffffffff16565b9250505b50949350505050565b60006fffffffffffffffffffffffffffffffff8311806147bd57506fffffffffffffffffffffffffffffffff82115b156147db576040516389560ca160e01b815260040160405180910390fd5b6113ff8383614b79565b6147ed614f93565b60405180610140016040528061480884600060018216610f1c565b1515815260200161481884614675565b1515815260200161482884614b89565b1515815260200161483884614b99565b1515815260200161484884614ba9565b1515815260200161485884614bb9565b6001600160401b0316815260200161486f84614c7d565b62ffffff16815260200161488284614d49565b63ffffffff1681526020016040518061010001604052806148a286614e22565b151581526020016148b286614e32565b151581526020016148c286614e42565b151581526020016148d286614e52565b151581526020016148e286614e62565b151581526020016148f286614e72565b1515815260200161490286614e82565b1515815260200161491286614e92565b15158152508152602001604051806040016040528061493086614b0c565b1515815260200161494086614a3d565b15159052905292915050565b60606000826001600160401b0381111561496857614968615047565b604051908082528060200260200182016040528015614991578160200160208202803683370190505b5060c085015190915062ffffff1660005b84811015614a125760006149c36149ba600584615bb8565b84901c601f1690565b90506149d081600a615dd4565b6149e290670de0b6b3a7640000615bb8565b8483815181106149f4576149f4615861565b60209081029190910101525080614a0a816159ea565b9150506149a2565b5090949350505050565b600080614a298385615bb8565b9050612167670de0b6b3a764000082615c95565b6000610f1c614a4d826001615cdf565b614a58906001615cdf565b614a63906001615cdf565b614a6e906001615cdf565b614a79906001615cdf565b614a84906001615cdf565b614a8f906001615cdf565b614a9a906001615cdf565b614aa5906001615cdf565b614ab0906001615cdf565b614abb906001615cdf565b614ac6906001615cdf565b614ad1906001615cdf565b614685906001615cdf565b620f424081101561113557604051634ddaf4a960e01b815260048101829052620f4240602482015260440161112c565b6000610f1c614a58826001615cdf565b805115614b2c5780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b60606113ff83836000612876565b600080614b5f83614b89565b614b6884614d49565b909463ffffffff9091169350915050565b60006113ff83608084901b61577e565b6000610f1c614ad1826001615cdf565b6000610f1c614a63826001615cdf565b6000610f1c614ac6826001615cdf565b6000610f1c614c78614bcc836001615cdf565b614bd7906001615cdf565b614be2906001615cdf565b614bed906001615cdf565b614bf8906001615cdf565b614c03906001615cdf565b614c0e906001615cdf565b614c19906001615cdf565b614c24906001615cdf565b614c2f906001615cdf565b614c3a906001615cdf565b614c45906001615cdf565b614c50906001615cdf565b614c5b906001615cdf565b614c66906001615cdf565b60ff1684901c6001600160401b031690565b614ea2565b6000610f1c614d446040614c92846001615cdf565b614c9d906001615cdf565b614ca8906001615cdf565b614cb3906001615cdf565b614cbe906001615cdf565b614cc9906001615cdf565b614cd4906001615cdf565b614cdf906001615cdf565b614cea906001615cdf565b614cf5906001615cdf565b614d00906001615cdf565b614d0b906001615cdf565b614d16906001615cdf565b614d21906001615cdf565b614d2c906001615cdf565b614d369190615cdf565b60ff1684901c62ffffff1690565b614ed8565b6000610f1c614e1d60186040614d60856001615cdf565b614d6b906001615cdf565b614d76906001615cdf565b614d81906001615cdf565b614d8c906001615cdf565b614d97906001615cdf565b614da2906001615cdf565b614dad906001615cdf565b614db8906001615cdf565b614dc3906001615cdf565b614dce906001615cdf565b614dd9906001615cdf565b614de4906001615cdf565b614def906001615cdf565b614dfa906001615cdf565b614e049190615cdf565b614e0e9190615cdf565b60ff1684901c63ffffffff1690565b614f08565b6000610f1c614a79826001615cdf565b6000610f1c614a6e826001615cdf565b6000610f1c614abb826001615cdf565b6000610f1c614ab0826001615cdf565b6000610f1c614aa5826001615cdf565b6000610f1c614a9a826001615cdf565b6000610f1c614a8f826001615cdf565b6000610f1c614a84826001615cdf565b60006001600160401b038211156144b657604080516306dfcc6560e41b815260048101919091526024810183905260440161112c565b600062ffffff8211156144b6576040516306dfcc6560e41b8152601860048201526024810183905260440161112c565b600063ffffffff8211156144b6576040516306dfcc6560e41b8152602060048201526024810183905260440161112c565b50805460008255906000526020600020908101906111359190615032565b6040518060c00160405280614f6a614f93565b815260200160608152602001606081526020016060815260200160608152602001606081525090565b6040805161014081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e080880187905288516101008082018b52888252818801899052818b01899052958101889052938401879052918301869052820185905281018490529084015283518085019094528184528301529061012082015290565b610364615de0565b5b808211156144b65760008155600101615033565b634e487b7160e01b600052604160045260246000fd5b60405160c081016001600160401b038111828210171561507f5761507f615047565b60405290565b60405160e081016001600160401b038111828210171561507f5761507f615047565b604051601f8201601f191681016001600160401b03811182821017156150cf576150cf615047565b604052919050565b6001600160a01b038116811461113557600080fd5b8035610dff816150d7565b60006001600160401b0382111561511057615110615047565b5060051b60200190565b600082601f83011261512b57600080fd5b8135602061514061513b836150f7565b6150a7565b82815260059290921b8401810191818101908684111561515f57600080fd5b8286015b8481101561517a5780358352918301918301615163565b509695505050505050565b803560048110610dff57600080fd5b60006001600160401b038211156151ad576151ad615047565b50601f01601f191660200190565b600082601f8301126151cc57600080fd5b81356151da61513b82615194565b8181528460208386010111156151ef57600080fd5b816020850160208301376000918101602001919091529392505050565b60006020828403121561521e57600080fd5b81356001600160401b038082111561523557600080fd5b9083019060c0828603121561524957600080fd5b61525161505d565b61525a836150ec565b8152615268602084016150ec565b60208201526040830135604082015260608301358281111561528957600080fd5b6152958782860161511a565b6060830152506152a760808401615185565b608082015260a0830135828111156152be57600080fd5b6152ca878286016151bb565b60a08301525095945050505050565b600081518084526020808501945080840160005b83811015615309578151875295820195908201906001016152ed565b509495945050505050565b60005b8381101561532f578181015183820152602001615317565b50506000910152565b60008151808452615350816020860160208601615314565b601f01601f19169290920160200192915050565b83815260606020820152600061537d60608301856152d9565b82810360408401526129098185615338565b803560028110610dff57600080fd5b6000602082840312156153b057600080fd5b81356001600160401b03808211156153c757600080fd5b9083019060e082860312156153db57600080fd5b6153e3615085565b6153ec8361538f565b81526153fa602084016150ec565b602082015261540b604084016150ec565b604082015261541c606084016150ec565b60608201526080830135608082015260a083013560a082015260c08301358281111561544757600080fd5b615453878286016151bb565b60c08301525095945050505050565b803560038110610dff57600080fd5b60006020828403121561548357600080fd5b81356001600160401b038082111561549a57600080fd5b9083019060c082860312156154ae57600080fd5b6154b661505d565b6154bf836150ec565b81526154cd602084016150ec565b60208201526040830135828111156154e457600080fd5b6154f08782860161511a565b604083015250606083013560608201526152a760808401615462565b60608152600061551f60608301866152d9565b84602084015282810360408401526129098185615338565b60006020828403121561554957600080fd5b81356113ff816150d7565b6000806020838503121561556757600080fd5b82356001600160401b038082111561557e57600080fd5b818501915085601f83011261559257600080fd5b8135818111156155a157600080fd5b8660208285010111156155b357600080fd5b60209290920196919550909350505050565b6020815260006113ff6020830184615338565b6000806000606084860312156155ed57600080fd5b83356155f8816150d7565b92506020840135615608816150d7565b929592945050506040919091013590565b6000806040838503121561562c57600080fd5b8235615637816150d7565b91506020830135615647816150d7565b809150509250929050565b634e487b7160e01b600052602160045260246000fd5b6001600160a01b038716815260006004871061568657615686615652565b86602083015285604083015260c060608301526156a660c08301866152d9565b82810360808401526156b881866152d9565b905082810360a08401526156cc8185615338565b9998505050505050505050565b6000602082840312156156eb57600080fd5b815180151581146113ff57600080fd5b6001600160a01b038616815284602082015260a06040820152600061572360a08301866152d9565b828103606084015261573581866152d9565b905082810360808401526157498185615338565b98975050505050505050565b634e487b7160e01b600052601160045260246000fd5b81810381811115610f1c57610f1c615755565b80820180821115610f1c57610f1c615755565b600281106157a1576157a1615652565b9052565b6000602080835261010083016157be8285018651615791565b8482015160408581019190915285015160e060608601528051918290528201906000906101208601905b8083101561580857835182529284019260019290920191908401906157e8565b5060608701516080870152608087015160a087015260a0870151935061583960c08701856001600160a01b03169052565b60c0870151868203601f190160e088015293506158568185615338565b979650505050505050565b634e487b7160e01b600052603260045260246000fd5b60408152615889604082018451615791565b600060208401516158a560608401826001600160a01b03169052565b5060408401516001600160a01b038116608084015250606084015160a0830152608084015160c083015260a084015160e083015260c0840151610100818185015260e08601519150610120615904818601846001600160a01b03169052565b818701519250806101408601525050615921610160840182615338565b9150508260208301529392505050565b6001600160a01b038716815260006003871061594f5761594f615652565b86602083015260c0604083015261596960c08301876152d9565b85606084015282810360808401526156b881866152d9565b6001600160a01b038616815260a0602082015260006159a360a08301876152d9565b856040840152828103606084015261573581866152d9565b6000602082840312156159cd57600080fd5b5051919050565b634e487b7160e01b600052603160045260246000fd5b6000600182016159fc576159fc615755565b5060010190565b600082601f830112615a1457600080fd5b81516020615a2461513b836150f7565b82815260059290921b84018101918181019086841115615a4357600080fd5b8286015b8481101561517a5780518352918301918301615a47565b600082601f830112615a6f57600080fd5b8151615a7d61513b82615194565b818152846020838601011115615a9257600080fd5b612167826020830160208701615314565b60008060008060808587031215615ab957600080fd5b8451935060208501516001600160401b0380821115615ad757600080fd5b615ae388838901615a03565b94506040870151915080821115615af957600080fd5b615b0588838901615a03565b93506060870151915080821115615b1b57600080fd5b50615b2887828801615a5e565b91505092959194509250565b604080825283519082018190526000906020906060840190828701845b82811015615b765781516001600160a01b031684529284019290840190600101615b51565b5050508381038285015284518082528583019183019060005b81811015615bab57835183529284019291840191600101615b8f565b5090979650505050505050565b8082028115828204841417610f1c57610f1c615755565b60008060008060808587031215615be557600080fd5b84516001600160401b0380821115615bfc57600080fd5b615c0888838901615a03565b9550602087015194506040870151915080821115615af957600080fd5b6000600160ff1b8201615c3a57615c3a615755565b5060000390565b60008251615c53818460208701615314565b9190910192915050565b606081526000615c7060608301866152d9565b60208301949094525060400152919050565b6020815260006113ff60208301846152d9565b600082615cb257634e487b7160e01b600052601260045260246000fd5b500490565b8082018281126000831280158216821582161715615cd757615cd7615755565b505092915050565b60ff8181168382160190811115610f1c57610f1c615755565b600181815b8085111561100a578160001904821115615d1957615d19615755565b80851615615d2657918102915b93841c9390800290615cfd565b600082615d4257506001610f1c565b81615d4f57506000610f1c565b8160018114615d655760028114615d6f57615d8b565b6001915050610f1c565b60ff841115615d8057615d80615755565b50506001821b610f1c565b5060208310610133831016604e8410600b8410161715615dae575081810a610f1c565b615db88383615cf8565b8060001904821115615dcc57615dcc615755565b029392505050565b60006113ff8383615d33565b634e487b7160e01b600052605160045260246000fdfea26469706673582212202c20667b62b714d44e621fcbeee22d74803b630821b1545704473e0db56e13b364736f6c63430008150033",
  deployedBytecode:
    "0x6080604052600436106100d65760003560e01c8063aaabadc51161007f578063c9c1661b11610059578063c9c1661b146102a9578063d2c725e0146102de578063ed2438cd14610303578063fc5e93fe14610323576100f4565b8063aaabadc514610224578063ae63932914610256578063b9a8effa14610276576100f4565b80636a256b29116100b05780636a256b29146101bf57806381548319146101ed5780638b19548d1461020d576100f4565b8063214578971461011d5780632bfb780c146101555780634af29ec414610190576100f4565b366100f457604051637911c44b60e11b815260040160405180910390fd5b341561011357604051637911c44b60e11b815260040160405180910390fd5b61011b61033b565b005b34801561012957600080fd5b5061013d61013836600461520c565b610366565b60405161014c93929190615364565b60405180910390f35b34801561016157600080fd5b5061017561017036600461539e565b6105a1565b6040805193845260208401929092529082015260600161014c565b34801561019c57600080fd5b506101b06101ab366004615471565b610b06565b60405161014c9392919061550c565b3480156101cb57600080fd5b506101df6101da366004615537565b610d35565b60405190815260200161014c565b6102006101fb366004615554565b610e04565b60405161014c91906155c5565b34801561021957600080fd5b506101df6276a70081565b34801561023057600080fd5b50600b546001600160a01b03165b6040516001600160a01b03909116815260200161014c565b34801561026257600080fd5b5061011b6102713660046155d8565b610f22565b34801561028257600080fd5b507f000000000000000000000000000000000000000000000000000000000000000061023e565b3480156102b557600080fd5b506102c96102c4366004615619565b610f93565b6040805192835260208301919091520161014c565b3480156102ea57600080fd5b506102f3611012565b604051901515815260200161014c565b34801561030f57600080fd5b5061011b61031e3660046155d8565b611020565b34801561032f57600080fd5b506101df630755580081565b6103647f000000000000000000000000000000000000000000000000000000000000000061107e565b565b60006060806103736110a2565b835161037e81611138565b8451610388611169565b6103918161118f565b60006103a2876000015160016111c1565b90506103b88160200151518860600151516112e3565b60a0810151608082015160608901516000926103d392611307565b8251610100015160c00151909150156104c45787600001516001600160a01b0316631abe476289602001518a608001518b604001518587606001518e60a001516040518763ffffffff1660e01b815260040161043496959493929190615668565b6020604051808303816000875af1158015610453573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061047791906156d9565b151560000361049957604051631557c43360e11b815260040160405180910390fd5b87516104a790836001611406565b60a0820151608083015160608a01516104c1929091611307565b90505b60606104d1838a8461148d565b8651610100015160e00151939b5091995090975091501561059557885160208a0151606085015160a08c0151604051633c7faa1360e21b81526001600160a01b039094169363f1fea84c936105309390928e92889291906004016156fb565b6020604051808303816000875af115801561054f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061057391906156d9565b1515600003610595576040516303a6723b60e31b815260040160405180910390fd5b50505050509193909250565b60008060006105ae6110a2565b83602001516105bc81611138565b84602001516105c9611169565b6105d28161118f565b85608001516000036105f7576040516357a456b760e01b815260040160405180910390fd5b85606001516001600160a01b031686604001516001600160a01b0316036106315760405163a54b181d60e01b815260040160405180910390fd5b6000610642876020015160016111c1565b6020888101516001600160a01b03908116600090815260028084526040808320815160e081018352848152808701859052808301859052606081018590526080810185905260a0810185905260c08101859052828f01519095168452918201909452929020549293509091815260608901516001600160a01b031660009081526002830160205260409020546020820152805115806106e357506020810151155b156107015760405163259ba1ad60e01b815260040160405180910390fd5b805160001990810182526020820180519091019052610721818a85611c2b565b825161072c90611d0d565b60a0820181905215801590610753575060018951600181111561075157610751615652565b145b156107a257604081015160a082015161077c908290670de0b6b3a7640000818103911002611d32565b610786919061576b565b6080820181905260408201805161079e90839061577e565b9052505b82516101000151604001511561086c5788602001516001600160a01b031663b116ea9a6107d08b8487611d81565b6040518263ffffffff1660e01b81526004016107ec91906157a5565b6020604051808303816000875af115801561080b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061082f91906156d9565b15156000036108515760405163e91e17e760e01b815260040160405180910390fd5b6108618960200151846001611406565b61086c818a85611c2b565b610877898285611e39565b8551610100015160600151929a50909850965015610a2457600080808b5160018111156108a6576108a6615652565b146108ba57826060015183604001516108c5565b826040015183606001515b915091508a602001516001600160a01b0316633ac204876040518061012001604052808e6000015160018111156108fe576108fe615652565b81526020018e604001516001600160a01b031681526020018e606001516001600160a01b03168152602001858152602001848152602001886060015187600001518151811061094f5761094f615861565b60200260200101518152602001886060015187602001518151811061097657610976615861565b60200260200101518152602001336001600160a01b031681526020018e60c0015181525085606001516040518363ffffffff1660e01b81526004016109bc929190615877565b6020604051808303816000875af11580156109db573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906109ff91906156d9565b1515600003610a2157604051630568a77b60e21b815260040160405180910390fd5b50505b6000610a818460a00151836020015181518110610a4357610a43615861565b60200260200101518560800151846020015181518110610a6557610a65615861565b602002602001015184608001516121529092919063ffffffff16565b905089606001516001600160a01b03168a604001516001600160a01b03168b602001516001600160a01b03167fd6d34547c69c5ee3d2667625c188acf1006abb93e0ee7cf03925c67cf77604138b8b86604051610af1939291909283526020830191909152604082015260600190565b60405180910390a45050505050509193909250565b606060006060610b146110a2565b8351610b1f81611138565b8451610b29611169565b610b328161118f565b6000610b43876000015160006111c1565b9050610b598160200151518860400151516112e3565b60a081015160808201516040890151600092610b749261216f565b825161010001516080015190915015610c655787600001516001600160a01b03166328a6c4ab89602001518a60800151848c6060015187606001518e60a001516040518763ffffffff1660e01b8152600401610bd596959493929190615931565b6020604051808303816000875af1158015610bf4573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c1891906156d9565b1515600003610c3a576040516305975b2960e11b815260040160405180910390fd5b8751610c4890836000611406565b60a0820151608083015160408a0151610c6292909161216f565b90505b6060610c72838a84612262565b8651610100015160a00151939b50909950975091501561059557885160208a0151606085015160a08c015160405163428e650760e11b81526001600160a01b039094169363851cca0e93610cd093909287928e929190600401615981565b6020604051808303816000875af1158015610cef573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610d1391906156d9565b15156000036105955760405163e124916560e01b815260040160405180910390fd5b6000610d3f612830565b610d476110a2565b6001600160a01b038216600081815260076020526040908190205490516370a0823160e01b81523060048201529091906370a0823190602401602060405180830381865afa158015610d9d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610dc191906159bb565b6001600160a01b0384166000908152600760205260409020819055610de790829061576b565b9150610df483833361285a565b50610dff6001600c55565b919050565b600480546001810182556000919091527f8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b01805473ffffffffffffffffffffffffffffffffffffffff191633179055604080516020601f8401819004810282018101909252828152606091610e98919085908590819084018382808284376000920191909152503393925034915050612876565b9050600454600103610edb5760055415610ec5576040516320f1d86d60e01b815260040160405180910390fd5b610ed160046000614f39565b6000600555610f1c565b6004805480610eec57610eec6159d4565b6000828152602090208101600019908101805473ffffffffffffffffffffffffffffffffffffffff191690550190555b92915050565b610f2a612830565b610f326110a2565b610f3d838233612913565b6001600160a01b03831660009081526007602052604081208054839290610f6590849061576b565b90915550610f7f90506001600160a01b0384168383612920565b610f896001600c55565b505050565b905090565b60008083610fa081612994565b6001600160a01b038516600090815260026020526040812090610fc1825490565b6001600160a01b0387166000908152600284016020526040812054919250819003610fff5760405163259ba1ad60e01b815260040160405180910390fd5b909450600019019250505b509250929050565b6000610f8e600c5460021490565b611028612830565b6110306110a2565b61103b83823361285a565b6001600160a01b0383166000908152600760205260408120805483929061106390849061577e565b90915550610f7f90506001600160a01b0384168330846129c5565b3660008037600080366000845af43d6000803e80801561109d573d6000f35b3d6000fd5b6004546000036110c457604051625185ab60e41b815260040160405180910390fd5b60048054600091906110d89060019061576b565b815481106110e8576110e8615861565b6000918252602090912001546001600160a01b03169050338114611135576040516327c2144960e21b81523360048201526001600160a01b03821660248201526044015b60405180910390fd5b50565b61114181612a04565b61113557604051634bdace1360e01b81526001600160a01b038216600482015260240161112c565b611171612a26565b15610364576040516336a7e2cd60e21b815260040160405180910390fd5b61119881612a64565b156111355760405163d971f59760e01b81526001600160a01b038216600482015260240161112c565b6111c9614f57565b6111d1612830565b60606111dd8484612a78565b8051919350915060005b818110156112cc5760008460200151828151811061120757611207615861565b6020026020010151600001519050600084838151811061122957611229615861565b6020026020010151905060008111156112b9576001600160a01b0382166000908152600a60205260408120805483929061126490849061577e565b92505081905550816001600160a01b0316886001600160a01b03167f0954687c12bae94d7ea785882bbed7766e38d72b5bc620f7c34167edd4f2db75836040516112b091815260200190565b60405180910390a35b5050806112c5906159ea565b90506111e7565b506112d78584612cd3565b5050610f1c6001600c55565b8082146113035760405163aaad13f760e01b815260040160405180910390fd5b5050565b606060008451905061131c8185518551612d8d565b6000816001600160401b0381111561133657611336615047565b60405190808252806020026020018201604052801561135f578160200160208202803683370190505b50905060005b828110156113fa576113cd86828151811061138257611382615861565b602002602001015186838151811061139c5761139c615861565b60200260200101518984815181106113b6576113b6615861565b6020026020010151612dba9092919063ffffffff16565b8282815181106113df576113df615861565b60209081029190910101526113f3816159ea565b9050611365565b509150505b9392505050565b61140f82612dd0565b600061141a84613011565b505091505060005b8360200151518110156114865781818151811061144157611441615861565b60200260200101518460400151828151811061145f5761145f615861565b60200260200101818152505061147684848361325d565b61147f816159ea565b9050611422565b5050505050565b6000606080606061149c612830565b6000606081886080015160038111156114b7576114b7615652565b0361153d57876040015195508860600151516001600160401b038111156114e0576114e0615047565b604051908082528060200260200182016040528015611509578160200160208202803683370190505b5060608a015189516001600160a01b03166000908152600f60205260409020549192506115369188613315565b935061177e565b60018860800151600381111561155557611555615652565b036115e7578760400151955086935061157188606001516133da565b91506115c0896060015183886115a08c600001516001600160a01b03166000908152600f602052604090205490565b8d516115ab90611d0d565b8d516001600160a01b03166316a0b3e0613464565b8584815181106115d2576115d2615861565b6020026020010181935082815250505061177e565b6002886080015160038111156115ff576115ff615652565b036116865786935061161488606001516133da565b915061167c89606001518386858151811061163157611631615861565b602002602001015161165c8c600001516001600160a01b03166000908152600f602052604090205490565b8d5161166790611d0d565b8d516001600160a01b03166380de451d6135e6565b909650905061177e565b60038860800151600381111561169e5761169e615652565b036117655787516001600160a01b03166000908152602081905260409020546116c69061392a565b87600001516001600160a01b031663ab68e28c89602001518a604001518a8d606001518d60a001516040518663ffffffff1660e01b815260040161170e9594939291906156fb565b6000604051808303816000875af115801561172d573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526117559190810190615aa3565b929850909550909350905061177e565b60405163137a9a3960e01b815260040160405180910390fd5b87604001518611156117b4578588604001516040516331d38e0b60e01b815260040161112c929190918252602082015260400190565b6020890151516000816001600160401b038111156117d4576117d4615047565b6040519080825280602002602001820160405280156117fd578160200160208202803683370190505b509050816001600160401b0381111561181857611818615047565b604051908082528060200260200182016040528015611841578160200160208202803683370190505b50965060005b82811015611b6d5760008c60200151828151811061186757611867615861565b602002602001015160000151905060006118a18e87858151811061188d5761188d615861565b60200260200101518f600001518587613955565b9050808e6040015184815181106118ba576118ba615861565b602002602001018181516118ce919061576b565b915081815250506119036008548785815181106118ed576118ed615861565b6020026020010151613a6290919063ffffffff16565b89848151811061191557611915615861565b6020026020010151611927919061577e565b8e60600151848151811061193d5761193d615861565b60200260200101818151611951919061576b565b9052508351829085908590811061196a5761196a615861565b60200260200101906001600160a01b031690816001600160a01b0316815250506119f28e60a0015184815181106119a3576119a3615861565b60200260200101518f6080015185815181106119c1576119c1615861565b60200260200101518b86815181106119db576119db615861565b60200260200101516121529092919063ffffffff16565b8a8481518110611a0457611a04615861565b6020026020010181815250508c606001518381518110611a2657611a26615861565b60200260200101518a8481518110611a4057611a40615861565b60200260200101511015611ad557838381518110611a6057611a60615861565b60200260200101518a8481518110611a7a57611a7a615861565b60200260200101518e606001518581518110611a9857611a98615861565b60209081029190910101516040516317bc2f2360e11b81526001600160a01b0390931660048401526024830191909152604482015260640161112c565b611b12848481518110611aea57611aea615861565b60200260200101518b8581518110611b0457611b04615861565b60200260200101513361285a565b898381518110611b2457611b24615861565b60200260200101518e604001518481518110611b4257611b42615861565b60200260200101818151611b56919061576b565b905250611b6691508290506159ea565b9050611847565b508951611b7a908c612cd3565b600b54600160a01b900460ff16158015611b92575032155b15611baa57611baa8a600001518b602001518a613a8f565b611bbd8a600001518b602001518a613aef565b60208a01518a516001600160a01b0391821691167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c83611bfe8b6000613c93565b604051611c0c929190615b34565b60405180910390a350505050611c226001600c55565b93509350935093565b600082516001811115611c4057611c40615652565b14611ca557611ca08160a00151846020015181518110611c6257611c62615861565b60200260200101518260800151856020015181518110611c8457611c84615861565b60200260200101518460800151612dba9092919063ffffffff16565b611d00565b611d008160a00151846000015181518110611cc257611cc2615861565b60200260200101518260800151856000015181518110611ce457611ce4615861565b60200260200101518460800151613d649092919063ffffffff16565b6040909301929092525050565b6000816080015115611d2157506000919050565b5060a001516001600160401b031690565b600081600003611d5557604051630a0c22c760e01b815260040160405180910390fd5b6000611d69670de0b6b3a764000085615bb8565b90506001836001830304018115150291505092915050565b611dcb6040805160e0810190915280600081526020016000815260200160608152602001600081526020016000815260200160006001600160a01b03168152602001606081525090565b6040518060e0016040528085600001516001811115611dec57611dec615652565b815260200184604001518152602001836060015181526020018460000151815260200184602001518152602001336001600160a01b031681526020018560c0015181525090509392505050565b6000806000611e46612830565b85602001516001600160a01b03166372c98186611e64888888611d81565b6040518263ffffffff1660e01b8152600401611e8091906157a5565b6020604051808303816000875af1158015611e9f573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611ec391906159bb565b6060860152600086516001811115611edd57611edd615652565b03611fbd5760a085015115611f1b5760a08501516060860151611eff91613a62565b60808601819052606086018051611f1790839061576b565b9052505b611f768460a00151866020015181518110611f3857611f38615861565b60200260200101518560800151876020015181518110611f5a57611f5a615861565b602002602001015187606001516121529092919063ffffffff16565b608087015160a08801519194509250839150811015611fb85760a086015160405163e2ea151b60e01b815261112c918391600401918252602082015260400190565b61205a565b6120188460a00151866000015181518110611fda57611fda615861565b60200260200101518560800151876000015181518110611ffc57611ffc615861565b60200260200101518760600151613d7a9092919063ffffffff16565b608087015160a0880151919450849350915082111561205a5760a086015160405163e2ea151b60e01b815261112c918491600401918252602082015260400190565b612077848660800151886020015189606001518960200151613955565b60c086015260408401518551815184929190811061209757612097615861565b602002602001018181516120ab919061577e565b90525060c08501516040850151602087015181518492919081106120d1576120d1615861565b60200260200101516120e3919061576b565b6120ed919061576b565b846040015186602001518151811061210757612107615861565b602002602001018181525050612121866020015185612cd3565b61213086604001518333612913565b61213f8660600151823361285a565b6121496001600c55565b93509350939050565b6000612167846121628585613a62565b613d8f565b949350505050565b60606000845190506121848185518551612d8d565b6000816001600160401b0381111561219e5761219e615047565b6040519080825280602002602001820160405280156121c7578160200160208202803683370190505b50905060005b828110156113fa576122358682815181106121ea576121ea615861565b602002602001015186838151811061220457612204615861565b602002602001015189848151811061221e5761221e615861565b6020026020010151613d649092919063ffffffff16565b82828151811061224757612247615861565b602090810291909101015261225b816159ea565b90506121cd565b60608060006060612271612830565b602087015151606060008860800151600281111561229157612291615652565b036122ef578694506122e58960600151886122c58b600001516001600160a01b03166000908152600f602052604090205490565b8c516122d090611d0d565b8c516001600160a01b03166380de451d613db0565b9094509050612490565b60018860800151600281111561230757612307615652565b036123985787606001519350600061231e886133da565b90508795506123708a6060015182876123508d600001516001600160a01b03166000908152600f602052604090205490565b8e5161235b90611d0d565b8e516001600160a01b03166316a0b3e0614165565b87838151811061238257612382615861565b6020026020010181945082815250505050612490565b6002886080015160028111156123b0576123b0615652565b036124775787516001600160a01b03166000908152602081905260409020546123d8906142f5565b87600001516001600160a01b031663e4c436638960200151898b606001518d606001518d60a001516040518663ffffffff1660e01b8152600401612420959493929190615981565b6000604051808303816000875af115801561243f573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526124679190810190615bcf565b9297509095509093509050612490565b604051636c02b39560e01b815260040160405180910390fd5b87606001518410156124c5576060880151604051638d261d5d60e01b815261112c918691600401918252602082015260400190565b816001600160401b038111156124dd576124dd615047565b604051908082528060200260200182016040528015612506578160200160208202803683370190505b5095506000826001600160401b0381111561252357612523615047565b60405190808252806020026020018201604052801561254c578160200160208202803683370190505b50905060005b838110156127ac5760008b60200151828151811061257257612572615861565b60200260200101516000015190508083838151811061259357612593615861565b60200260200101906001600160a01b031690816001600160a01b03168152505060006125df8d8685815181106125cb576125cb615861565b60200260200101518e600001518587613955565b9050600061264b8e60a0015185815181106125fc576125fc615861565b60200260200101518f60800151868151811061261a5761261a615861565b60200260200101518c878151811061263457612634615861565b6020026020010151613d7a9092919063ffffffff16565b90508c60400151848151811061266357612663615861565b60200260200101518111156126c75782818e60400151868151811061268a5761268a615861565b60209081029190910101516040516323b6a17960e21b81526001600160a01b0390931660048401526024830191909152604482015260640161112c565b6126d2838233612913565b6126dc828261576b565b8e6040015185815181106126f2576126f2615861565b60200260200101818151612706919061577e565b915081815250506127256008548786815181106118ed576118ed615861565b8a858151811061273757612737615861565b6020026020010151612749919061576b565b8e60600151858151811061275f5761275f615861565b60200260200101818151612773919061577e565b9052508a5181908c908690811061278c5761278c615861565b602002602001018181525050505050806127a5906159ea565b9050612552565b5088516127b9908b612cd3565b6127cc89600001518a6020015187614320565b602089015189516001600160a01b0391821691167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c8361280d8b6001613c93565b60405161281b929190615b34565b60405180910390a3505050611c226001600c55565b6002600c540361285357604051633ee5aeb560e01b815260040160405180910390fd5b6002600c55565b610f898361286784614470565b61287090615c25565b836144ba565b60608147101561289b5760405163cd78605960e01b815230600482015260240161112c565b600080856001600160a01b031684866040516128b79190615c41565b60006040518083038185875af1925050503d80600081146128f4576040519150601f19603f3d011682016040523d82523d6000602084013e6128f9565b606091505b509150915061290986838361458e565b9695505050505050565b610f898361287084614470565b6040516001600160a01b03838116602483015260448201839052610f8991859182169063a9059cbb906064015b604051602081830303815290604052915060e01b6020820180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff83818316178352505050506145ea565b61299d8161464d565b611135576040516327946f5760e21b81526001600160a01b038216600482015260240161112c565b6040516001600160a01b0384811660248301528381166044830152606482018390526129fe9186918216906323b872dd9060840161294d565b50505050565b6001600160a01b038116600090815260208190526040812054610f1c90614675565b60007f00000000000000000000000000000000000000000000000000000000000000004211158015610f8e575050600b54600160a81b900460ff1690565b600080612a7083614691565b509392505050565b612a80614f57565b6060612a8b84613011565b855260a08501526040808501919091526020808501929092526001600160a01b03861660009081526002909252812090612ac3825490565b9050806001600160401b03811115612add57612add615047565b604051908082528060200260200182016040528015612b06578160200160208202803683370190505b509250806001600160401b03811115612b2157612b21615047565b604051908082528060200260200182016040528015612b4a578160200160208202803683370190505b506060850152600954612b5c85612dd0565b8451602001516000908015612b715750600082115b8015612b805750855160600151155b905060005b83811015612cc757600087602001518281518110612ba557612ba5615861565b6020026020010151602001519050612bbe888a8461325d565b60006002826002811115612bd457612bd4615652565b1480612c1e57506001826002811115612bef57612bef615652565b148015612c1e575088602001518381518110612c0d57612c0d615861565b602090810291909101015160600151155b9050838015612c2a5750805b15612cb45760008381526001888101602052604082200154612c52908b9060801c86896146fd565b90508015612cb25780898581518110612c6d57612c6d615861565b602002602001018181525050808a604001518581518110612c9057612c90615861565b60200260200101818151612ca4919061576b565b905250612cb28a8c8661325d565b505b505080612cc0906159ea565b9050612b85565b50505050509250929050565b6001600160a01b0382166000908152600260205260409081902060a08301516080840151928401519192612d0892919061216f565b606083015260005b8260400151518110156129fe57612d7d81612d6585604001518481518110612d3a57612d3a615861565b602002602001015186606001518581518110612d5857612d58615861565b602002602001015161478e565b60009182526001808601602052604090922090910155565b612d86816159ea565b9050612d10565b8183141580612d9c5750808214155b15610f895760405163aaad13f760e01b815260040160405180910390fd5b600061216782612dca8686613a62565b90613a62565b602081015151806001600160401b03811115612dee57612dee615047565b604051908082528060200260200182016040528015612e17578160200160208202803683370190505b50608083015260005b81811015610f8957600083602001518281518110612e4057612e40615861565b602002602001015160200151905060006002811115612e6157612e61615652565b816002811115612e7357612e73615652565b03612ea857670de0b6b3a764000084608001518381518110612e9757612e97615861565b602002602001018181525050613000565b6001816002811115612ebc57612ebc615652565b03612f5a5783602001518281518110612ed757612ed7615861565b6020026020010151604001516001600160a01b031663679aefce6040518163ffffffff1660e01b8152600401602060405180830381865afa158015612f20573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612f4491906159bb565b84608001518381518110612e9757612e97615861565b6002816002811115612f6e57612f6e615652565b03612fe75783602001518281518110612f8957612f89615861565b6020026020010151600001516001600160a01b03166307a2d13a670de0b6b3a76400006040518263ffffffff1660e01b8152600401612fca91815260200190565b602060405180830381865afa158015612f20573d6000803e3d6000fd5b604051636fa2831960e11b815260040160405180910390fd5b5061300a816159ea565b9050612e20565b606080606061301e614f93565b6001600160a01b038516600090815260026020908152604080832060039092528220909161304a835490565b6001600160a01b03891660009081526020819052604090205490915061306f906147e5565b9350806001600160401b0381111561308957613089615047565b6040519080825280602002602001820160405280156130db57816020015b6040805160808101825260008082526020808301829052928201819052606082015282526000199092019101816130a75790505b509650806001600160401b038111156130f6576130f6615047565b60405190808252806020026020018201604052801561311f578160200160208202803683370190505b50955061312c848261494c565b945060008060005b838110156132505760008181526001808801602052604090912080549101546001600160a01b0390911690935091506fffffffffffffffffffffffffffffffff831689828151811061318857613188615861565b6020908102919091018101919091526001600160a01b038381166000908152878352604090819020815160808101909252805492831682529092909190830190600160a01b900460ff1660028111156131e3576131e3615652565b60028111156131f4576131f4615652565b8152600191909101546001600160a01b0381166020830152600160a01b900460ff1615156040909101528a518b908390811061323257613232615861565b60200260200101819052508080613248906159ea565b915050613134565b5050505050509193509193565b61502a600083600181111561327457613274615652565b1461328157613d64613285565b612dba5b90506132ed846040015183815181106132a0576132a0615861565b60200260200101518560a0015184815181106132be576132be615861565b6020026020010151866080015185815181106132dc576132dc615861565b60200260200101518463ffffffff16565b8460600151838151811061330357613303615861565b60200260200101818152505050505050565b606060006133238385613d8f565b905084516001600160401b0381111561333e5761333e615047565b604051908082528060200260200182016040528015613367578160200160208202803683370190505b50915060005b85518110156133d1576133a28287838151811061338c5761338c615861565b6020026020010151614a1c90919063ffffffff16565b8382815181106133b4576133b4615861565b6020908102919091010152806133c9816159ea565b91505061336d565b50509392505050565b80518060005b8181101561343d578381815181106133fa576133fa615861565b602002602001015160001461342d5781831461342957604051636b8c3be560e01b815260040160405180910390fd5b8092505b613436816159ea565b90506133e0565b5080821061345e57604051631f91af7760e21b815260040160405180910390fd5b50919050565b6000606081613473888861576b565b9050600085858c8c613485868d611d32565b6040518463ffffffff1660e01b81526004016134a393929190615c5d565b602060405180830381865afa1580156134c0573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906134e491906159bb565b90506000818c8c815181106134fb576134fb615861565b602002602001015161350d919061576b565b905060006135478a6135418f8f8151811061352a5761352a615861565b602002602001015187613a6290919063ffffffff16565b90613d8f565b90506000613555848361576b565b90506000613563828c613a62565b90508e516001600160401b0381111561357e5761357e615047565b6040519080825280602002602001820160405280156135a7578160200160208202803683370190505b50965080878f815181106135bd576135bd615861565b60209081029190910101526135d2818561576b565b975050505050505097509795505050505050565b865160009060609082816001600160401b0381111561360757613607615047565b604051908082528060200260200182016040528015613630578160200160208202803683370190505b50905060005b8b51811015613688578b818151811061365157613651615861565b602002602001015182828151811061366b5761366b615861565b602090810291909101015280613680816159ea565b915050613636565b5088818b8151811061369c5761369c615861565b60200260200101516136ae919061576b565b818b815181106136c0576136c0615861565b602002602001018181525050600086868d6040518263ffffffff1660e01b81526004016136ed9190615c82565b602060405180830381865afa15801561370a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061372e91906159bb565b90506000828c8151811061374457613744615861565b60200260200101516137d38e8e8151811061376157613761615861565b6020026020010151612dca858c8c896040518263ffffffff1660e01b815260040161378c9190615c82565b602060405180830381865afa1580156137a9573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906137cd91906159bb565b90611d32565b6137dd919061576b565b90506000816137fd670de0b6b3a76400008c8103908d10025b8490611d32565b613807919061576b565b905080848e8151811061381c5761381c615861565b602002602001015161382e919061576b565b848e8151811061384057613840615861565b60200260200101818152505060008989866040518263ffffffff1660e01b815260040161386d9190615c82565b602060405180830381865afa15801561388a573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906138ae91906159bb565b9050856001600160401b038111156138c8576138c8615047565b6040519080825280602002602001820160405280156138f1578160200160208202803683370190505b50965081878f8151811061390757613907615861565b60209081029190910101526135d284613541613923848361576b565b8f90613a62565b61393381614a3d565b15156000036111355760405163033c2a5760e61b815260040160405180910390fd5b6000808511801561396857506000600854115b80156139775750855160600151155b15613a59576139d78660a00151838151811061399557613995615861565b6020026020010151876080015184815181106139b3576139b3615861565b60200260200101516139d060085489613a6290919063ffffffff16565b9190612152565b6001600160a01b0384166000908152600a6020526040812080549293508392909190613a0490849061577e565b92505081905550826001600160a01b0316846001600160a01b03167f7ed2189f578f040de476a40b0677b8f117d19e127bcd551586055aca4823661483604051613a5091815260200190565b60405180910390a35b95945050505050565b600080613a6f8385615bb8565b90506001670de0b6b3a76400006001830304018115150291505092915050565b3215613aae576040516333fc255960e11b815260040160405180910390fd5b6001600160a01b038084166000908152600d6020908152604080832093861683529290529081208054839290613ae590849061577e565b9091555050505050565b6001600160a01b038216613b2157604051634b637e8f60e11b81526001600160a01b038316600482015260240161112c565b6001600160a01b038084166000908152600d602090815260408083209386168352929052205480821115613b815760405163391434e360e21b81526001600160a01b0384166004820152602481018290526044810183905260640161112c565b6001600160a01b038085166000818152600d6020908152604080832094881683529381528382208686039055918152600f90915290812054613bc490849061576b565b9050613bcf81614adc565b6001600160a01b038581166000818152600f60209081526040808320869055518781529193881692917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b03858116600483015260006024830152604482018590528616906323de665190606401600060405180830381600087803b158015613c7457600080fd5b505af1158015613c88573d6000803e3d6000fd5b505050505050505050565b606082516001600160401b03811115613cae57613cae615047565b604051908082528060200260200182016040528015613cd7578160200160208202803683370190505b50905060005b8351811015613d5d5782613d1357838181518110613cfd57613cfd615861565b6020026020010151613d0e90615c25565b613d2e565b838181518110613d2557613d25615861565b60200260200101515b828281518110613d4057613d40615861565b602090810291909101015280613d55816159ea565b915050613cdd565b5092915050565b600061216782613d748686614a1c565b90614a1c565b600061216784613d8a8585614a1c565b611d32565b600080613da4670de0b6b3a764000085615bb8565b90506121678382615c95565b855160009060609082816001600160401b03811115613dd157613dd1615047565b604051908082528060200260200182016040528015613dfa578160200160208202803683370190505b509050816001600160401b03811115613e1557613e15615047565b604051908082528060200260200182016040528015613e3e578160200160208202803683370190505b50925060005b8a51811015613eba57898181518110613e5f57613e5f615861565b60200260200101518b8281518110613e7957613e79615861565b6020026020010151613e8b919061577e565b828281518110613e9d57613e9d615861565b602090810291909101015280613eb2816159ea565b915050613e44565b50600086868c6040518263ffffffff1660e01b8152600401613edc9190615c82565b602060405180830381865afa158015613ef9573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613f1d91906159bb565b905060008787846040518263ffffffff1660e01b8152600401613f409190615c82565b602060405180830381865afa158015613f5d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190613f8191906159bb565b90506000613f8f8284613d8f565b905060005b8d518110156140d557613fc98e8281518110613fb257613fb2615861565b602002602001015183613a6290919063ffffffff16565b858281518110613fdb57613fdb615861565b602002602001015111156140c35760006140178f838151811061400057614000615861565b602002602001015184613a6290919063ffffffff16565b86838151811061402957614029615861565b602002602001015161403b919061576b565b9050614047818d613a62565b88838151811061405957614059615861565b60200260200101818152505087828151811061407757614077615861565b602002602001015186838151811061409157614091615861565b60200260200101516140a3919061576b565b8683815181106140b5576140b5615861565b602002602001018181525050505b806140cd816159ea565b915050613f94565b5060008989866040518263ffffffff1660e01b81526004016140f79190615c82565b602060405180830381865afa158015614114573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061413891906159bb565b905061415261414b85613541818561576b565b8d90614a1c565b9750505050505050965096945050505050565b6000606081614174878961577e565b9050600085858c8c614186868d611d32565b6040518463ffffffff1660e01b81526004016141a493929190615c5d565b602060405180830381865afa1580156141c1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906141e591906159bb565b905060008b8b815181106141fb576141fb615861565b60200260200101518261420e919061576b565b9050600061422b8a6135418f8f8151811061352a5761352a615861565b90506000818e8e8151811061424257614242615861565b602002602001015184614255919061577e565b61425f919061576b565b905060008161427c670de0b6b3a76400008d8103908e10026137f6565b614286919061576b565b90508e516001600160401b038111156142a1576142a1615047565b6040519080825280602002602001820160405280156142ca578160200160208202803683370190505b50965080878f815181106142e0576142e0615861565b60209081029190910101526135d2818561577e565b6142fe81614b0c565b15156000036111355760405163121db02f60e21b815260040160405180910390fd5b6001600160a01b0382166143525760405163ec442f0560e01b81526001600160a01b038316600482015260240161112c565b6001600160a01b0383166000908152600f602052604081205461437690839061577e565b6001600160a01b038086166000908152600d6020908152604080832093881683529290522080548401905590506143ac81614adc565b6001600160a01b038481166000818152600f6020908152604080832086905551868152938716939192917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b8152600060048201526001600160a01b038481166024830152604482018490528516906323de665190606401600060405180830381600087803b15801561445257600080fd5b505af1158015614466573d6000803e3d6000fd5b5050505050505050565b60007f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8211156144b65760405163123baf0360e11b81526004810183905260240161112c565b5090565b816000036144c757505050565b6001600160a01b0381163314614501576040516327c2144960e21b81526001600160a01b038216600482015233602482015260440161112c565b6001600160a01b038082166000908152600660209081526040808320938716835292905290812054906145348483615cb7565b90508060000361454d576005805460001901905561455f565b8160000361455f576005805460010190555b6001600160a01b0392831660009081526006602090815260408083209790951682529590955291909320555050565b6060826145a35761459e82614b1c565b6113ff565b81511580156145ba57506001600160a01b0384163b155b156145e357604051639996b31560e01b81526001600160a01b038516600482015260240161112c565b50806113ff565b60006145ff6001600160a01b03841683614b45565b9050805160001415801561462457508080602001905181019061462291906156d9565b155b15610f8957604051635274afe760e01b81526001600160a01b038416600482015260240161112c565b6001600160a01b038116600090815260208190526040812054610f1c90600060018216610f1c565b6000610f1c614685826001615cdf565b839060ff161c60011690565b6001600160a01b0381166000908152602081905260408120548190819081906146b990614b53565b915091508180156146f357506146ef7f00000000000000000000000000000000000000000000000000000000000000008261577e565b4211155b9590945092505050565b6000808560600151848151811061471657614716615861565b602002602001015190508481111561478557600085820390506147818760a00151868151811061474857614748615861565b60200260200101518860800151878151811061476657614766615861565b60200260200101516139d08785614a1c90919063ffffffff16565b9250505b50949350505050565b60006fffffffffffffffffffffffffffffffff8311806147bd57506fffffffffffffffffffffffffffffffff82115b156147db576040516389560ca160e01b815260040160405180910390fd5b6113ff8383614b79565b6147ed614f93565b60405180610140016040528061480884600060018216610f1c565b1515815260200161481884614675565b1515815260200161482884614b89565b1515815260200161483884614b99565b1515815260200161484884614ba9565b1515815260200161485884614bb9565b6001600160401b0316815260200161486f84614c7d565b62ffffff16815260200161488284614d49565b63ffffffff1681526020016040518061010001604052806148a286614e22565b151581526020016148b286614e32565b151581526020016148c286614e42565b151581526020016148d286614e52565b151581526020016148e286614e62565b151581526020016148f286614e72565b1515815260200161490286614e82565b1515815260200161491286614e92565b15158152508152602001604051806040016040528061493086614b0c565b1515815260200161494086614a3d565b15159052905292915050565b60606000826001600160401b0381111561496857614968615047565b604051908082528060200260200182016040528015614991578160200160208202803683370190505b5060c085015190915062ffffff1660005b84811015614a125760006149c36149ba600584615bb8565b84901c601f1690565b90506149d081600a615dd4565b6149e290670de0b6b3a7640000615bb8565b8483815181106149f4576149f4615861565b60209081029190910101525080614a0a816159ea565b9150506149a2565b5090949350505050565b600080614a298385615bb8565b9050612167670de0b6b3a764000082615c95565b6000610f1c614a4d826001615cdf565b614a58906001615cdf565b614a63906001615cdf565b614a6e906001615cdf565b614a79906001615cdf565b614a84906001615cdf565b614a8f906001615cdf565b614a9a906001615cdf565b614aa5906001615cdf565b614ab0906001615cdf565b614abb906001615cdf565b614ac6906001615cdf565b614ad1906001615cdf565b614685906001615cdf565b620f424081101561113557604051634ddaf4a960e01b815260048101829052620f4240602482015260440161112c565b6000610f1c614a58826001615cdf565b805115614b2c5780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b60606113ff83836000612876565b600080614b5f83614b89565b614b6884614d49565b909463ffffffff9091169350915050565b60006113ff83608084901b61577e565b6000610f1c614ad1826001615cdf565b6000610f1c614a63826001615cdf565b6000610f1c614ac6826001615cdf565b6000610f1c614c78614bcc836001615cdf565b614bd7906001615cdf565b614be2906001615cdf565b614bed906001615cdf565b614bf8906001615cdf565b614c03906001615cdf565b614c0e906001615cdf565b614c19906001615cdf565b614c24906001615cdf565b614c2f906001615cdf565b614c3a906001615cdf565b614c45906001615cdf565b614c50906001615cdf565b614c5b906001615cdf565b614c66906001615cdf565b60ff1684901c6001600160401b031690565b614ea2565b6000610f1c614d446040614c92846001615cdf565b614c9d906001615cdf565b614ca8906001615cdf565b614cb3906001615cdf565b614cbe906001615cdf565b614cc9906001615cdf565b614cd4906001615cdf565b614cdf906001615cdf565b614cea906001615cdf565b614cf5906001615cdf565b614d00906001615cdf565b614d0b906001615cdf565b614d16906001615cdf565b614d21906001615cdf565b614d2c906001615cdf565b614d369190615cdf565b60ff1684901c62ffffff1690565b614ed8565b6000610f1c614e1d60186040614d60856001615cdf565b614d6b906001615cdf565b614d76906001615cdf565b614d81906001615cdf565b614d8c906001615cdf565b614d97906001615cdf565b614da2906001615cdf565b614dad906001615cdf565b614db8906001615cdf565b614dc3906001615cdf565b614dce906001615cdf565b614dd9906001615cdf565b614de4906001615cdf565b614def906001615cdf565b614dfa906001615cdf565b614e049190615cdf565b614e0e9190615cdf565b60ff1684901c63ffffffff1690565b614f08565b6000610f1c614a79826001615cdf565b6000610f1c614a6e826001615cdf565b6000610f1c614abb826001615cdf565b6000610f1c614ab0826001615cdf565b6000610f1c614aa5826001615cdf565b6000610f1c614a9a826001615cdf565b6000610f1c614a8f826001615cdf565b6000610f1c614a84826001615cdf565b60006001600160401b038211156144b657604080516306dfcc6560e41b815260048101919091526024810183905260440161112c565b600062ffffff8211156144b6576040516306dfcc6560e41b8152601860048201526024810183905260440161112c565b600063ffffffff8211156144b6576040516306dfcc6560e41b8152602060048201526024810183905260440161112c565b50805460008255906000526020600020908101906111359190615032565b6040518060c00160405280614f6a614f93565b815260200160608152602001606081526020016060815260200160608152602001606081525090565b6040805161014081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e080880187905288516101008082018b52888252818801899052818b01899052958101889052938401879052918301869052820185905281018490529084015283518085019094528184528301529061012082015290565b610364615de0565b5b808211156144b65760008155600101615033565b634e487b7160e01b600052604160045260246000fd5b60405160c081016001600160401b038111828210171561507f5761507f615047565b60405290565b60405160e081016001600160401b038111828210171561507f5761507f615047565b604051601f8201601f191681016001600160401b03811182821017156150cf576150cf615047565b604052919050565b6001600160a01b038116811461113557600080fd5b8035610dff816150d7565b60006001600160401b0382111561511057615110615047565b5060051b60200190565b600082601f83011261512b57600080fd5b8135602061514061513b836150f7565b6150a7565b82815260059290921b8401810191818101908684111561515f57600080fd5b8286015b8481101561517a5780358352918301918301615163565b509695505050505050565b803560048110610dff57600080fd5b60006001600160401b038211156151ad576151ad615047565b50601f01601f191660200190565b600082601f8301126151cc57600080fd5b81356151da61513b82615194565b8181528460208386010111156151ef57600080fd5b816020850160208301376000918101602001919091529392505050565b60006020828403121561521e57600080fd5b81356001600160401b038082111561523557600080fd5b9083019060c0828603121561524957600080fd5b61525161505d565b61525a836150ec565b8152615268602084016150ec565b60208201526040830135604082015260608301358281111561528957600080fd5b6152958782860161511a565b6060830152506152a760808401615185565b608082015260a0830135828111156152be57600080fd5b6152ca878286016151bb565b60a08301525095945050505050565b600081518084526020808501945080840160005b83811015615309578151875295820195908201906001016152ed565b509495945050505050565b60005b8381101561532f578181015183820152602001615317565b50506000910152565b60008151808452615350816020860160208601615314565b601f01601f19169290920160200192915050565b83815260606020820152600061537d60608301856152d9565b82810360408401526129098185615338565b803560028110610dff57600080fd5b6000602082840312156153b057600080fd5b81356001600160401b03808211156153c757600080fd5b9083019060e082860312156153db57600080fd5b6153e3615085565b6153ec8361538f565b81526153fa602084016150ec565b602082015261540b604084016150ec565b604082015261541c606084016150ec565b60608201526080830135608082015260a083013560a082015260c08301358281111561544757600080fd5b615453878286016151bb565b60c08301525095945050505050565b803560038110610dff57600080fd5b60006020828403121561548357600080fd5b81356001600160401b038082111561549a57600080fd5b9083019060c082860312156154ae57600080fd5b6154b661505d565b6154bf836150ec565b81526154cd602084016150ec565b60208201526040830135828111156154e457600080fd5b6154f08782860161511a565b604083015250606083013560608201526152a760808401615462565b60608152600061551f60608301866152d9565b84602084015282810360408401526129098185615338565b60006020828403121561554957600080fd5b81356113ff816150d7565b6000806020838503121561556757600080fd5b82356001600160401b038082111561557e57600080fd5b818501915085601f83011261559257600080fd5b8135818111156155a157600080fd5b8660208285010111156155b357600080fd5b60209290920196919550909350505050565b6020815260006113ff6020830184615338565b6000806000606084860312156155ed57600080fd5b83356155f8816150d7565b92506020840135615608816150d7565b929592945050506040919091013590565b6000806040838503121561562c57600080fd5b8235615637816150d7565b91506020830135615647816150d7565b809150509250929050565b634e487b7160e01b600052602160045260246000fd5b6001600160a01b038716815260006004871061568657615686615652565b86602083015285604083015260c060608301526156a660c08301866152d9565b82810360808401526156b881866152d9565b905082810360a08401526156cc8185615338565b9998505050505050505050565b6000602082840312156156eb57600080fd5b815180151581146113ff57600080fd5b6001600160a01b038616815284602082015260a06040820152600061572360a08301866152d9565b828103606084015261573581866152d9565b905082810360808401526157498185615338565b98975050505050505050565b634e487b7160e01b600052601160045260246000fd5b81810381811115610f1c57610f1c615755565b80820180821115610f1c57610f1c615755565b600281106157a1576157a1615652565b9052565b6000602080835261010083016157be8285018651615791565b8482015160408581019190915285015160e060608601528051918290528201906000906101208601905b8083101561580857835182529284019260019290920191908401906157e8565b5060608701516080870152608087015160a087015260a0870151935061583960c08701856001600160a01b03169052565b60c0870151868203601f190160e088015293506158568185615338565b979650505050505050565b634e487b7160e01b600052603260045260246000fd5b60408152615889604082018451615791565b600060208401516158a560608401826001600160a01b03169052565b5060408401516001600160a01b038116608084015250606084015160a0830152608084015160c083015260a084015160e083015260c0840151610100818185015260e08601519150610120615904818601846001600160a01b03169052565b818701519250806101408601525050615921610160840182615338565b9150508260208301529392505050565b6001600160a01b038716815260006003871061594f5761594f615652565b86602083015260c0604083015261596960c08301876152d9565b85606084015282810360808401526156b881866152d9565b6001600160a01b038616815260a0602082015260006159a360a08301876152d9565b856040840152828103606084015261573581866152d9565b6000602082840312156159cd57600080fd5b5051919050565b634e487b7160e01b600052603160045260246000fd5b6000600182016159fc576159fc615755565b5060010190565b600082601f830112615a1457600080fd5b81516020615a2461513b836150f7565b82815260059290921b84018101918181019086841115615a4357600080fd5b8286015b8481101561517a5780518352918301918301615a47565b600082601f830112615a6f57600080fd5b8151615a7d61513b82615194565b818152846020838601011115615a9257600080fd5b612167826020830160208701615314565b60008060008060808587031215615ab957600080fd5b8451935060208501516001600160401b0380821115615ad757600080fd5b615ae388838901615a03565b94506040870151915080821115615af957600080fd5b615b0588838901615a03565b93506060870151915080821115615b1b57600080fd5b50615b2887828801615a5e565b91505092959194509250565b604080825283519082018190526000906020906060840190828701845b82811015615b765781516001600160a01b031684529284019290840190600101615b51565b5050508381038285015284518082528583019183019060005b81811015615bab57835183529284019291840191600101615b8f565b5090979650505050505050565b8082028115828204841417610f1c57610f1c615755565b60008060008060808587031215615be557600080fd5b84516001600160401b0380821115615bfc57600080fd5b615c0888838901615a03565b9550602087015194506040870151915080821115615af957600080fd5b6000600160ff1b8201615c3a57615c3a615755565b5060000390565b60008251615c53818460208701615314565b9190910192915050565b606081526000615c7060608301866152d9565b60208301949094525060400152919050565b6020815260006113ff60208301846152d9565b600082615cb257634e487b7160e01b600052601260045260246000fd5b500490565b8082018281126000831280158216821582161715615cd757615cd7615755565b505092915050565b60ff8181168382160190811115610f1c57610f1c615755565b600181815b8085111561100a578160001904821115615d1957615d19615755565b80851615615d2657918102915b93841c9390800290615cfd565b600082615d4257506001610f1c565b81615d4f57506000610f1c565b8160018114615d655760028114615d6f57615d8b565b6001915050610f1c565b60ff841115615d8057615d80615755565b50506001821b610f1c565b5060208310610133831016604e8410600b8410161715615dae575081810a610f1c565b615db88383615cf8565b8060001904821115615dcc57615dcc615755565b029392505050565b60006113ff8383615d33565b634e487b7160e01b600052605160045260246000fdfea26469706673582212202c20667b62b714d44e621fcbeee22d74803b630821b1545704473e0db56e13b364736f6c63430008150033",
  linkReferences: {},
  deployedLinkReferences: {},
};
