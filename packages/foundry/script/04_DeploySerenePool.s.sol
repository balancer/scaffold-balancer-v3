//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import { PoolHelpers, InitializationConfig } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { WeightedPoolFactory } from "@balancer-labs/v3-pool-weighted/contracts/WeightedPoolFactory.sol";
import { ExitFeeHookExample } from "../contracts/hooks/ExitFeeHookExample.sol";

import { GaugeRegistry } from "../contracts/mocks/GaugeRegistry.sol";
import { MockQuestBoard } from "../contracts/mocks/MockQuestBoard.sol";
import { QuestSettingsRegistry } from "../contracts/hooks/utils/QuestSettingsRegistry.sol";
import { SereneHook } from "../contracts/hooks/SereneHook.sol";
import { IQuestBoard } from "../contracts/hooks/interfaces/IQuestBoard.sol";

import { DeployWeightedPool8020 } from "./03_DeployWeightedPool8020.s.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";

/**
 * @title Deploy Weighted Pool 80/20
 * @notice Deploys, registers, and initializes a 80/20 weighted pool that uses an Exit Fee Hook
 */
contract DeploySerenePool is DeployWeightedPool8020 {
    struct SereneHookConstructorParams {
        IVault vault;
        IPermit2 permit2;
        address factory;
        address gaugeRegistry;
        address batchRouter;
        address questBoard;
        address questSettings;
        address token1;
        uint64 fee;
    }

    function deploySerenePool(address token1, address token2) internal {
        // Set the pool initialization config
        InitializationConfig memory initConfig = getWeightedPoolInitConfig(token1, token2);

        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a  factory
        WeightedPoolFactory factory = new WeightedPoolFactory(vault, 365 days, "Factory v1", "Pool v1");
        console.log("Weighted Pool Factory deployed at: %s", address(factory));

        // Deploy a hook
        GaugeRegistry gaugeRegistry = new GaugeRegistry();
        QuestSettingsRegistry questSettings = new QuestSettingsRegistry(deployer);
        MockQuestBoard questBoard = new MockQuestBoard(400, 0);
        questSettings.setQuestSettings(
            address(token1),
            1,
            1000,
            2000,
            IQuestBoard.QuestVoteType.NORMAL,
            IQuestBoard.QuestCloseType.NORMAL,
            new address[](0)
        );

        address sereneHook = _deploySereneHook(
            SereneHookConstructorParams(
                vault,
                permit2,
                address(factory),
                address(gaugeRegistry),
                address(batchRouter),
                address(questBoard),
                address(questSettings),
                address(token1),
                5e17 // 50% of fee
            )
        );
        console.log("SereneHook deployed at address: %s", sereneHook);

        // Deploy a pool and register it with the vault
        /// @notice passing args directly to avoid stack too deep error
        address pool = factory.create(
            "80/20 Weighted Pool", // string name
            "80-20-WP", // string symbol
            getTokenConfigs(token1, token2), // TokenConfig[] tokenConfigs
            getNormailzedWeights(), // uint256[] normalizedWeights
            getRoleAccounts(), // PoolRoleAccounts roleAccounts
            0.001e18, // uint256 swapFeePercentage (.01%)
            sereneHook, // address poolHooksContract
            true, //bool enableDonation
            true, // bool disableUnbalancedLiquidity (must be true for the ExitFee Hook)
            keccak256(abi.encode(block.number)) // bytes32 salt
        );
        console.log("Weighted Pool deployed at: %s", pool);

        // Add a fake gauge to the Gauge Registry
        gaugeRegistry.register(address(pool), makeAddr("gauge"));

        // Approve the router to spend tokens for pool initialization
        approveRouterWithPermit2(initConfig.tokens);

        // Seed the pool with initial liquidity using Router as entrypoint
        router.initialize(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Weighted Pool initialized successfully!");
        vm.stopBroadcast();
    }

    function _deploySereneHook(SereneHookConstructorParams memory params) internal returns (address) {
        return address(
            new SereneHook(
                params.vault,
                params.permit2,
                params.factory,
                params.gaugeRegistry,
                params.batchRouter,
                params.questBoard,
                params.questSettings,
                params.token1,
                params.fee
            )
        );
    }
}
