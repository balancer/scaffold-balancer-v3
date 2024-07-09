//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

import { PoolHelpers } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { ConstantSumFactory } from "../contracts/pools/ConstantSumFactory.sol";

/**
 * @title Deploy Constant Sum
 * @notice Deploys, registers, and initializes a Constant Sum Pool
 * @dev Set the registration & initialization configurations in the internal getter functions below
 * @dev This script runs as part of `yarn deploy`, but can also be run discretely with `yarn deploy:sum`
 */
contract DeployConstantSumPool is PoolHelpers, ScaffoldHelpers {
    function run() external virtual {
        uint256 deployerPrivateKey = getDeployerPrivateKey();

        // Grab the latest deployment addresses for the mock tokens and constant sum factory
        address token1 = DevOpsTools.get_most_recent_deployment(
            "MockToken1", // Must match the mock token contract name
            block.chainid
        );
        address token2 = DevOpsTools.get_most_recent_deployment(
            "MockToken2", // Must match the mock token contract name
            block.chainid
        );
        address factory = DevOpsTools.get_most_recent_deployment(
            "ConstantSumFactory", // Must match the factory contract name
            block.chainid
        );
        // Grab arguments for pool deployment and initialization outside of broadcast to save gas
        RegistrationConfig memory regConfig = getPoolConfig(token1, token2);
        InitializationConfig memory initConfig = getInitializationConfig(token1, token2);

        vm.startBroadcast(deployerPrivateKey);
        // Deploy a pool and register it with the vault
        address pool = ConstantSumFactory(factory).create(
            regConfig.name,
            regConfig.symbol,
            regConfig.salt,
            regConfig.tokenConfig,
            regConfig.swapFeePercentage,
            regConfig.protocolFeeExempt,
            regConfig.roleAccounts,
            regConfig.poolHooksContract,
            regConfig.liquidityManagement
        );
        console.log("Constant Sum Pool deployed at: %s", pool);

        // Seed the pool with initial liquidity
        initializePool(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Constant Sum Pool initialized successfully!");
        vm.stopBroadcast();
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getPoolConfig(address token1, address token2) internal view returns (RegistrationConfig memory regConfig) {
        string memory name = "Constant Sum Pool #1"; // name for the pool
        string memory symbol = "CS-50scUSD-50scDAI"; // symbol for the BPT
        bytes32 salt = keccak256(abi.encode(block.number)); // salt for the pool deployment via factory
        uint256 swapFeePercentage = 1e12; // 0.00001%
        bool protocolFeeExempt = false;
        address poolHooksContract = address(0); // zero address if no hooks contract is needed

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
        tokenConfig[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(token1),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        tokenConfig[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(token2),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });

        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: address(0), // Account empowered to pause/unpause the pool (or 0 to delegate to governance)
            swapFeeManager: address(0), // Account empowered to set static swap fees for a pool (or 0 to delegate to goverance)
            poolCreator: address(0) // Account empowered to set the pool creator fee percentage
        });
        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false
        });

        regConfig = RegistrationConfig({
            name: name,
            symbol: symbol,
            salt: salt,
            tokenConfig: sortTokenConfig(tokenConfig),
            swapFeePercentage: swapFeePercentage,
            protocolFeeExempt: protocolFeeExempt,
            roleAccounts: roleAccounts,
            poolHooksContract: poolHooksContract,
            liquidityManagement: liquidityManagement
        });
    }

    /**
     * @dev Set the pool initialization configurations here
     * @notice this is where the amounts of tokens to be initially added to the pool are set
     */
    function getInitializationConfig(
        address token1,
        address token2
    ) internal pure returns (InitializationConfig memory poolInitConfig) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 10 ether; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 10 ether; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        poolInitConfig = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }
}
