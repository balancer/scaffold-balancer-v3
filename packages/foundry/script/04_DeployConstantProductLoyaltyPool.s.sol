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

import { PoolHelpers, CustomPoolConfig, InitializationConfig } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { ConstantProductFactory } from "../contracts/factories/ConstantProductFactory.sol";
import { LoyaltyHook } from "../contracts/hooks/LoyaltyHook.sol";
import { LoyaltyToken } from "../contracts/mocks/LoyaltyToken.sol";
import { LoyaltyRewardStrategy } from "../contracts/hooks/strategies/LoyaltyRewardStrategy.sol";

/**
 * @title Deploy Constant Product Pool
 * @notice Deploys, registers, and initializes a constant product pool that uses a Loyalty Hook
 */
contract DeployConstantProductLoyaltyPool is PoolHelpers, ScaffoldHelpers {
    function deployConstantProductLoyaltyPool(address token1, address token2, address loyaltyToken) internal {
        // Set the deployment configurations
        CustomPoolConfig memory poolConfig = getLoyaltyProductPoolConfig(token1, token2);
        InitializationConfig memory initConfig = getLoyaltyProductPoolInitConfig(token1, token2);

        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a factory
        ConstantProductFactory factory = new ConstantProductFactory(vault, 365 days); //pauseWindowDuration
        console.log("Constant Product Factory deployed at: %s", address(factory));

        // Deploy a hook
        address loyaltyHook = address(
            new LoyaltyHook(vault, address(router), address(loyaltyToken), address(createLoyaltyRewardStrategy()))
        );
        console.log("LoyaltyHook deployed at address: %s", loyaltyHook);

        LoyaltyToken(loyaltyToken).grantMinterRole(address(loyaltyHook));

        // Deploy a pool and register it with the vault
        address pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            loyaltyHook, // poolHooksContract
            poolConfig.liquidityManagement
        );
        console.log("Constant Product Pool with Loyalty Hook deployed at: %s", pool);

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
        console.log("Constant Product Pool with Loyalty Hook initialized successfully!");
        vm.stopBroadcast();
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getLoyaltyProductPoolConfig(
        address token1,
        address token2
    ) internal view returns (CustomPoolConfig memory config) {
        string memory name = "Constant Product Pool with Loyalty Hook"; // name for the pool
        string memory symbol = "CPPL"; // symbol for the BPT
        bytes32 salt = keccak256(abi.encode(block.number)); // salt for the pool deployment via factory
        uint256 swapFeePercentage = 0.02e18; // 2%
        bool protocolFeeExempt = false;
        address poolHooksContract = address(0); // zero address if no hooks contract is needed

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage
        tokenConfigs[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: IERC20(token1),
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        tokenConfigs[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
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
            disableUnbalancedLiquidity: true,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true
        });

        config = CustomPoolConfig({
            name: name,
            symbol: symbol,
            salt: salt,
            tokenConfigs: sortTokenConfig(tokenConfigs),
            swapFeePercentage: swapFeePercentage,
            protocolFeeExempt: protocolFeeExempt,
            roleAccounts: roleAccounts,
            poolHooksContract: poolHooksContract,
            liquidityManagement: liquidityManagement
        });
    }

    /**
     * @dev Set the pool initialization configurations here
     * @notice This is where the amounts of tokens to Seed the pool with initial liquidity using Router as entrypoint are set
     */
    function getLoyaltyProductPoolInitConfig(
        address token1,
        address token2
    ) internal pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 50e18; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 50e18; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 49e18; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        config = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }

    /**
     * @notice Deploys the LoyaltyRewardStrategy with defined parameters.
     * @return LoyaltyRewardStrategy The deployed LoyaltyRewardStrategy contract instance.
     */
    function createLoyaltyRewardStrategy() internal returns (LoyaltyRewardStrategy) {
        // Define thresholds for loyalty tiers
        uint256[] memory thresholds = new uint256[](3);
        thresholds[0] = 100 * 1e18; // TIER1_THRESHOLD: 100 tokens
        thresholds[1] = 500 * 1e18; // TIER2_THRESHOLD: 500 tokens
        thresholds[2] = 1000 * 1e18; // TIER3_THRESHOLD: 1000 tokens

        // Define discount percentages for each tier
        uint256[] memory discounts = new uint256[](3);
        discounts[0] = 50 * 1e16; // TIER1_DISCOUNT: 50% discount
        discounts[1] = 80 * 1e16; // TIER2_DISCOUNT: 80% discount
        discounts[2] = 90 * 1e16; // TIER3_DISCOUNT: 90% discount

        // Define decay parameters
        uint256 decayPerAction = 10 * 1e16; // DECAY_PER_ACTION: 10% decay
        uint256 maxDecay = 90 * 1e16; // MAX_DECAY: 90% max decay

        // Deploy LoyaltyRewardStrategy contract
        LoyaltyRewardStrategy loyaltyRewardStrategy = new LoyaltyRewardStrategy(
            thresholds,
            discounts,
            decayPerAction,
            maxDecay
        );

        console.log("LoyaltyRewardStrategy deployed at: %s", address(loyaltyRewardStrategy));

        return loyaltyRewardStrategy;
    }
}
