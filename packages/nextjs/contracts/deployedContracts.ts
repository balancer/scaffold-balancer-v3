/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const deployedContracts = {
  31337: {
    ConstantSumFactory: {
      address: "0x69221a99e5Bc30E0cf891992e958E3Ba3815bfc6",
      abi: [
        {
          type: "constructor",
          inputs: [
            {
              name: "vault",
              type: "address",
              internalType: "contract IVault",
            },
            {
              name: "pauseWindowDuration",
              type: "uint32",
              internalType: "uint32",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "create",
          inputs: [
            {
              name: "name",
              type: "string",
              internalType: "string",
            },
            {
              name: "symbol",
              type: "string",
              internalType: "string",
            },
            {
              name: "salt",
              type: "bytes32",
              internalType: "bytes32",
            },
            {
              name: "tokens",
              type: "tuple[]",
              internalType: "struct TokenConfig[]",
              components: [
                {
                  name: "token",
                  type: "address",
                  internalType: "contract IERC20",
                },
                {
                  name: "tokenType",
                  type: "uint8",
                  internalType: "enum TokenType",
                },
                {
                  name: "rateProvider",
                  type: "address",
                  internalType: "contract IRateProvider",
                },
                {
                  name: "paysYieldFees",
                  type: "bool",
                  internalType: "bool",
                },
              ],
            },
            {
              name: "swapFeePercentage",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "protocolFeeExempt",
              type: "bool",
              internalType: "bool",
            },
            {
              name: "roleAccounts",
              type: "tuple",
              internalType: "struct PoolRoleAccounts",
              components: [
                {
                  name: "pauseManager",
                  type: "address",
                  internalType: "address",
                },
                {
                  name: "swapFeeManager",
                  type: "address",
                  internalType: "address",
                },
                {
                  name: "poolCreator",
                  type: "address",
                  internalType: "address",
                },
              ],
            },
            {
              name: "poolHooksContract",
              type: "address",
              internalType: "address",
            },
            {
              name: "liquidityManagement",
              type: "tuple",
              internalType: "struct LiquidityManagement",
              components: [
                {
                  name: "disableUnbalancedLiquidity",
                  type: "bool",
                  internalType: "bool",
                },
                {
                  name: "enableAddLiquidityCustom",
                  type: "bool",
                  internalType: "bool",
                },
                {
                  name: "enableRemoveLiquidityCustom",
                  type: "bool",
                  internalType: "bool",
                },
              ],
            },
          ],
          outputs: [
            {
              name: "pool",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "disable",
          inputs: [],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "getActionId",
          inputs: [
            {
              name: "selector",
              type: "bytes4",
              internalType: "bytes4",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bytes32",
              internalType: "bytes32",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getAuthorizer",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "contract IAuthorizer",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getDefaultLiquidityManagement",
          inputs: [],
          outputs: [
            {
              name: "liquidityManagement",
              type: "tuple",
              internalType: "struct LiquidityManagement",
              components: [
                {
                  name: "disableUnbalancedLiquidity",
                  type: "bool",
                  internalType: "bool",
                },
                {
                  name: "enableAddLiquidityCustom",
                  type: "bool",
                  internalType: "bool",
                },
                {
                  name: "enableRemoveLiquidityCustom",
                  type: "bool",
                  internalType: "bool",
                },
              ],
            },
          ],
          stateMutability: "pure",
        },
        {
          type: "function",
          name: "getDefaultPoolHooksContract",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "pure",
        },
        {
          type: "function",
          name: "getDeploymentAddress",
          inputs: [
            {
              name: "salt",
              type: "bytes32",
              internalType: "bytes32",
            },
          ],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getNewPoolPauseWindowEndTime",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint32",
              internalType: "uint32",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getOriginalPauseWindowEndTime",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint32",
              internalType: "uint32",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getPauseWindowDuration",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint32",
              internalType: "uint32",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getVault",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "contract IVault",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "isDisabled",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "isPoolFromFactory",
          inputs: [
            {
              name: "pool",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "event",
          name: "FactoryDisabled",
          inputs: [],
          anonymous: false,
        },
        {
          type: "event",
          name: "PoolCreated",
          inputs: [
            {
              name: "pool",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "error",
          name: "Disabled",
          inputs: [],
        },
        {
          type: "error",
          name: "PoolPauseWindowDurationOverflow",
          inputs: [],
        },
        {
          type: "error",
          name: "SenderNotAllowed",
          inputs: [],
        },
        {
          type: "error",
          name: "StandardPoolWithCreator",
          inputs: [],
        },
      ],
      inheritedFunctions: {
        disable: "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getActionId: "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getAuthorizer:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getDefaultLiquidityManagement:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getDefaultPoolHooksContract:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getDeploymentAddress:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getNewPoolPauseWindowEndTime:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getOriginalPauseWindowEndTime:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getPauseWindowDuration:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        getVault: "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        isDisabled: "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
        isPoolFromFactory:
          "../../node_modules/@balancer-labs/v3-monorepo/pkg/vault/contracts/factories/BasePoolFactory.sol",
      },
    },
  },
} as const;

export default deployedContracts satisfies GenericContractsDeclaration;
