export const vaultExtensionInfo = {
  _format: "hh-sol-artifact-1",
  contractName: "VaultExtension",
  sourceName: "contracts/VaultExtension.sol",
  abi: [
    {
      inputs: [
        {
          internalType: "contract IVault",
          name: "mainVault",
          type: "address",
        },
        {
          internalType: "contract IVaultAdmin",
          name: "vaultAdmin",
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
      name: "CodecOverflow",
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
      name: "OutOfBounds",
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
      inputs: [],
      name: "TokensNotSorted",
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
          internalType: "address",
          name: "token",
          type: "address",
        },
        {
          internalType: "address",
          name: "owner",
          type: "address",
        },
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
      ],
      name: "allowance",
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
          internalType: "address",
          name: "owner",
          type: "address",
        },
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256",
        },
      ],
      name: "approve",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "token",
          type: "address",
        },
        {
          internalType: "address",
          name: "account",
          type: "address",
        },
      ],
      name: "balanceOf",
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
          internalType: "uint256",
          name: "index",
          type: "uint256",
        },
      ],
      name: "getLocker",
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
      inputs: [],
      name: "getLockersCount",
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
      name: "getNonzeroDeltaCount",
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "getPoolConfig",
      outputs: [
        {
          components: [
            {
              internalType: "bool",
              name: "isPoolRegistered",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "isPoolInitialized",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "isPoolPaused",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "isPoolInRecoveryMode",
              type: "bool",
            },
            {
              internalType: "bool",
              name: "hasDynamicSwapFee",
              type: "bool",
            },
            {
              internalType: "uint64",
              name: "staticSwapFeePercentage",
              type: "uint64",
            },
            {
              internalType: "uint24",
              name: "tokenDecimalDiffs",
              type: "uint24",
            },
            {
              internalType: "uint32",
              name: "pauseWindowEndTime",
              type: "uint32",
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
              internalType: "struct LiquidityManagement",
              name: "liquidityManagement",
              type: "tuple",
            },
          ],
          internalType: "struct PoolConfig",
          name: "",
          type: "tuple",
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
      ],
      name: "getPoolPausedState",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "getPoolTokenInfo",
      outputs: [
        {
          internalType: "contract IERC20[]",
          name: "tokens",
          type: "address[]",
        },
        {
          internalType: "enum TokenType[]",
          name: "tokenTypes",
          type: "uint8[]",
        },
        {
          internalType: "uint256[]",
          name: "balancesRaw",
          type: "uint256[]",
        },
        {
          internalType: "uint256[]",
          name: "decimalScalingFactors",
          type: "uint256[]",
        },
        {
          internalType: "contract IRateProvider[]",
          name: "rateProviders",
          type: "address[]",
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
      ],
      name: "getPoolTokens",
      outputs: [
        {
          internalType: "contract IERC20[]",
          name: "",
          type: "address[]",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "token",
          type: "address",
        },
      ],
      name: "getProtocolFees",
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
      name: "getProtocolSwapFeePercentage",
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
      name: "getProtocolYieldFeePercentage",
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
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
      ],
      name: "getReservesOf",
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "getStaticSwapFeePercentage",
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
          internalType: "address",
          name: "user",
          type: "address",
        },
        {
          internalType: "contract IERC20",
          name: "token",
          type: "address",
        },
      ],
      name: "getTokenDelta",
      outputs: [
        {
          internalType: "int256",
          name: "",
          type: "int256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "getVaultAdmin",
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
      ],
      name: "isPoolInRecoveryMode",
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "isPoolInitialized",
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "isPoolPaused",
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
          internalType: "address",
          name: "pool",
          type: "address",
        },
      ],
      name: "isPoolRegistered",
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
      inputs: [],
      name: "isQueryDisabled",
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
          internalType: "bytes",
          name: "data",
          type: "bytes",
        },
      ],
      name: "quote",
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
          internalType: "address",
          name: "pool",
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
          internalType: "struct TokenConfig[]",
          name: "tokenConfig",
          type: "tuple[]",
        },
        {
          internalType: "uint256",
          name: "pauseWindowEndTime",
          type: "uint256",
        },
        {
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
          internalType: "struct PoolHooks",
          name: "poolHooks",
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
          internalType: "struct LiquidityManagement",
          name: "liquidityManagement",
          type: "tuple",
        },
      ],
      name: "registerPool",
      outputs: [],
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
          name: "from",
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
          name: "amountsOutRaw",
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
          name: "token",
          type: "address",
        },
      ],
      name: "totalSupply",
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
          internalType: "address",
          name: "owner",
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
      name: "transfer",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "spender",
          type: "address",
        },
        {
          internalType: "address",
          name: "from",
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
      name: "transferFrom",
      outputs: [
        {
          internalType: "bool",
          name: "",
          type: "bool",
        },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [],
      name: "vault",
      outputs: [
        {
          internalType: "contract IVault",
          name: "",
          type: "address",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      stateMutability: "payable",
      type: "receive",
    },
  ],
  bytecode:
    "0x6101406040523480156200001257600080fd5b5060405162005abf38038062005abf833981016040819052620000359162000247565b6001600c81905550816001600160a01b0316816001600160a01b031663fbfa77cf6040518163ffffffff1660e01b8152600401602060405180830381865afa15801562000086573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620000ac919062000286565b6001600160a01b031614620000d457604051634166145b60e11b815260040160405180910390fd5b806001600160a01b0316638a8d123a6040518163ffffffff1660e01b8152600401602060405180830381865afa15801562000113573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001399190620002ad565b60a08181525050806001600160a01b03166320c1fb7a6040518163ffffffff1660e01b8152600401602060405180830381865afa1580156200017f573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001a59190620002ad565b60e08181525050806001600160a01b031663cd51c12f6040518163ffffffff1660e01b8152600401602060405180830381865afa158015620001eb573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620002119190620002ad565b60c0526001600160a01b03918216610100521661012052620002c7565b6001600160a01b03811681146200024457600080fd5b50565b600080604083850312156200025b57600080fd5b825162000268816200022e565b60208401519092506200027b816200022e565b809150509250929050565b6000602082840312156200029957600080fd5b8151620002a6816200022e565b9392505050565b600060208284031215620002c057600080fd5b5051919050565b60805160a05160c05160e0516101005161012051615799620003266000396000818161032301526106cf01526000818161066e01526113c60152600081816107c7015261166d01526000613607015260005050600050506157996000f3fe6080604052600436106101f25760003560e01c8063ba8a2be01161010d578063e1f21c67116100a0578063f29486a11161006f578063f29486a114610612578063f7888aec1461063f578063fbfa77cf1461065f578063fc5e93fe14610692578063fea5ec5d146106aa57610210565b8063e1f21c6714610592578063e4dc2aa4146105b2578063edfa3568146105d2578063f27dd8ab146105f257610210565b8063c673bdaf116100dc578063c673bdaf1461051b578063ca4f28031461053b578063d2c725e014610568578063db8171871461057d57610210565b8063ba8a2be0146104a6578063be7d628a146104c6578063beabacc8146104e6578063c2372f821461050657610210565b80636c9bc73211610185578063ab8f258d11610154578063ab8f258d1461043c578063b099a7991461045c578063b45090f914610471578063b4aef0ab1461049157610210565b80636c9bc732146103c55780638b19548d146103e5578063927da105146103fc578063967870921461041c57610210565b80631ba0ae45116101c15780631ba0ae45146103145780633a2d133b14610347578063532cec7c1461037457806367e0e0761461039457610210565b80630b1bd243146102395780630f950ea61461027657806315dacbea1461029957806315e32046146102c957610210565b3661021057604051637911c44b60e11b815260040160405180910390fd5b341561022f57604051637911c44b60e11b815260040160405180910390fd5b6102376106ca565b005b34801561024557600080fd5b50610259610254366004614912565b6106f5565b6040516001600160a01b0390911681526020015b60405180910390f35b34801561028257600080fd5b5061028b610759565b60405190815260200161026d565b3480156102a557600080fd5b506102b96102b436600461494b565b61076a565b604051901515815260200161026d565b3480156102d557600080fd5b506102e96102e436600461499c565b610797565b6040805194151585526020850193909352918301526001600160a01b0316606082015260800161026d565b34801561032057600080fd5b507f0000000000000000000000000000000000000000000000000000000000000000610259565b34801561035357600080fd5b506103676103623660046149b9565b610820565b60405161026d9190614a35565b34801561038057600080fd5b506102b961038f36600461499c565b610b63565b3480156103a057600080fd5b506103b46103af36600461499c565b610b80565b60405161026d959493929190614ab9565b3480156103d157600080fd5b506102b96103e036600461499c565b610d96565b3480156103f157600080fd5b5061028b6276a70081565b34801561040857600080fd5b5061028b610417366004614b81565b610db3565b34801561042857600080fd5b5061028b61043736600461499c565b610dd0565b34801561044857600080fd5b5061028b610457366004614bcc565b610df6565b34801561046857600080fd5b5061028b610e2e565b34801561047d57600080fd5b5061028b61048c36600461499c565b610e3f565b34801561049d57600080fd5b506102b9610e89565b3480156104b257600080fd5b5061028b6104c1366004614d70565b610ea4565b3480156104d257600080fd5b506102b96104e136600461499c565b6110cd565b3480156104f257600080fd5b506102b96105013660046149b9565b6110ea565b34801561051257600080fd5b5061028b61110a565b34801561052757600080fd5b506102b961053636600461499c565b61111b565b34801561054757600080fd5b5061055b61055636600461499c565b61112e565b60405161026d9190614e85565b34801561057457600080fd5b506102b961114b565b34801561058957600080fd5b5061028b611159565b34801561059e57600080fd5b506102b96105ad3660046149b9565b61116a565b3480156105be57600080fd5b5061028b6105cd36600461499c565b611180565b6105e56105e0366004614e98565b6111a8565b60405161026d9190614f59565b3480156105fe57600080fd5b5061028b61060d36600461499c565b611281565b34801561061e57600080fd5b5061063261062d36600461499c565b6112a7565b60405161026d9190614fdd565b34801561064b57600080fd5b5061028b61065a366004614bcc565b6112e3565b34801561066b57600080fd5b507f0000000000000000000000000000000000000000000000000000000000000000610259565b34801561069e57600080fd5b5061028b630755580081565b3480156106b657600080fd5b506102376106c53660046150fd565b611318565b6106f37f0000000000000000000000000000000000000000000000000000000000000000611398565b565b60006106ff6113c1565b600454821061072957604051631adf3e3360e01b8152600481018390526024015b60405180910390fd5b6004828154811061073c5761073c615242565b6000918252602090912001546001600160a01b031690505b919050565b60006107636113c1565b5060045490565b60006107746113c1565b610780338587856113f3565b61078c3385858561145a565b506001949350505050565b600080600080846107a781611600565b6107af6113c1565b6000806107bb88611634565b909250905081816107ec7f00000000000000000000000000000000000000000000000000000000000000008261526e565b6001600160a01b03808c16600090815260016020526040902054939a5091985096501693505050509193509193565b905090565b606061082a6116a0565b61083261172e565b8361083c81611758565b8461084681611789565b6001600160a01b038616600090815260026020526040812090610867825490565b90506000816001600160401b0381111561088357610883614c05565b6040519080825280602002602001820160405280156108ac578160200160208202803683370190505b5090506000826001600160401b038111156108c9576108c9614c05565b6040519080825280602002602001820160405280156108f2578160200160208202803683370190505b5090506000805b848110156109955760008181526001808801602052604090912080549101546001600160a01b039091169085838151811061093657610936615242565b60200260200101819450826001600160a01b03166001600160a01b03168152505050610968826001600160801b031690565b83828151811061097a5761097a615242565b602090810291909101015261098e81615281565b90506108f9565b506109bf826109b98d6001600160a01b03166000908152600f602052604090205490565b8b6117ba565b975060005b84811015610a5c57610a098482815181106109e1576109e1615242565b60200260200101518a83815181106109fb576109fb615242565b60200260200101513361187f565b888181518110610a1b57610a1b615242565b6020026020010151838281518110610a3557610a35615242565b60200260200101818151610a49919061529a565b905250610a5581615281565b90506109c4565b506001600160a01b038b166000908152600260205260408120905b85811015610aed5760008181526001808401602052604090912001549250610add81610ac5868481518110610aae57610aae615242565b60200260200101518661189b90919063ffffffff16565b60009182526001808601602052604090922090910155565b610ae681615281565b9050610a77565b50610af98c8c8c6118b0565b6001600160a01b03808c16908d167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c86610b348d6000611a20565b604051610b429291906152ad565b60405180910390a35050505050505050610b5c6001600c55565b9392505050565b600081610b6f81611600565b610b776113c1565b610b5c83611af1565b606080606080606085610b9281611600565b6060610b9d88611b13565b5082519197509550909150806001600160401b03811115610bc057610bc0614c05565b604051908082528060200260200182016040528015610be9578160200160208202803683370190505b509750806001600160401b03811115610c0457610c04614c05565b604051908082528060200260200182016040528015610c2d578160200160208202803683370190505b509650806001600160401b03811115610c4857610c48614c05565b604051908082528060200260200182016040528015610c71578160200160208202803683370190505b50935060005b81811015610d8957828181518110610c9157610c91615242565b602002602001015160000151898281518110610caf57610caf615242565b60200260200101906001600160a01b031690816001600160a01b031681525050828181518110610ce157610ce1615242565b602002602001015160200151888281518110610cff57610cff615242565b60200260200101906002811115610d1857610d18614a81565b90816002811115610d2b57610d2b614a81565b81525050828181518110610d4157610d41615242565b602002602001015160400151858281518110610d5f57610d5f615242565b6001600160a01b039092166020928302919091019091015280610d8181615281565b915050610c77565b5050505091939590929450565b600081610da281611600565b610daa6113c1565b610b5c83611d56565b6000610dbd6113c1565b610dc8848484611d6a565b949350505050565b6000610dda6113c1565b506001600160a01b031660009081526007602052604090205490565b6000610e006113c1565b506001600160a01b038083166000908152600660209081526040808320938516835292905220545b92915050565b6000610e386113c1565b5060095490565b600081610e4b81611600565b610e536113c1565b6001600160a01b038316600090815260208190526040902054610e7590611dbb565b60a001516001600160401b03169392505050565b6000610e936113c1565b50600b54600160a01b900460ff1690565b6000610eae6116a0565b86610eb881611600565b87610ec1611f1c565b610eca81611f42565b610ed26113c1565b6000610edf8a6001611f74565b80516020015190915015610f115760405163218e374760e01b81526001600160a01b038b166004820152602401610720565b6020810151518751610f24908290612096565b6000610f438360a0015184608001518b6120ba9092919063ffffffff16565b8351610100015151909150156110075760405163038293c560e31b81526001600160a01b038d1690631c149e2890610f819084908b90600401615304565b6020604051808303816000875af1158015610fa0573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610fc49190615332565b1515600003610fe657604051636061292560e01b815260040160405180910390fd5b610fef836121b7565b60a08301516080840151611004918b916120ba565b90505b6110168c8c858d8d868e6123f8565b8351610100015160200151909650156110be576040516338be241d60e01b81526001600160a01b038d16906338be241d906110599084908a908c9060040161534f565b6020604051808303816000875af1158015611078573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061109c9190615332565b15156000036110be57604051630791ede360e11b815260040160405180910390fd5b50505050509695505050505050565b6000816110d981611600565b6110e16113c1565b610b5c83612703565b60006110f46113c1565b6111003385858561145a565b5060019392505050565b60006111146113c1565b5060085490565b60006111256113c1565b610e2882612725565b60608161113a81611600565b6111426113c1565b610b5c83612747565b600061081b600c5460021490565b60006111636113c1565b5060055490565b60006111746113c1565b61110033858585612820565b600061118a6113c1565b6001600160a01b0382166000908152600f6020526040902054610e28565b606032156111c9576040516333fc255960e11b815260040160405180910390fd5b600b54600160a01b900460ff16156111f457604051633d0cc44360e11b815260040160405180910390fd5b600480546001810182556000919091527f8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b0180546001600160a01b0319163317905561123e6113c1565b610b5c83838080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250339392503491505061295f565b600061128b6113c1565b506001600160a01b03166000908152600a602052604090205490565b6112af614837565b816112b981611600565b6112c16113c1565b6001600160a01b038316600090815260208190526040902054610b5c90611dbb565b60006112ed6113c1565b6001600160a01b038084166000908152600d6020908152604080832093861683529290522054610b5c565b61132061172e565b611328611f1c565b6113306113c1565b611386866040518060a00160405280888152602001878152602001866001600160a01b031681526020018580360381019061136b919061537a565b815260200161137f36869003860186615443565b90526129fc565b6113906001600c55565b505050505050565b3660008037600080366000845af43d6000803e8080156113b7573d6000f35b3d6000fd5b505050565b6106f37f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316612f20565b6000611400858585611d6a565b90506000198114611453578082111561144557604051637dc7a0d960e11b81526001600160a01b03841660048201526024810182905260448101839052606401610720565b611453858585858503612820565b5050505050565b6001600160a01b03831661148c57604051634b637e8f60e11b81526001600160a01b0384166004820152602401610720565b6001600160a01b0382166114be5760405163ec442f0560e01b81526001600160a01b0383166004820152602401610720565b6001600160a01b038085166000908152600d60209081526040808320938716835292905220548082111561151e5760405163391434e360e21b81526001600160a01b03851660048201526024810182905260448101839052606401610720565b6001600160a01b038581166000818152600d6020908152604080832089861680855290835281842088880390559488168084529281902080548801905551868152919392917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b0385811660048301528481166024830152604482018490528616906323de6651906064015b600060405180830381600087803b1580156115e157600080fd5b505af11580156115f5573d6000803e3d6000fd5b505050505050505050565b61160981612725565b611631576040516327946f5760e21b81526001600160a01b0382166004820152602401610720565b50565b6001600160a01b03811660009081526020819052604081205481908190819061165c90612f49565b9150915081801561169657506116927f00000000000000000000000000000000000000000000000000000000000000008261526e565b4211155b9590945092505050565b6004546000036116c257604051625185ab60e41b815260040160405180910390fd5b60048054600091906116d69060019061529a565b815481106116e6576116e6615242565b6000918252602090912001546001600160a01b03169050338114611631576040516327c2144960e21b81523360048201526001600160a01b0382166024820152604401610720565b6002600c540361175157604051633ee5aeb560e01b815260040160405180910390fd5b6002600c55565b61176181611af1565b61163157604051634bdace1360e01b81526001600160a01b0382166004820152602401610720565b61179281612703565b6116315760405163ef029adf60e01b81526001600160a01b0382166004820152602401610720565b606060006117c88385612f6f565b905084516001600160401b038111156117e3576117e3614c05565b60405190808252806020026020018201604052801561180c578160200160208202803683370190505b50915060005b8551811015611876576118478287838151811061183157611831615242565b6020026020010151612f9090919063ffffffff16565b83828151811061185957611859615242565b60209081029190910101528061186e81615281565b915050611812565b50509392505050565b6113bc8361188c84612fb1565b611895906154a1565b83612ffb565b6000610b5c826118ab8560801c90565b6130cf565b6001600160a01b0382166118e257604051634b637e8f60e11b81526001600160a01b0383166004820152602401610720565b6001600160a01b038084166000908152600d6020908152604080832093861683529290522054808211156119425760405163391434e360e21b81526001600160a01b03841660048201526024810182905260448101839052606401610720565b6001600160a01b038085166000818152600d6020908152604080832094881683529381528382208686039055918152600f9091529081205461198590849061529a565b905061199081613114565b6001600160a01b038581166000818152600f60209081526040808320869055518781529193881692917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b03858116600483015260006024830152604482018590528616906323de6651906064016115c7565b606082516001600160401b03811115611a3b57611a3b614c05565b604051908082528060200260200182016040528015611a64578160200160208202803683370190505b50905060005b8351811015611aea5782611aa057838181518110611a8a57611a8a615242565b6020026020010151611a9b906154a1565b611abb565b838181518110611ab257611ab2615242565b60200260200101515b828281518110611acd57611acd615242565b602090810291909101015280611ae281615281565b915050611a6a565b5092915050565b6001600160a01b038116600090815260208190526040812054610e2890613144565b6060806060611b20614837565b6001600160a01b0385166000908152600260209081526040808320600390925282209091611b4c835490565b6001600160a01b038916600090815260208190526040902054909150611b7190611dbb565b9350806001600160401b03811115611b8b57611b8b614c05565b604051908082528060200260200182016040528015611bdd57816020015b604080516080810182526000808252602080830182905292820181905260608201528252600019909201910181611ba95790505b509650806001600160401b03811115611bf857611bf8614c05565b604051908082528060200260200182016040528015611c21578160200160208202803683370190505b509550611c2e8482613160565b945060008060005b83811015611d495760008181526001808801602052604090912080549101546001600160a01b0390911690935091506001600160801b038316898281518110611c8157611c81615242565b6020908102919091018101919091526001600160a01b038381166000908152878352604090819020815160808101909252805492831682529092909190830190600160a01b900460ff166002811115611cdc57611cdc614a81565b6002811115611ced57611ced614a81565b8152600191909101546001600160a01b0381166020830152600160a01b900460ff1615156040909101528a518b9083908110611d2b57611d2b615242565b60200260200101819052508080611d4190615281565b915050611c36565b5050505050509193509193565b600080611d6283611634565b509392505050565b6000306001600160a01b03831603611d855750600019610b5c565b506001600160a01b038084166000908152600e602090815260408083208685168452825280832093851683529290522054610b5c565b611dc3614837565b604051806101400160405280611dd884613230565b15158152602001611de884613144565b15158152602001611df88461323b565b15158152602001611e0884613256565b15158152602001611e18846132d4565b15158152602001611e28846132e4565b6001600160401b03168152602001611e3f846133a8565b62ffffff168152602001611e5284613474565b63ffffffff168152602001604051806101000160405280611e728661354d565b15158152602001611e828661355d565b15158152602001611e928661356d565b15158152602001611ea28661357d565b15158152602001611eb28661358d565b15158152602001611ec28661359d565b15158152602001611ed2866135ad565b15158152602001611ee2866135bd565b151581525081526020016040518060400160405280611f00866135cd565b15158152602001611f10866135e8565b15159052905292915050565b611f24613603565b156106f3576040516336a7e2cd60e21b815260040160405180910390fd5b611f4b81611d56565b156116315760405163d971f59760e01b81526001600160a01b0382166004820152602401610720565b611f7c6148ce565b611f8461172e565b6060611f908484613641565b8051919350915060005b8181101561207f57600084602001518281518110611fba57611fba615242565b60200260200101516000015190506000848381518110611fdc57611fdc615242565b60200260200101519050600081111561206c576001600160a01b0382166000908152600a60205260408120805483929061201790849061526e565b92505081905550816001600160a01b0316886001600160a01b03167f0954687c12bae94d7ea785882bbed7766e38d72b5bc620f7c34167edd4f2db758360405161206391815260200190565b60405180910390a35b50508061207890615281565b9050611f9a565b5061208a858461389c565b5050610e286001600c55565b8082146120b65760405163aaad13f760e01b815260040160405180910390fd5b5050565b60606000845190506120cf8185518551613937565b6000816001600160401b038111156120e9576120e9614c05565b604051908082528060200260200182016040528015612112578160200160208202803683370190505b50905060005b828110156121ad5761218086828151811061213557612135615242565b602002602001015186838151811061214f5761214f615242565b602002602001015189848151811061216957612169615242565b60200260200101516139649092919063ffffffff16565b82828151811061219257612192615242565b60209081029190910101526121a681615281565b9050612118565b5095945050505050565b602081015151806001600160401b038111156121d5576121d5614c05565b6040519080825280602002602001820160405280156121fe578160200160208202803683370190505b50608083015260005b818110156113bc5760008360200151828151811061222757612227615242565b60200260200101516020015190506000600281111561224857612248614a81565b81600281111561225a5761225a614a81565b0361228f57670de0b6b3a76400008460800151838151811061227e5761227e615242565b6020026020010181815250506123e7565b60018160028111156122a3576122a3614a81565b0361234157836020015182815181106122be576122be615242565b6020026020010151604001516001600160a01b031663679aefce6040518163ffffffff1660e01b8152600401602060405180830381865afa158015612307573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061232b91906154bd565b8460800151838151811061227e5761227e615242565b600281600281111561235557612355614a81565b036123ce578360200151828151811061237057612370615242565b6020026020010151600001516001600160a01b03166307a2d13a670de0b6b3a76400006040518263ffffffff1660e01b81526004016123b191815260200190565b602060405180830381865afa158015612307573d6000803e3d6000fd5b604051636fa2831960e11b815260040160405180910390fd5b506123f181615281565b9050612207565b600061240261172e565b6001600160a01b0388166000908152600260205260408120905b87602001515181101561257a5760008860200151828151811061244157612441615242565b602002602001015160000151905087828151811061246157612461615242565b60200260200101516001600160a01b0316816001600160a01b0316146124ed578a88838151811061249457612494615242565b60209081029190910101516040517fffe261a10000000000000000000000000000000000000000000000000000000081526001600160a01b03928316600482015290821660248201529082166044820152606401610720565b6125118188848151811061250357612503615242565b60200260200101513361397a565b6125698261255189858151811061252a5761252a615242565b602002602001015189868151811061254457612544615242565b60200260200101516130cf565b60009182526001808701602052604090922090910155565b5061257381615281565b905061241c565b506001600160a01b03808916908a167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c886125b6896001611a20565b6040516125c49291906152ad565b60405180910390a38651600160209091015286516125e190613987565b6001600160a01b038a16600081815260208190526040908190209290925590516380de451d60e01b81526380de451d9061261f908790600401614a35565b602060405180830381865afa15801561263c573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061266091906154bd565b915061266b82613114565b612678620f42408361529a565b915061268389614176565b61268e898984614271565b828210156126b957604051638d261d5d60e01b81526004810183905260248101849052604401610720565b6040516001600160a01b038a16907fcad8c9d32507393b6508ca4a888b81979919b477510585bde8488f153072d6f390600090a2506126f86001600c55565b979650505050505050565b6001600160a01b038116600090815260208190526040812054610e2890613256565b6001600160a01b038116600090815260208190526040812054610e2890613230565b6001600160a01b038116600090815260026020526040902060609061276a815490565b6001600160401b0381111561278157612781614c05565b6040519080825280602002602001820160405280156127aa578160200160208202803683370190505b50915060005b825181101561281957600081815260018301602052604090205483516001600160a01b03909116908490839081106127ea576127ea615242565b60200260200101816001600160a01b03166001600160a01b0316815250508061281290615281565b90506127b0565b5050919050565b6001600160a01b0383166128525760405163e602df0560e01b81526001600160a01b0384166004820152602401610720565b6001600160a01b03821661288457604051634a1406b160e11b81526001600160a01b0383166004820152602401610720565b6001600160a01b038481166000818152600e6020908152604080832088861680855290835281842095881680855295835292819020869055518581529192917fa0175360a15bca328baf7ea85c7b784d58b222a50d0ce760b10dba336d226a61910160405180910390a4604051630ad0fe5760e31b81526001600160a01b038481166004830152838116602483015260448201839052851690635687f2b8906064015b600060405180830381600087803b15801561294157600080fd5b505af1158015612955573d6000803e3d6000fd5b5050505050505050565b6060814710156129845760405163cd78605960e01b8152306004820152602401610720565b600080856001600160a01b031684866040516129a091906154d6565b60006040518083038185875af1925050503d80600081146129dd576040519150601f19603f3d011682016040523d82523d6000602084013e6129e2565b606091505b50915091506129f286838361438e565b9695505050505050565b612a0582612725565b15612a2e576040516301b6ee3960e71b81526001600160a01b0383166004820152602401610720565b8051516002811015612a5357604051635ed4ba8f60e01b815260040160405180910390fd5b6004811115612a7557604051630e0f7beb60e31b815260040160405180910390fd5b6001600160a01b038316600090815260026020526040812090826001600160401b03811115612aa657612aa6614c05565b604051908082528060200260200182016040528015612acf578160200160208202803683370190505b5090506000805b84811015612e0f57600086600001518281518110612af657612af6615242565b60200260200101519050600081600001519050836001600160a01b0316816001600160a01b03161015612b3c57604051636e8f194760e01b815260040160405180910390fd5b9250826001600160a01b0381161580612b665750886001600160a01b0316816001600160a01b0316145b15612b845760405163c1ab6dc160e01b815260040160405180910390fd5b612b90868260006143ea565b1515600003612bbd576040516327a5b1a760e11b81526001600160a01b0382166004820152602401610720565b6040808301516001600160a01b038b811660009081526003602090815284822086841683528152939020855181549083166001600160a01b0319821681178355948701519390921615159386939192839174ffffffffffffffffffffffffffffffffffffffffff1990911617600160a01b836002811115612c4057612c40614a81565b02179055506040820151600190910180546060909301511515600160a01b0274ffffffffffffffffffffffffffffffffffffffffff199093166001600160a01b0390921691909117919091179055600083602001516002811115612ca657612ca6614a81565b03612ccf578015612cca57604051636fa2831960e11b815260040160405180910390fd5b612d68565b600183602001516002811115612ce757612ce7614a81565b03612d0f57801515600003612cca57604051636fa2831960e11b815260040160405180910390fd5b600283602001516002811115612d2757612d27614a81565b03612d4f57826060015115612cca57604051636fa2831960e11b815260040160405180910390fd5b60405163a1e9dd9d60e01b815260040160405180910390fd5b816001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015612da6573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612dca91906154f2565b612dd5906012615515565b868581518110612de757612de7615242565b602002602001019060ff16908160ff168152505050505080612e0890615281565b9050612ad6565b506040858101516001600160a01b0388811660009081526001602090815284822080546001600160a01b031916939094169290921790925581905290812054612e5790611dbb565b60018152606087015161010082015260808701516101208201529050612e7c83614499565b62ffffff1660c08201526020860151612e9490614500565b63ffffffff1660e0820152612ea881613987565b6001600160a01b03881660008181526020818152604091829020939093558851928901518982015160608b015160808c0151935133967f446454f4aa9a3f9251e3d036114f917fc005a7e94a64e319d5a67aa30bf54a2895612f0f9591949193919261552e565b60405180910390a350505050505050565b306001600160a01b0382161461163157604051634fe92d9b60e11b815260040160405180910390fd5b600080612f558361323b565b612f5e84613474565b909463ffffffff9091169350915050565b600080612f84670de0b6b3a7640000856155e3565b9050610dc883826155fa565b600080612f9d83856155e3565b9050610dc8670de0b6b3a7640000826155fa565b60007f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821115612ff75760405163123baf0360e11b815260048101839052602401610720565b5090565b8160000361300857505050565b6001600160a01b0381163314613042576040516327c2144960e21b81526001600160a01b0382166004820152336024820152604401610720565b6001600160a01b03808216600090815260066020908152604080832093871683529290529081205490613075848361561c565b90508060000361308e57600580546000190190556130a0565b816000036130a0576005805460010190555b6001600160a01b0392831660009081526006602090815260408083209790951682529590955291909320555050565b60006001600160801b038311806130ec57506001600160801b0382115b1561310a576040516389560ca160e01b815260040160405180910390fd5b610b5c8383614531565b620f424081101561163157604051634ddaf4a960e01b815260048101829052620f42406024820152604401610720565b6000610e28613154826001615644565b839060ff161c60011690565b60606000826001600160401b0381111561317c5761317c614c05565b6040519080825280602002602001820160405280156131a5578160200160208202803683370190505b5060c085015190915062ffffff1660005b848110156132265760006131d76131ce6005846155e3565b84901c601f1690565b90506131e481600a615741565b6131f690670de0b6b3a76400006155e3565b84838151811061320857613208615242565b6020908102919091010152508061321e81615281565b9150506131b6565b5090949350505050565b600060018216610e28565b6000610e2861324b826001615644565b613154906001615644565b6000610e28613266826001615644565b613271906001615644565b61327c906001615644565b613287906001615644565b613292906001615644565b61329d906001615644565b6132a8906001615644565b6132b3906001615644565b6132be906001615644565b6132c9906001615644565b61324b906001615644565b6000610e286132c9826001615644565b6000610e286133a36132f7836001615644565b613302906001615644565b61330d906001615644565b613318906001615644565b613323906001615644565b61332e906001615644565b613339906001615644565b613344906001615644565b61334f906001615644565b61335a906001615644565b613365906001615644565b613370906001615644565b61337b906001615644565b613386906001615644565b613391906001615644565b60ff1684901c6001600160401b031690565b614541565b6000610e2861346f60406133bd846001615644565b6133c8906001615644565b6133d3906001615644565b6133de906001615644565b6133e9906001615644565b6133f4906001615644565b6133ff906001615644565b61340a906001615644565b613415906001615644565b613420906001615644565b61342b906001615644565b613436906001615644565b613441906001615644565b61344c906001615644565b613457906001615644565b6134619190615644565b60ff1684901c62ffffff1690565b614577565b6000610e286135486018604061348b856001615644565b613496906001615644565b6134a1906001615644565b6134ac906001615644565b6134b7906001615644565b6134c2906001615644565b6134cd906001615644565b6134d8906001615644565b6134e3906001615644565b6134ee906001615644565b6134f9906001615644565b613504906001615644565b61350f906001615644565b61351a906001615644565b613525906001615644565b61352f9190615644565b6135399190615644565b60ff1684901c63ffffffff1690565b614500565b6000610e2861327c826001615644565b6000610e28613271826001615644565b6000610e286132be826001615644565b6000610e286132b3826001615644565b6000610e286132a8826001615644565b6000610e2861329d826001615644565b6000610e28613292826001615644565b6000610e28613287826001615644565b6000610e286135dd826001615644565b613266906001615644565b6000610e286135f8826001615644565b6135dd906001615644565b60007f0000000000000000000000000000000000000000000000000000000000000000421115801561081b575050600b54600160a81b900460ff1690565b6136496148ce565b606061365484611b13565b855260a08501526040808501919091526020808501929092526001600160a01b0386166000908152600290925281209061368c825490565b9050806001600160401b038111156136a6576136a6614c05565b6040519080825280602002602001820160405280156136cf578160200160208202803683370190505b509250806001600160401b038111156136ea576136ea614c05565b604051908082528060200260200182016040528015613713578160200160208202803683370190505b506060850152600954613725856121b7565b845160200151600090801561373a5750600082115b80156137495750855160600151155b905060005b838110156138905760008760200151828151811061376e5761376e615242565b6020026020010151602001519050613787888a846145a7565b6000600282600281111561379d5761379d614a81565b14806137e7575060018260028111156137b8576137b8614a81565b1480156137e75750886020015183815181106137d6576137d6615242565b602090810291909101015160600151155b90508380156137f35750805b1561387d576000838152600188810160205260408220015461381b908b9060801c868961465f565b9050801561387b578089858151811061383657613836615242565b602002602001018181525050808a60400151858151811061385957613859615242565b6020026020010181815161386d919061529a565b90525061387b8a8c866145a7565b505b50508061388990615281565b905061374e565b50505050509250929050565b6001600160a01b0382166000908152600260205260409081902060a083015160808401519284015191926138d19291906120ba565b606083015260005b8260400151518110156139315761392181610ac58560400151848151811061390357613903615242565b60200260200101518660600151858151811061254457612544615242565b61392a81615281565b90506138d9565b50505050565b81831415806139465750808214155b156113bc5760405163aaad13f760e01b815260040160405180910390fd5b6000610dc8826139748686612f90565b90612f90565b6113bc8361189584612fb1565b60808101516000908190613aa2906139a0836001615644565b6139ab906001615644565b6139b6906001615644565b60ff16613a958660600151600060016139cf9190615644565b6139da906001615644565b6139e5906001615644565b6139f0906001615644565b6139fb906001615644565b613a06906001615644565b613a11906001615644565b613a1c906001615644565b613a27906001615644565b613a32906001615644565b613a3d906001615644565b613a48906001615644565b60ff16613a95896040015160006001613a619190615644565b613a6c906001615644565b60ff16613a958c6020015160006001613a859190615644565b8e5160ff91909116906001198e16175b6001821b191691901b1790565b9050613b3c8361010001516060015160006001613abf9190615644565b613aca906001615644565b613ad5906001615644565b613ae0906001615644565b613aeb906001615644565b60ff16613a958661010001516040015160006001613b099190615644565b613b14906001615644565b613b1f906001615644565b613b2a906001615644565b60ff1690811b600190911b1986161790565b9050613ce383610100015160e0015160006001613b599190615644565b613b64906001615644565b613b6f906001615644565b613b7a906001615644565b613b85906001615644565b613b90906001615644565b613b9b906001615644565b613ba6906001615644565b613bb1906001615644565b60ff16613a9586610100015160c0015160006001613bcf9190615644565b613bda906001615644565b613be5906001615644565b613bf0906001615644565b613bfb906001615644565b613c06906001615644565b613c11906001615644565b613c1c906001615644565b60ff16613a9589610100015160a0015160006001613c3a9190615644565b613c45906001615644565b613c50906001615644565b613c5b906001615644565b613c66906001615644565b613c71906001615644565b613c7c906001615644565b60ff16613a958c61010001516080015160006001613c9a9190615644565b613ca5906001615644565b613cb0906001615644565b613cbb906001615644565b613cc6906001615644565b613cd1906001615644565b60ff1690811b600190911b198c161790565b9050613f078361012001516020015160006001613d009190615644565b613d0b906001615644565b613d16906001615644565b613d21906001615644565b613d2c906001615644565b613d37906001615644565b613d42906001615644565b613d4d906001615644565b613d58906001615644565b613d63906001615644565b613d6e906001615644565b613d79906001615644565b613d84906001615644565b613d8f906001615644565b60ff16613a958661012001516000015160006001613dad9190615644565b613db8906001615644565b613dc3906001615644565b613dce906001615644565b613dd9906001615644565b613de4906001615644565b613def906001615644565b613dfa906001615644565b613e05906001615644565b613e10906001615644565b613e1b906001615644565b613e26906001615644565b613e31906001615644565b60ff16613a958961010001516020015160006001613e4f9190615644565b613e5a906001615644565b613e65906001615644565b613e70906001615644565b613e7b906001615644565b613e86906001615644565b613e91906001615644565b613e9c906001615644565b613ea7906001615644565b613eb2906001615644565b613ebd906001615644565b60ff16613a958c61010001516000015160006001613edb9190615644565b613ee6906001615644565b613ef1906001615644565b613efc906001615644565b613c9a906001615644565b9050610b5c8360e0015163ffffffff166018604060006001613f299190615644565b613f34906001615644565b613f3f906001615644565b613f4a906001615644565b613f55906001615644565b613f60906001615644565b613f6b906001615644565b613f76906001615644565b613f81906001615644565b613f8c906001615644565b613f97906001615644565b613fa2906001615644565b613fad906001615644565b613fb8906001615644565b613fc3906001615644565b613fcd9190615644565b613fd79190615644565b60ff16602060ff1661416e8760a001516001600160401b031660006001613ffe9190615644565b614009906001615644565b614014906001615644565b61401f906001615644565b61402a906001615644565b614035906001615644565b614040906001615644565b61404b906001615644565b614056906001615644565b614061906001615644565b61406c906001615644565b614077906001615644565b614082906001615644565b61408d906001615644565b614098906001615644565b60ff16604060ff1661416e8b60c0015162ffffff166040600060016140bd9190615644565b6140c8906001615644565b6140d3906001615644565b6140de906001615644565b6140e9906001615644565b6140f4906001615644565b6140ff906001615644565b61410a906001615644565b614115906001615644565b614120906001615644565b61412b906001615644565b614136906001615644565b614141906001615644565b61414c906001615644565b614157906001615644565b6141619190615644565b8b919060ff1660186146f7565b9291906146f7565b6001600160a01b0381166000908152600f602052604081208054620f424092906141a190849061526e565b90915550506001600160a01b0381166000818152600d6020908152604080832083805282528083208054620f424090810190915590519081529192839290917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526000600482018190526024820152620f424060448201526001600160a01b038216906323de665190606401600060405180830381600087803b15801561425d57600080fd5b505af1158015611453573d6000803e3d6000fd5b6001600160a01b0382166142a35760405163ec442f0560e01b81526001600160a01b0383166004820152602401610720565b6001600160a01b0383166000908152600f60205260408120546142c790839061526e565b6001600160a01b038086166000908152600d6020908152604080832093881683529290522080548401905590506142fd81613114565b6001600160a01b038481166000818152600f6020908152604080832086905551868152938716939192917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b8152600060048201526001600160a01b038481166024830152604482018490528516906323de665190606401612927565b6060826143a35761439e8261471a565b610b5c565b81511580156143ba57506001600160a01b0384163b155b156143e357604051639996b31560e01b81526001600160a01b0385166004820152602401610720565b5080610b5c565b6001600160a01b038216600090815260028401602052604081205480820361447957505082546040805180820182526001600160a01b03858116808352602080840187815260008781526001808c018452878220965187546001600160a01b03191696169590951786559051948401949094559482018089559083526002880190945291902091909155610b5c565b600019016000908152600180860160205260408220018390559050610b5c565b60008060005b83518110156144f6576144e28482815181106144bd576144bd615242565b602002602001015160ff16600560ff16836144d891906155e3565b84919060056146f7565b9150806144ee81615281565b91505061449f565b50610b5c81614577565b600063ffffffff821115612ff7576040516306dfcc6560e41b81526020600482015260248101839052604401610720565b6000610b5c83608084901b61526e565b60006001600160401b03821115612ff757604080516306dfcc6560e41b8152600481019190915260248101839052604401610720565b600062ffffff821115612ff7576040516306dfcc6560e41b81526018600482015260248101839052604401610720565b61490a60008360018111156145be576145be614a81565b146145cb576139646145cf565b6147435b9050614637846040015183815181106145ea576145ea615242565b60200260200101518560a00151848151811061460857614608615242565b60200260200101518660800151858151811061462657614626615242565b60200260200101518463ffffffff16565b8460600151838151811061464d5761464d615242565b60200260200101818152505050505050565b6000808560600151848151811061467857614678615242565b60200260200101519050848111156146ee57600085820390506146ea8760a0015186815181106146aa576146aa615242565b6020026020010151886080015187815181106146c8576146c8615242565b60200260200101516146e38785612f9090919063ffffffff16565b9190614759565b9250505b50949350505050565b600061470484848461476e565b506001901b60001901811b1992909216911b1790565b80511561472a5780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b6000610dc88261475386866147f4565b906147f4565b6000610dc88461476985856147f4565b612f6f565b610100821061479057604051632d0483c560e21b815260040160405180910390fd5b600181101580156147b657506147b260ff6147ad8461010061529a565b614821565b8111155b6147d357604051632d0483c560e21b815260040160405180910390fd5b82811c156113bc5760405163e4337c0560e01b815260040160405180910390fd5b60008061480183856155e3565b90506001670de0b6b3a76400006001830304018115150291505092915050565b60008183106148305781610b5c565b5090919050565b6040805161014081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e080880187905288516101008082018b52888252818801899052818b01899052958101889052938401879052918301869052820185905281018490529084015283518085019094528184528301529061012082015290565b6040518060c001604052806148e1614837565b815260200160608152602001606081526020016060815260200160608152602001606081525090565b6106f361574d565b60006020828403121561492457600080fd5b5035919050565b6001600160a01b038116811461163157600080fd5b80356107548161492b565b6000806000806080858703121561496157600080fd5b843561496c8161492b565b9350602085013561497c8161492b565b9250604085013561498c8161492b565b9396929550929360600135925050565b6000602082840312156149ae57600080fd5b8135610b5c8161492b565b6000806000606084860312156149ce57600080fd5b83356149d98161492b565b925060208401356149e98161492b565b929592945050506040919091013590565b600081518084526020808501945080840160005b83811015614a2a57815187529582019590820190600101614a0e565b509495945050505050565b602081526000610b5c60208301846149fa565b600081518084526020808501945080840160005b83811015614a2a5781516001600160a01b031687529582019590820190600101614a5c565b634e487b7160e01b600052602160045260246000fd5b60038110614ab557634e487b7160e01b600052602160045260246000fd5b9052565b60a081526000614acc60a0830188614a48565b82810360208481019190915287518083528882019282019060005b81811015614b0a57614afa838651614a97565b9383019391830191600101614ae7565b50508481036040860152614b1e81896149fa565b9250508382036060850152614b3382876149fa565b8481036080860152855180825282870193509082019060005b81811015614b715784516001600160a01b031683529383019391830191600101614b4c565b50909a9950505050505050505050565b600080600060608486031215614b9657600080fd5b8335614ba18161492b565b92506020840135614bb18161492b565b91506040840135614bc18161492b565b809150509250925092565b60008060408385031215614bdf57600080fd5b8235614bea8161492b565b91506020830135614bfa8161492b565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b604051608081016001600160401b0381118282101715614c3d57614c3d614c05565b60405290565b604051601f8201601f191681016001600160401b0381118282101715614c6b57614c6b614c05565b604052919050565b60006001600160401b03821115614c8c57614c8c614c05565b5060051b60200190565b600082601f830112614ca757600080fd5b81356020614cbc614cb783614c73565b614c43565b82815260059290921b84018101918181019086841115614cdb57600080fd5b8286015b84811015614cf65780358352918301918301614cdf565b509695505050505050565b600082601f830112614d1257600080fd5b81356001600160401b03811115614d2b57614d2b614c05565b614d3e601f8201601f1916602001614c43565b818152846020838601011115614d5357600080fd5b816020850160208301376000918101602001919091529392505050565b60008060008060008060c08789031215614d8957600080fd5b8635614d948161492b565b9550602087810135614da58161492b565b955060408801356001600160401b0380821115614dc157600080fd5b818a0191508a601f830112614dd557600080fd5b8135614de3614cb782614c73565b81815260059190911b8301840190848101908d831115614e0257600080fd5b938501935b82851015614e29578435614e1a8161492b565b82529385019390850190614e07565b9850505060608a0135925080831115614e4157600080fd5b614e4d8b848c01614c96565b955060808a0135945060a08a0135925080831115614e6a57600080fd5b5050614e7889828a01614d01565b9150509295509295509295565b602081526000610b5c6020830184614a48565b60008060208385031215614eab57600080fd5b82356001600160401b0380821115614ec257600080fd5b818501915085601f830112614ed657600080fd5b813581811115614ee557600080fd5b866020828501011115614ef757600080fd5b60209290920196919550909350505050565b60005b83811015614f24578181015183820152602001614f0c565b50506000910152565b60008151808452614f45816020860160208601614f09565b601f01601f19169290920160200192915050565b602081526000610b5c6020830184614f2d565b80511515825260208101511515602083015260408101511515604083015260608101511515606083015260808101511515608083015260a0810151614fb560a084018215159052565b5060c0810151614fc960c084018215159052565b5060e08101516113bc60e084018215159052565b81511515815261024081016020830151614ffb602084018215159052565b50604083015161500f604084018215159052565b506060830151615023606084018215159052565b506080830151615037608084018215159052565b5060a083015161505260a08401826001600160401b03169052565b5060c083015161506960c084018262ffffff169052565b5060e083015161508160e084018263ffffffff169052565b506101008084015161509582850182614f6c565b50506101208301518051151561020084015260208101511515610220840152611aea565b801515811461163157600080fd5b8035610754816150b9565b600061010082840312156150e557600080fd5b50919050565b6000604082840312156150e557600080fd5b6000806000806000806101c0878903121561511757600080fd5b86356151228161492b565b95506020878101356001600160401b0381111561513e57600080fd5b8801601f81018a1361514f57600080fd5b803561515d614cb782614c73565b81815260079190911b8201830190838101908c83111561517c57600080fd5b928401925b828410156151fd576080848e03121561519a5760008081fd5b6151a2614c1b565b84356151ad8161492b565b815284860135600381106151c15760008081fd5b818701526040858101356151d48161492b565b908201526060858101356151e7816150b9565b9082015282526080939093019290840190615181565b985050505060408801359450615217905060608801614940565b925061522688608089016150d2565b91506152368861018089016150eb565b90509295509295509295565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b80820180821115610e2857610e28615258565b60006001820161529357615293615258565b5060010190565b81810381811115610e2857610e28615258565b6040815260006152c06040830185614a48565b82810360208481019190915284518083528582019282019060005b818110156152f7578451835293830193918301916001016152db565b5090979650505050505050565b60408152600061531760408301856149fa565b82810360208401526153298185614f2d565b95945050505050565b60006020828403121561534457600080fd5b8151610b5c816150b9565b60608152600061536260608301866149fa565b84602084015282810360408401526129f28185614f2d565b600061010080838503121561538e57600080fd5b604051908101906001600160401b03821181831017156153b0576153b0614c05565b81604052833591506153c1826150b9565b8181526153d0602085016150c7565b60208201526153e1604085016150c7565b60408201526153f2606085016150c7565b6060820152615403608085016150c7565b608082015261541460a085016150c7565b60a082015261542560c085016150c7565b60c082015261543660e085016150c7565b60e0820152949350505050565b60006040828403121561545557600080fd5b604051604081018181106001600160401b038211171561547757615477614c05565b6040528235615485816150b9565b81526020830135615495816150b9565b60208201529392505050565b6000600160ff1b82016154b6576154b6615258565b5060000390565b6000602082840312156154cf57600080fd5b5051919050565b600082516154e8818460208701614f09565b9190910192915050565b60006020828403121561550457600080fd5b815160ff81168114610b5c57600080fd5b60ff8281168282160390811115610e2857610e28615258565b6101a080825286519082018190526000906101c0830190602090818a01845b828110156155a15781516001600160a01b038082511687528582015161557587890182614a97565b50604082810151909116908701526060908101511515908601526080909401939083019060010161554d565b50505083018790526001600160a01b038616604084015290506155c76060830185614f6c565b82511515610160830152602083015115156101808301526129f2565b8082028115828204841417610e2857610e28615258565b60008261561757634e487b7160e01b600052601260045260246000fd5b500490565b808201828112600083128015821682158216171561563c5761563c615258565b505092915050565b60ff8181168382160190811115610e2857610e28615258565b600181815b8085111561569857816000190482111561567e5761567e615258565b8085161561568b57918102915b93841c9390800290615662565b509250929050565b6000826156af57506001610e28565b816156bc57506000610e28565b81600181146156d257600281146156dc576156f8565b6001915050610e28565b60ff8411156156ed576156ed615258565b50506001821b610e28565b5060208310610133831016604e8410600b841016171561571b575081810a610e28565b615725838361565d565b806000190482111561573957615739615258565b029392505050565b6000610b5c83836156a0565b634e487b7160e01b600052605160045260246000fdfea2646970667358221220207ac99485f2742c90b0feab377819c1fd00f4a91b80038649a81c629135477064736f6c63430008150033",
  deployedBytecode:
    "0x6080604052600436106101f25760003560e01c8063ba8a2be01161010d578063e1f21c67116100a0578063f29486a11161006f578063f29486a114610612578063f7888aec1461063f578063fbfa77cf1461065f578063fc5e93fe14610692578063fea5ec5d146106aa57610210565b8063e1f21c6714610592578063e4dc2aa4146105b2578063edfa3568146105d2578063f27dd8ab146105f257610210565b8063c673bdaf116100dc578063c673bdaf1461051b578063ca4f28031461053b578063d2c725e014610568578063db8171871461057d57610210565b8063ba8a2be0146104a6578063be7d628a146104c6578063beabacc8146104e6578063c2372f821461050657610210565b80636c9bc73211610185578063ab8f258d11610154578063ab8f258d1461043c578063b099a7991461045c578063b45090f914610471578063b4aef0ab1461049157610210565b80636c9bc732146103c55780638b19548d146103e5578063927da105146103fc578063967870921461041c57610210565b80631ba0ae45116101c15780631ba0ae45146103145780633a2d133b14610347578063532cec7c1461037457806367e0e0761461039457610210565b80630b1bd243146102395780630f950ea61461027657806315dacbea1461029957806315e32046146102c957610210565b3661021057604051637911c44b60e11b815260040160405180910390fd5b341561022f57604051637911c44b60e11b815260040160405180910390fd5b6102376106ca565b005b34801561024557600080fd5b50610259610254366004614912565b6106f5565b6040516001600160a01b0390911681526020015b60405180910390f35b34801561028257600080fd5b5061028b610759565b60405190815260200161026d565b3480156102a557600080fd5b506102b96102b436600461494b565b61076a565b604051901515815260200161026d565b3480156102d557600080fd5b506102e96102e436600461499c565b610797565b6040805194151585526020850193909352918301526001600160a01b0316606082015260800161026d565b34801561032057600080fd5b507f0000000000000000000000000000000000000000000000000000000000000000610259565b34801561035357600080fd5b506103676103623660046149b9565b610820565b60405161026d9190614a35565b34801561038057600080fd5b506102b961038f36600461499c565b610b63565b3480156103a057600080fd5b506103b46103af36600461499c565b610b80565b60405161026d959493929190614ab9565b3480156103d157600080fd5b506102b96103e036600461499c565b610d96565b3480156103f157600080fd5b5061028b6276a70081565b34801561040857600080fd5b5061028b610417366004614b81565b610db3565b34801561042857600080fd5b5061028b61043736600461499c565b610dd0565b34801561044857600080fd5b5061028b610457366004614bcc565b610df6565b34801561046857600080fd5b5061028b610e2e565b34801561047d57600080fd5b5061028b61048c36600461499c565b610e3f565b34801561049d57600080fd5b506102b9610e89565b3480156104b257600080fd5b5061028b6104c1366004614d70565b610ea4565b3480156104d257600080fd5b506102b96104e136600461499c565b6110cd565b3480156104f257600080fd5b506102b96105013660046149b9565b6110ea565b34801561051257600080fd5b5061028b61110a565b34801561052757600080fd5b506102b961053636600461499c565b61111b565b34801561054757600080fd5b5061055b61055636600461499c565b61112e565b60405161026d9190614e85565b34801561057457600080fd5b506102b961114b565b34801561058957600080fd5b5061028b611159565b34801561059e57600080fd5b506102b96105ad3660046149b9565b61116a565b3480156105be57600080fd5b5061028b6105cd36600461499c565b611180565b6105e56105e0366004614e98565b6111a8565b60405161026d9190614f59565b3480156105fe57600080fd5b5061028b61060d36600461499c565b611281565b34801561061e57600080fd5b5061063261062d36600461499c565b6112a7565b60405161026d9190614fdd565b34801561064b57600080fd5b5061028b61065a366004614bcc565b6112e3565b34801561066b57600080fd5b507f0000000000000000000000000000000000000000000000000000000000000000610259565b34801561069e57600080fd5b5061028b630755580081565b3480156106b657600080fd5b506102376106c53660046150fd565b611318565b6106f37f0000000000000000000000000000000000000000000000000000000000000000611398565b565b60006106ff6113c1565b600454821061072957604051631adf3e3360e01b8152600481018390526024015b60405180910390fd5b6004828154811061073c5761073c615242565b6000918252602090912001546001600160a01b031690505b919050565b60006107636113c1565b5060045490565b60006107746113c1565b610780338587856113f3565b61078c3385858561145a565b506001949350505050565b600080600080846107a781611600565b6107af6113c1565b6000806107bb88611634565b909250905081816107ec7f00000000000000000000000000000000000000000000000000000000000000008261526e565b6001600160a01b03808c16600090815260016020526040902054939a5091985096501693505050509193509193565b905090565b606061082a6116a0565b61083261172e565b8361083c81611758565b8461084681611789565b6001600160a01b038616600090815260026020526040812090610867825490565b90506000816001600160401b0381111561088357610883614c05565b6040519080825280602002602001820160405280156108ac578160200160208202803683370190505b5090506000826001600160401b038111156108c9576108c9614c05565b6040519080825280602002602001820160405280156108f2578160200160208202803683370190505b5090506000805b848110156109955760008181526001808801602052604090912080549101546001600160a01b039091169085838151811061093657610936615242565b60200260200101819450826001600160a01b03166001600160a01b03168152505050610968826001600160801b031690565b83828151811061097a5761097a615242565b602090810291909101015261098e81615281565b90506108f9565b506109bf826109b98d6001600160a01b03166000908152600f602052604090205490565b8b6117ba565b975060005b84811015610a5c57610a098482815181106109e1576109e1615242565b60200260200101518a83815181106109fb576109fb615242565b60200260200101513361187f565b888181518110610a1b57610a1b615242565b6020026020010151838281518110610a3557610a35615242565b60200260200101818151610a49919061529a565b905250610a5581615281565b90506109c4565b506001600160a01b038b166000908152600260205260408120905b85811015610aed5760008181526001808401602052604090912001549250610add81610ac5868481518110610aae57610aae615242565b60200260200101518661189b90919063ffffffff16565b60009182526001808601602052604090922090910155565b610ae681615281565b9050610a77565b50610af98c8c8c6118b0565b6001600160a01b03808c16908d167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c86610b348d6000611a20565b604051610b429291906152ad565b60405180910390a35050505050505050610b5c6001600c55565b9392505050565b600081610b6f81611600565b610b776113c1565b610b5c83611af1565b606080606080606085610b9281611600565b6060610b9d88611b13565b5082519197509550909150806001600160401b03811115610bc057610bc0614c05565b604051908082528060200260200182016040528015610be9578160200160208202803683370190505b509750806001600160401b03811115610c0457610c04614c05565b604051908082528060200260200182016040528015610c2d578160200160208202803683370190505b509650806001600160401b03811115610c4857610c48614c05565b604051908082528060200260200182016040528015610c71578160200160208202803683370190505b50935060005b81811015610d8957828181518110610c9157610c91615242565b602002602001015160000151898281518110610caf57610caf615242565b60200260200101906001600160a01b031690816001600160a01b031681525050828181518110610ce157610ce1615242565b602002602001015160200151888281518110610cff57610cff615242565b60200260200101906002811115610d1857610d18614a81565b90816002811115610d2b57610d2b614a81565b81525050828181518110610d4157610d41615242565b602002602001015160400151858281518110610d5f57610d5f615242565b6001600160a01b039092166020928302919091019091015280610d8181615281565b915050610c77565b5050505091939590929450565b600081610da281611600565b610daa6113c1565b610b5c83611d56565b6000610dbd6113c1565b610dc8848484611d6a565b949350505050565b6000610dda6113c1565b506001600160a01b031660009081526007602052604090205490565b6000610e006113c1565b506001600160a01b038083166000908152600660209081526040808320938516835292905220545b92915050565b6000610e386113c1565b5060095490565b600081610e4b81611600565b610e536113c1565b6001600160a01b038316600090815260208190526040902054610e7590611dbb565b60a001516001600160401b03169392505050565b6000610e936113c1565b50600b54600160a01b900460ff1690565b6000610eae6116a0565b86610eb881611600565b87610ec1611f1c565b610eca81611f42565b610ed26113c1565b6000610edf8a6001611f74565b80516020015190915015610f115760405163218e374760e01b81526001600160a01b038b166004820152602401610720565b6020810151518751610f24908290612096565b6000610f438360a0015184608001518b6120ba9092919063ffffffff16565b8351610100015151909150156110075760405163038293c560e31b81526001600160a01b038d1690631c149e2890610f819084908b90600401615304565b6020604051808303816000875af1158015610fa0573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610fc49190615332565b1515600003610fe657604051636061292560e01b815260040160405180910390fd5b610fef836121b7565b60a08301516080840151611004918b916120ba565b90505b6110168c8c858d8d868e6123f8565b8351610100015160200151909650156110be576040516338be241d60e01b81526001600160a01b038d16906338be241d906110599084908a908c9060040161534f565b6020604051808303816000875af1158015611078573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061109c9190615332565b15156000036110be57604051630791ede360e11b815260040160405180910390fd5b50505050509695505050505050565b6000816110d981611600565b6110e16113c1565b610b5c83612703565b60006110f46113c1565b6111003385858561145a565b5060019392505050565b60006111146113c1565b5060085490565b60006111256113c1565b610e2882612725565b60608161113a81611600565b6111426113c1565b610b5c83612747565b600061081b600c5460021490565b60006111636113c1565b5060055490565b60006111746113c1565b61110033858585612820565b600061118a6113c1565b6001600160a01b0382166000908152600f6020526040902054610e28565b606032156111c9576040516333fc255960e11b815260040160405180910390fd5b600b54600160a01b900460ff16156111f457604051633d0cc44360e11b815260040160405180910390fd5b600480546001810182556000919091527f8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b0180546001600160a01b0319163317905561123e6113c1565b610b5c83838080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250339392503491505061295f565b600061128b6113c1565b506001600160a01b03166000908152600a602052604090205490565b6112af614837565b816112b981611600565b6112c16113c1565b6001600160a01b038316600090815260208190526040902054610b5c90611dbb565b60006112ed6113c1565b6001600160a01b038084166000908152600d6020908152604080832093861683529290522054610b5c565b61132061172e565b611328611f1c565b6113306113c1565b611386866040518060a00160405280888152602001878152602001866001600160a01b031681526020018580360381019061136b919061537a565b815260200161137f36869003860186615443565b90526129fc565b6113906001600c55565b505050505050565b3660008037600080366000845af43d6000803e8080156113b7573d6000f35b3d6000fd5b505050565b6106f37f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316612f20565b6000611400858585611d6a565b90506000198114611453578082111561144557604051637dc7a0d960e11b81526001600160a01b03841660048201526024810182905260448101839052606401610720565b611453858585858503612820565b5050505050565b6001600160a01b03831661148c57604051634b637e8f60e11b81526001600160a01b0384166004820152602401610720565b6001600160a01b0382166114be5760405163ec442f0560e01b81526001600160a01b0383166004820152602401610720565b6001600160a01b038085166000908152600d60209081526040808320938716835292905220548082111561151e5760405163391434e360e21b81526001600160a01b03851660048201526024810182905260448101839052606401610720565b6001600160a01b038581166000818152600d6020908152604080832089861680855290835281842088880390559488168084529281902080548801905551868152919392917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b0385811660048301528481166024830152604482018490528616906323de6651906064015b600060405180830381600087803b1580156115e157600080fd5b505af11580156115f5573d6000803e3d6000fd5b505050505050505050565b61160981612725565b611631576040516327946f5760e21b81526001600160a01b0382166004820152602401610720565b50565b6001600160a01b03811660009081526020819052604081205481908190819061165c90612f49565b9150915081801561169657506116927f00000000000000000000000000000000000000000000000000000000000000008261526e565b4211155b9590945092505050565b6004546000036116c257604051625185ab60e41b815260040160405180910390fd5b60048054600091906116d69060019061529a565b815481106116e6576116e6615242565b6000918252602090912001546001600160a01b03169050338114611631576040516327c2144960e21b81523360048201526001600160a01b0382166024820152604401610720565b6002600c540361175157604051633ee5aeb560e01b815260040160405180910390fd5b6002600c55565b61176181611af1565b61163157604051634bdace1360e01b81526001600160a01b0382166004820152602401610720565b61179281612703565b6116315760405163ef029adf60e01b81526001600160a01b0382166004820152602401610720565b606060006117c88385612f6f565b905084516001600160401b038111156117e3576117e3614c05565b60405190808252806020026020018201604052801561180c578160200160208202803683370190505b50915060005b8551811015611876576118478287838151811061183157611831615242565b6020026020010151612f9090919063ffffffff16565b83828151811061185957611859615242565b60209081029190910101528061186e81615281565b915050611812565b50509392505050565b6113bc8361188c84612fb1565b611895906154a1565b83612ffb565b6000610b5c826118ab8560801c90565b6130cf565b6001600160a01b0382166118e257604051634b637e8f60e11b81526001600160a01b0383166004820152602401610720565b6001600160a01b038084166000908152600d6020908152604080832093861683529290522054808211156119425760405163391434e360e21b81526001600160a01b03841660048201526024810182905260448101839052606401610720565b6001600160a01b038085166000818152600d6020908152604080832094881683529381528382208686039055918152600f9091529081205461198590849061529a565b905061199081613114565b6001600160a01b038581166000818152600f60209081526040808320869055518781529193881692917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526001600160a01b03858116600483015260006024830152604482018590528616906323de6651906064016115c7565b606082516001600160401b03811115611a3b57611a3b614c05565b604051908082528060200260200182016040528015611a64578160200160208202803683370190505b50905060005b8351811015611aea5782611aa057838181518110611a8a57611a8a615242565b6020026020010151611a9b906154a1565b611abb565b838181518110611ab257611ab2615242565b60200260200101515b828281518110611acd57611acd615242565b602090810291909101015280611ae281615281565b915050611a6a565b5092915050565b6001600160a01b038116600090815260208190526040812054610e2890613144565b6060806060611b20614837565b6001600160a01b0385166000908152600260209081526040808320600390925282209091611b4c835490565b6001600160a01b038916600090815260208190526040902054909150611b7190611dbb565b9350806001600160401b03811115611b8b57611b8b614c05565b604051908082528060200260200182016040528015611bdd57816020015b604080516080810182526000808252602080830182905292820181905260608201528252600019909201910181611ba95790505b509650806001600160401b03811115611bf857611bf8614c05565b604051908082528060200260200182016040528015611c21578160200160208202803683370190505b509550611c2e8482613160565b945060008060005b83811015611d495760008181526001808801602052604090912080549101546001600160a01b0390911690935091506001600160801b038316898281518110611c8157611c81615242565b6020908102919091018101919091526001600160a01b038381166000908152878352604090819020815160808101909252805492831682529092909190830190600160a01b900460ff166002811115611cdc57611cdc614a81565b6002811115611ced57611ced614a81565b8152600191909101546001600160a01b0381166020830152600160a01b900460ff1615156040909101528a518b9083908110611d2b57611d2b615242565b60200260200101819052508080611d4190615281565b915050611c36565b5050505050509193509193565b600080611d6283611634565b509392505050565b6000306001600160a01b03831603611d855750600019610b5c565b506001600160a01b038084166000908152600e602090815260408083208685168452825280832093851683529290522054610b5c565b611dc3614837565b604051806101400160405280611dd884613230565b15158152602001611de884613144565b15158152602001611df88461323b565b15158152602001611e0884613256565b15158152602001611e18846132d4565b15158152602001611e28846132e4565b6001600160401b03168152602001611e3f846133a8565b62ffffff168152602001611e5284613474565b63ffffffff168152602001604051806101000160405280611e728661354d565b15158152602001611e828661355d565b15158152602001611e928661356d565b15158152602001611ea28661357d565b15158152602001611eb28661358d565b15158152602001611ec28661359d565b15158152602001611ed2866135ad565b15158152602001611ee2866135bd565b151581525081526020016040518060400160405280611f00866135cd565b15158152602001611f10866135e8565b15159052905292915050565b611f24613603565b156106f3576040516336a7e2cd60e21b815260040160405180910390fd5b611f4b81611d56565b156116315760405163d971f59760e01b81526001600160a01b0382166004820152602401610720565b611f7c6148ce565b611f8461172e565b6060611f908484613641565b8051919350915060005b8181101561207f57600084602001518281518110611fba57611fba615242565b60200260200101516000015190506000848381518110611fdc57611fdc615242565b60200260200101519050600081111561206c576001600160a01b0382166000908152600a60205260408120805483929061201790849061526e565b92505081905550816001600160a01b0316886001600160a01b03167f0954687c12bae94d7ea785882bbed7766e38d72b5bc620f7c34167edd4f2db758360405161206391815260200190565b60405180910390a35b50508061207890615281565b9050611f9a565b5061208a858461389c565b5050610e286001600c55565b8082146120b65760405163aaad13f760e01b815260040160405180910390fd5b5050565b60606000845190506120cf8185518551613937565b6000816001600160401b038111156120e9576120e9614c05565b604051908082528060200260200182016040528015612112578160200160208202803683370190505b50905060005b828110156121ad5761218086828151811061213557612135615242565b602002602001015186838151811061214f5761214f615242565b602002602001015189848151811061216957612169615242565b60200260200101516139649092919063ffffffff16565b82828151811061219257612192615242565b60209081029190910101526121a681615281565b9050612118565b5095945050505050565b602081015151806001600160401b038111156121d5576121d5614c05565b6040519080825280602002602001820160405280156121fe578160200160208202803683370190505b50608083015260005b818110156113bc5760008360200151828151811061222757612227615242565b60200260200101516020015190506000600281111561224857612248614a81565b81600281111561225a5761225a614a81565b0361228f57670de0b6b3a76400008460800151838151811061227e5761227e615242565b6020026020010181815250506123e7565b60018160028111156122a3576122a3614a81565b0361234157836020015182815181106122be576122be615242565b6020026020010151604001516001600160a01b031663679aefce6040518163ffffffff1660e01b8152600401602060405180830381865afa158015612307573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061232b91906154bd565b8460800151838151811061227e5761227e615242565b600281600281111561235557612355614a81565b036123ce578360200151828151811061237057612370615242565b6020026020010151600001516001600160a01b03166307a2d13a670de0b6b3a76400006040518263ffffffff1660e01b81526004016123b191815260200190565b602060405180830381865afa158015612307573d6000803e3d6000fd5b604051636fa2831960e11b815260040160405180910390fd5b506123f181615281565b9050612207565b600061240261172e565b6001600160a01b0388166000908152600260205260408120905b87602001515181101561257a5760008860200151828151811061244157612441615242565b602002602001015160000151905087828151811061246157612461615242565b60200260200101516001600160a01b0316816001600160a01b0316146124ed578a88838151811061249457612494615242565b60209081029190910101516040517fffe261a10000000000000000000000000000000000000000000000000000000081526001600160a01b03928316600482015290821660248201529082166044820152606401610720565b6125118188848151811061250357612503615242565b60200260200101513361397a565b6125698261255189858151811061252a5761252a615242565b602002602001015189868151811061254457612544615242565b60200260200101516130cf565b60009182526001808701602052604090922090910155565b5061257381615281565b905061241c565b506001600160a01b03808916908a167fbe6ac7a0b82631778289589a1a0ad2e5b4fcfea5f4fbdc3559bf6ea2131d511c886125b6896001611a20565b6040516125c49291906152ad565b60405180910390a38651600160209091015286516125e190613987565b6001600160a01b038a16600081815260208190526040908190209290925590516380de451d60e01b81526380de451d9061261f908790600401614a35565b602060405180830381865afa15801561263c573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061266091906154bd565b915061266b82613114565b612678620f42408361529a565b915061268389614176565b61268e898984614271565b828210156126b957604051638d261d5d60e01b81526004810183905260248101849052604401610720565b6040516001600160a01b038a16907fcad8c9d32507393b6508ca4a888b81979919b477510585bde8488f153072d6f390600090a2506126f86001600c55565b979650505050505050565b6001600160a01b038116600090815260208190526040812054610e2890613256565b6001600160a01b038116600090815260208190526040812054610e2890613230565b6001600160a01b038116600090815260026020526040902060609061276a815490565b6001600160401b0381111561278157612781614c05565b6040519080825280602002602001820160405280156127aa578160200160208202803683370190505b50915060005b825181101561281957600081815260018301602052604090205483516001600160a01b03909116908490839081106127ea576127ea615242565b60200260200101816001600160a01b03166001600160a01b0316815250508061281290615281565b90506127b0565b5050919050565b6001600160a01b0383166128525760405163e602df0560e01b81526001600160a01b0384166004820152602401610720565b6001600160a01b03821661288457604051634a1406b160e11b81526001600160a01b0383166004820152602401610720565b6001600160a01b038481166000818152600e6020908152604080832088861680855290835281842095881680855295835292819020869055518581529192917fa0175360a15bca328baf7ea85c7b784d58b222a50d0ce760b10dba336d226a61910160405180910390a4604051630ad0fe5760e31b81526001600160a01b038481166004830152838116602483015260448201839052851690635687f2b8906064015b600060405180830381600087803b15801561294157600080fd5b505af1158015612955573d6000803e3d6000fd5b5050505050505050565b6060814710156129845760405163cd78605960e01b8152306004820152602401610720565b600080856001600160a01b031684866040516129a091906154d6565b60006040518083038185875af1925050503d80600081146129dd576040519150601f19603f3d011682016040523d82523d6000602084013e6129e2565b606091505b50915091506129f286838361438e565b9695505050505050565b612a0582612725565b15612a2e576040516301b6ee3960e71b81526001600160a01b0383166004820152602401610720565b8051516002811015612a5357604051635ed4ba8f60e01b815260040160405180910390fd5b6004811115612a7557604051630e0f7beb60e31b815260040160405180910390fd5b6001600160a01b038316600090815260026020526040812090826001600160401b03811115612aa657612aa6614c05565b604051908082528060200260200182016040528015612acf578160200160208202803683370190505b5090506000805b84811015612e0f57600086600001518281518110612af657612af6615242565b60200260200101519050600081600001519050836001600160a01b0316816001600160a01b03161015612b3c57604051636e8f194760e01b815260040160405180910390fd5b9250826001600160a01b0381161580612b665750886001600160a01b0316816001600160a01b0316145b15612b845760405163c1ab6dc160e01b815260040160405180910390fd5b612b90868260006143ea565b1515600003612bbd576040516327a5b1a760e11b81526001600160a01b0382166004820152602401610720565b6040808301516001600160a01b038b811660009081526003602090815284822086841683528152939020855181549083166001600160a01b0319821681178355948701519390921615159386939192839174ffffffffffffffffffffffffffffffffffffffffff1990911617600160a01b836002811115612c4057612c40614a81565b02179055506040820151600190910180546060909301511515600160a01b0274ffffffffffffffffffffffffffffffffffffffffff199093166001600160a01b0390921691909117919091179055600083602001516002811115612ca657612ca6614a81565b03612ccf578015612cca57604051636fa2831960e11b815260040160405180910390fd5b612d68565b600183602001516002811115612ce757612ce7614a81565b03612d0f57801515600003612cca57604051636fa2831960e11b815260040160405180910390fd5b600283602001516002811115612d2757612d27614a81565b03612d4f57826060015115612cca57604051636fa2831960e11b815260040160405180910390fd5b60405163a1e9dd9d60e01b815260040160405180910390fd5b816001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015612da6573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612dca91906154f2565b612dd5906012615515565b868581518110612de757612de7615242565b602002602001019060ff16908160ff168152505050505080612e0890615281565b9050612ad6565b506040858101516001600160a01b0388811660009081526001602090815284822080546001600160a01b031916939094169290921790925581905290812054612e5790611dbb565b60018152606087015161010082015260808701516101208201529050612e7c83614499565b62ffffff1660c08201526020860151612e9490614500565b63ffffffff1660e0820152612ea881613987565b6001600160a01b03881660008181526020818152604091829020939093558851928901518982015160608b015160808c0151935133967f446454f4aa9a3f9251e3d036114f917fc005a7e94a64e319d5a67aa30bf54a2895612f0f9591949193919261552e565b60405180910390a350505050505050565b306001600160a01b0382161461163157604051634fe92d9b60e11b815260040160405180910390fd5b600080612f558361323b565b612f5e84613474565b909463ffffffff9091169350915050565b600080612f84670de0b6b3a7640000856155e3565b9050610dc883826155fa565b600080612f9d83856155e3565b9050610dc8670de0b6b3a7640000826155fa565b60007f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821115612ff75760405163123baf0360e11b815260048101839052602401610720565b5090565b8160000361300857505050565b6001600160a01b0381163314613042576040516327c2144960e21b81526001600160a01b0382166004820152336024820152604401610720565b6001600160a01b03808216600090815260066020908152604080832093871683529290529081205490613075848361561c565b90508060000361308e57600580546000190190556130a0565b816000036130a0576005805460010190555b6001600160a01b0392831660009081526006602090815260408083209790951682529590955291909320555050565b60006001600160801b038311806130ec57506001600160801b0382115b1561310a576040516389560ca160e01b815260040160405180910390fd5b610b5c8383614531565b620f424081101561163157604051634ddaf4a960e01b815260048101829052620f42406024820152604401610720565b6000610e28613154826001615644565b839060ff161c60011690565b60606000826001600160401b0381111561317c5761317c614c05565b6040519080825280602002602001820160405280156131a5578160200160208202803683370190505b5060c085015190915062ffffff1660005b848110156132265760006131d76131ce6005846155e3565b84901c601f1690565b90506131e481600a615741565b6131f690670de0b6b3a76400006155e3565b84838151811061320857613208615242565b6020908102919091010152508061321e81615281565b9150506131b6565b5090949350505050565b600060018216610e28565b6000610e2861324b826001615644565b613154906001615644565b6000610e28613266826001615644565b613271906001615644565b61327c906001615644565b613287906001615644565b613292906001615644565b61329d906001615644565b6132a8906001615644565b6132b3906001615644565b6132be906001615644565b6132c9906001615644565b61324b906001615644565b6000610e286132c9826001615644565b6000610e286133a36132f7836001615644565b613302906001615644565b61330d906001615644565b613318906001615644565b613323906001615644565b61332e906001615644565b613339906001615644565b613344906001615644565b61334f906001615644565b61335a906001615644565b613365906001615644565b613370906001615644565b61337b906001615644565b613386906001615644565b613391906001615644565b60ff1684901c6001600160401b031690565b614541565b6000610e2861346f60406133bd846001615644565b6133c8906001615644565b6133d3906001615644565b6133de906001615644565b6133e9906001615644565b6133f4906001615644565b6133ff906001615644565b61340a906001615644565b613415906001615644565b613420906001615644565b61342b906001615644565b613436906001615644565b613441906001615644565b61344c906001615644565b613457906001615644565b6134619190615644565b60ff1684901c62ffffff1690565b614577565b6000610e286135486018604061348b856001615644565b613496906001615644565b6134a1906001615644565b6134ac906001615644565b6134b7906001615644565b6134c2906001615644565b6134cd906001615644565b6134d8906001615644565b6134e3906001615644565b6134ee906001615644565b6134f9906001615644565b613504906001615644565b61350f906001615644565b61351a906001615644565b613525906001615644565b61352f9190615644565b6135399190615644565b60ff1684901c63ffffffff1690565b614500565b6000610e2861327c826001615644565b6000610e28613271826001615644565b6000610e286132be826001615644565b6000610e286132b3826001615644565b6000610e286132a8826001615644565b6000610e2861329d826001615644565b6000610e28613292826001615644565b6000610e28613287826001615644565b6000610e286135dd826001615644565b613266906001615644565b6000610e286135f8826001615644565b6135dd906001615644565b60007f0000000000000000000000000000000000000000000000000000000000000000421115801561081b575050600b54600160a81b900460ff1690565b6136496148ce565b606061365484611b13565b855260a08501526040808501919091526020808501929092526001600160a01b0386166000908152600290925281209061368c825490565b9050806001600160401b038111156136a6576136a6614c05565b6040519080825280602002602001820160405280156136cf578160200160208202803683370190505b509250806001600160401b038111156136ea576136ea614c05565b604051908082528060200260200182016040528015613713578160200160208202803683370190505b506060850152600954613725856121b7565b845160200151600090801561373a5750600082115b80156137495750855160600151155b905060005b838110156138905760008760200151828151811061376e5761376e615242565b6020026020010151602001519050613787888a846145a7565b6000600282600281111561379d5761379d614a81565b14806137e7575060018260028111156137b8576137b8614a81565b1480156137e75750886020015183815181106137d6576137d6615242565b602090810291909101015160600151155b90508380156137f35750805b1561387d576000838152600188810160205260408220015461381b908b9060801c868961465f565b9050801561387b578089858151811061383657613836615242565b602002602001018181525050808a60400151858151811061385957613859615242565b6020026020010181815161386d919061529a565b90525061387b8a8c866145a7565b505b50508061388990615281565b905061374e565b50505050509250929050565b6001600160a01b0382166000908152600260205260409081902060a083015160808401519284015191926138d19291906120ba565b606083015260005b8260400151518110156139315761392181610ac58560400151848151811061390357613903615242565b60200260200101518660600151858151811061254457612544615242565b61392a81615281565b90506138d9565b50505050565b81831415806139465750808214155b156113bc5760405163aaad13f760e01b815260040160405180910390fd5b6000610dc8826139748686612f90565b90612f90565b6113bc8361189584612fb1565b60808101516000908190613aa2906139a0836001615644565b6139ab906001615644565b6139b6906001615644565b60ff16613a958660600151600060016139cf9190615644565b6139da906001615644565b6139e5906001615644565b6139f0906001615644565b6139fb906001615644565b613a06906001615644565b613a11906001615644565b613a1c906001615644565b613a27906001615644565b613a32906001615644565b613a3d906001615644565b613a48906001615644565b60ff16613a95896040015160006001613a619190615644565b613a6c906001615644565b60ff16613a958c6020015160006001613a859190615644565b8e5160ff91909116906001198e16175b6001821b191691901b1790565b9050613b3c8361010001516060015160006001613abf9190615644565b613aca906001615644565b613ad5906001615644565b613ae0906001615644565b613aeb906001615644565b60ff16613a958661010001516040015160006001613b099190615644565b613b14906001615644565b613b1f906001615644565b613b2a906001615644565b60ff1690811b600190911b1986161790565b9050613ce383610100015160e0015160006001613b599190615644565b613b64906001615644565b613b6f906001615644565b613b7a906001615644565b613b85906001615644565b613b90906001615644565b613b9b906001615644565b613ba6906001615644565b613bb1906001615644565b60ff16613a9586610100015160c0015160006001613bcf9190615644565b613bda906001615644565b613be5906001615644565b613bf0906001615644565b613bfb906001615644565b613c06906001615644565b613c11906001615644565b613c1c906001615644565b60ff16613a9589610100015160a0015160006001613c3a9190615644565b613c45906001615644565b613c50906001615644565b613c5b906001615644565b613c66906001615644565b613c71906001615644565b613c7c906001615644565b60ff16613a958c61010001516080015160006001613c9a9190615644565b613ca5906001615644565b613cb0906001615644565b613cbb906001615644565b613cc6906001615644565b613cd1906001615644565b60ff1690811b600190911b198c161790565b9050613f078361012001516020015160006001613d009190615644565b613d0b906001615644565b613d16906001615644565b613d21906001615644565b613d2c906001615644565b613d37906001615644565b613d42906001615644565b613d4d906001615644565b613d58906001615644565b613d63906001615644565b613d6e906001615644565b613d79906001615644565b613d84906001615644565b613d8f906001615644565b60ff16613a958661012001516000015160006001613dad9190615644565b613db8906001615644565b613dc3906001615644565b613dce906001615644565b613dd9906001615644565b613de4906001615644565b613def906001615644565b613dfa906001615644565b613e05906001615644565b613e10906001615644565b613e1b906001615644565b613e26906001615644565b613e31906001615644565b60ff16613a958961010001516020015160006001613e4f9190615644565b613e5a906001615644565b613e65906001615644565b613e70906001615644565b613e7b906001615644565b613e86906001615644565b613e91906001615644565b613e9c906001615644565b613ea7906001615644565b613eb2906001615644565b613ebd906001615644565b60ff16613a958c61010001516000015160006001613edb9190615644565b613ee6906001615644565b613ef1906001615644565b613efc906001615644565b613c9a906001615644565b9050610b5c8360e0015163ffffffff166018604060006001613f299190615644565b613f34906001615644565b613f3f906001615644565b613f4a906001615644565b613f55906001615644565b613f60906001615644565b613f6b906001615644565b613f76906001615644565b613f81906001615644565b613f8c906001615644565b613f97906001615644565b613fa2906001615644565b613fad906001615644565b613fb8906001615644565b613fc3906001615644565b613fcd9190615644565b613fd79190615644565b60ff16602060ff1661416e8760a001516001600160401b031660006001613ffe9190615644565b614009906001615644565b614014906001615644565b61401f906001615644565b61402a906001615644565b614035906001615644565b614040906001615644565b61404b906001615644565b614056906001615644565b614061906001615644565b61406c906001615644565b614077906001615644565b614082906001615644565b61408d906001615644565b614098906001615644565b60ff16604060ff1661416e8b60c0015162ffffff166040600060016140bd9190615644565b6140c8906001615644565b6140d3906001615644565b6140de906001615644565b6140e9906001615644565b6140f4906001615644565b6140ff906001615644565b61410a906001615644565b614115906001615644565b614120906001615644565b61412b906001615644565b614136906001615644565b614141906001615644565b61414c906001615644565b614157906001615644565b6141619190615644565b8b919060ff1660186146f7565b9291906146f7565b6001600160a01b0381166000908152600f602052604081208054620f424092906141a190849061526e565b90915550506001600160a01b0381166000818152600d6020908152604080832083805282528083208054620f424090810190915590519081529192839290917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b81526000600482018190526024820152620f424060448201526001600160a01b038216906323de665190606401600060405180830381600087803b15801561425d57600080fd5b505af1158015611453573d6000803e3d6000fd5b6001600160a01b0382166142a35760405163ec442f0560e01b81526001600160a01b0383166004820152602401610720565b6001600160a01b0383166000908152600f60205260408120546142c790839061526e565b6001600160a01b038086166000908152600d6020908152604080832093881683529290522080548401905590506142fd81613114565b6001600160a01b038481166000818152600f6020908152604080832086905551868152938716939192917fd1398bee19313d6bf672ccb116e51f4a1a947e91c757907f51fbb5b5e56c698f910160405180910390a46040516323de665160e01b8152600060048201526001600160a01b038481166024830152604482018490528516906323de665190606401612927565b6060826143a35761439e8261471a565b610b5c565b81511580156143ba57506001600160a01b0384163b155b156143e357604051639996b31560e01b81526001600160a01b0385166004820152602401610720565b5080610b5c565b6001600160a01b038216600090815260028401602052604081205480820361447957505082546040805180820182526001600160a01b03858116808352602080840187815260008781526001808c018452878220965187546001600160a01b03191696169590951786559051948401949094559482018089559083526002880190945291902091909155610b5c565b600019016000908152600180860160205260408220018390559050610b5c565b60008060005b83518110156144f6576144e28482815181106144bd576144bd615242565b602002602001015160ff16600560ff16836144d891906155e3565b84919060056146f7565b9150806144ee81615281565b91505061449f565b50610b5c81614577565b600063ffffffff821115612ff7576040516306dfcc6560e41b81526020600482015260248101839052604401610720565b6000610b5c83608084901b61526e565b60006001600160401b03821115612ff757604080516306dfcc6560e41b8152600481019190915260248101839052604401610720565b600062ffffff821115612ff7576040516306dfcc6560e41b81526018600482015260248101839052604401610720565b61490a60008360018111156145be576145be614a81565b146145cb576139646145cf565b6147435b9050614637846040015183815181106145ea576145ea615242565b60200260200101518560a00151848151811061460857614608615242565b60200260200101518660800151858151811061462657614626615242565b60200260200101518463ffffffff16565b8460600151838151811061464d5761464d615242565b60200260200101818152505050505050565b6000808560600151848151811061467857614678615242565b60200260200101519050848111156146ee57600085820390506146ea8760a0015186815181106146aa576146aa615242565b6020026020010151886080015187815181106146c8576146c8615242565b60200260200101516146e38785612f9090919063ffffffff16565b9190614759565b9250505b50949350505050565b600061470484848461476e565b506001901b60001901811b1992909216911b1790565b80511561472a5780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b6000610dc88261475386866147f4565b906147f4565b6000610dc88461476985856147f4565b612f6f565b610100821061479057604051632d0483c560e21b815260040160405180910390fd5b600181101580156147b657506147b260ff6147ad8461010061529a565b614821565b8111155b6147d357604051632d0483c560e21b815260040160405180910390fd5b82811c156113bc5760405163e4337c0560e01b815260040160405180910390fd5b60008061480183856155e3565b90506001670de0b6b3a76400006001830304018115150291505092915050565b60008183106148305781610b5c565b5090919050565b6040805161014081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e080880187905288516101008082018b52888252818801899052818b01899052958101889052938401879052918301869052820185905281018490529084015283518085019094528184528301529061012082015290565b6040518060c001604052806148e1614837565b815260200160608152602001606081526020016060815260200160608152602001606081525090565b6106f361574d565b60006020828403121561492457600080fd5b5035919050565b6001600160a01b038116811461163157600080fd5b80356107548161492b565b6000806000806080858703121561496157600080fd5b843561496c8161492b565b9350602085013561497c8161492b565b9250604085013561498c8161492b565b9396929550929360600135925050565b6000602082840312156149ae57600080fd5b8135610b5c8161492b565b6000806000606084860312156149ce57600080fd5b83356149d98161492b565b925060208401356149e98161492b565b929592945050506040919091013590565b600081518084526020808501945080840160005b83811015614a2a57815187529582019590820190600101614a0e565b509495945050505050565b602081526000610b5c60208301846149fa565b600081518084526020808501945080840160005b83811015614a2a5781516001600160a01b031687529582019590820190600101614a5c565b634e487b7160e01b600052602160045260246000fd5b60038110614ab557634e487b7160e01b600052602160045260246000fd5b9052565b60a081526000614acc60a0830188614a48565b82810360208481019190915287518083528882019282019060005b81811015614b0a57614afa838651614a97565b9383019391830191600101614ae7565b50508481036040860152614b1e81896149fa565b9250508382036060850152614b3382876149fa565b8481036080860152855180825282870193509082019060005b81811015614b715784516001600160a01b031683529383019391830191600101614b4c565b50909a9950505050505050505050565b600080600060608486031215614b9657600080fd5b8335614ba18161492b565b92506020840135614bb18161492b565b91506040840135614bc18161492b565b809150509250925092565b60008060408385031215614bdf57600080fd5b8235614bea8161492b565b91506020830135614bfa8161492b565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b604051608081016001600160401b0381118282101715614c3d57614c3d614c05565b60405290565b604051601f8201601f191681016001600160401b0381118282101715614c6b57614c6b614c05565b604052919050565b60006001600160401b03821115614c8c57614c8c614c05565b5060051b60200190565b600082601f830112614ca757600080fd5b81356020614cbc614cb783614c73565b614c43565b82815260059290921b84018101918181019086841115614cdb57600080fd5b8286015b84811015614cf65780358352918301918301614cdf565b509695505050505050565b600082601f830112614d1257600080fd5b81356001600160401b03811115614d2b57614d2b614c05565b614d3e601f8201601f1916602001614c43565b818152846020838601011115614d5357600080fd5b816020850160208301376000918101602001919091529392505050565b60008060008060008060c08789031215614d8957600080fd5b8635614d948161492b565b9550602087810135614da58161492b565b955060408801356001600160401b0380821115614dc157600080fd5b818a0191508a601f830112614dd557600080fd5b8135614de3614cb782614c73565b81815260059190911b8301840190848101908d831115614e0257600080fd5b938501935b82851015614e29578435614e1a8161492b565b82529385019390850190614e07565b9850505060608a0135925080831115614e4157600080fd5b614e4d8b848c01614c96565b955060808a0135945060a08a0135925080831115614e6a57600080fd5b5050614e7889828a01614d01565b9150509295509295509295565b602081526000610b5c6020830184614a48565b60008060208385031215614eab57600080fd5b82356001600160401b0380821115614ec257600080fd5b818501915085601f830112614ed657600080fd5b813581811115614ee557600080fd5b866020828501011115614ef757600080fd5b60209290920196919550909350505050565b60005b83811015614f24578181015183820152602001614f0c565b50506000910152565b60008151808452614f45816020860160208601614f09565b601f01601f19169290920160200192915050565b602081526000610b5c6020830184614f2d565b80511515825260208101511515602083015260408101511515604083015260608101511515606083015260808101511515608083015260a0810151614fb560a084018215159052565b5060c0810151614fc960c084018215159052565b5060e08101516113bc60e084018215159052565b81511515815261024081016020830151614ffb602084018215159052565b50604083015161500f604084018215159052565b506060830151615023606084018215159052565b506080830151615037608084018215159052565b5060a083015161505260a08401826001600160401b03169052565b5060c083015161506960c084018262ffffff169052565b5060e083015161508160e084018263ffffffff169052565b506101008084015161509582850182614f6c565b50506101208301518051151561020084015260208101511515610220840152611aea565b801515811461163157600080fd5b8035610754816150b9565b600061010082840312156150e557600080fd5b50919050565b6000604082840312156150e557600080fd5b6000806000806000806101c0878903121561511757600080fd5b86356151228161492b565b95506020878101356001600160401b0381111561513e57600080fd5b8801601f81018a1361514f57600080fd5b803561515d614cb782614c73565b81815260079190911b8201830190838101908c83111561517c57600080fd5b928401925b828410156151fd576080848e03121561519a5760008081fd5b6151a2614c1b565b84356151ad8161492b565b815284860135600381106151c15760008081fd5b818701526040858101356151d48161492b565b908201526060858101356151e7816150b9565b9082015282526080939093019290840190615181565b985050505060408801359450615217905060608801614940565b925061522688608089016150d2565b91506152368861018089016150eb565b90509295509295509295565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b80820180821115610e2857610e28615258565b60006001820161529357615293615258565b5060010190565b81810381811115610e2857610e28615258565b6040815260006152c06040830185614a48565b82810360208481019190915284518083528582019282019060005b818110156152f7578451835293830193918301916001016152db565b5090979650505050505050565b60408152600061531760408301856149fa565b82810360208401526153298185614f2d565b95945050505050565b60006020828403121561534457600080fd5b8151610b5c816150b9565b60608152600061536260608301866149fa565b84602084015282810360408401526129f28185614f2d565b600061010080838503121561538e57600080fd5b604051908101906001600160401b03821181831017156153b0576153b0614c05565b81604052833591506153c1826150b9565b8181526153d0602085016150c7565b60208201526153e1604085016150c7565b60408201526153f2606085016150c7565b6060820152615403608085016150c7565b608082015261541460a085016150c7565b60a082015261542560c085016150c7565b60c082015261543660e085016150c7565b60e0820152949350505050565b60006040828403121561545557600080fd5b604051604081018181106001600160401b038211171561547757615477614c05565b6040528235615485816150b9565b81526020830135615495816150b9565b60208201529392505050565b6000600160ff1b82016154b6576154b6615258565b5060000390565b6000602082840312156154cf57600080fd5b5051919050565b600082516154e8818460208701614f09565b9190910192915050565b60006020828403121561550457600080fd5b815160ff81168114610b5c57600080fd5b60ff8281168282160390811115610e2857610e28615258565b6101a080825286519082018190526000906101c0830190602090818a01845b828110156155a15781516001600160a01b038082511687528582015161557587890182614a97565b50604082810151909116908701526060908101511515908601526080909401939083019060010161554d565b50505083018790526001600160a01b038616604084015290506155c76060830185614f6c565b82511515610160830152602083015115156101808301526129f2565b8082028115828204841417610e2857610e28615258565b60008261561757634e487b7160e01b600052601260045260246000fd5b500490565b808201828112600083128015821682158216171561563c5761563c615258565b505092915050565b60ff8181168382160190811115610e2857610e28615258565b600181815b8085111561569857816000190482111561567e5761567e615258565b8085161561568b57918102915b93841c9390800290615662565b509250929050565b6000826156af57506001610e28565b816156bc57506000610e28565b81600181146156d257600281146156dc576156f8565b6001915050610e28565b60ff8411156156ed576156ed615258565b50506001821b610e28565b5060208310610133831016604e8410600b841016171561571b575081810a610e28565b615725838361565d565b806000190482111561573957615739615258565b029392505050565b6000610b5c83836156a0565b634e487b7160e01b600052605160045260246000fdfea2646970667358221220207ac99485f2742c90b0feab377819c1fd00f4a91b80038649a81c629135477064736f6c63430008150033",
  linkReferences: {},
  deployedLinkReferences: {},
};
