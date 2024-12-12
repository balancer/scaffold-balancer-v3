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
// import { LotteryHookExample } from "../contracts/hooks/LotteryHookExample.sol";
import { VolatilityFeeHookV1 } from "../contracts/hooks/volatilityFee/VolatilityFeeHookV1.sol";
import { VolatilityFeeHookV2 } from "../contracts/hooks/volatilityFee/VolatilityFeeHookV2.sol";

/**
 * @title Deploy Constant Product Pool
 * @notice Deploys, registers, and initializes a constant product pool that uses a Lottery Hook
 */
contract DeployCPPWithVolatilityFeeHook is PoolHelpers, ScaffoldHelpers {
    uint256 private nonce = 0;
    function deployCPPWithVolatilityFeeHook(address token1, address token2) internal {
        // Set the deployment configurations
        CustomPoolConfig memory poolConfigV1 = getCPPConfig(token1, token2, "CPP With Hook V1", "CPPV1", keccak256(abi.encode(block.timestamp)));
        CustomPoolConfig memory poolConfigV2 = getCPPConfig(token1, token2, "CPP With Hook V2", "CPPV2", keccak256(abi.encode(block.number)));
        InitializationConfig memory initConfig = getCPPInitConfig(token1, token2);

        // Start creating the transactions
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a factory
        ConstantProductFactory factory = new ConstantProductFactory(vault, 365 days); //pauseWindowDuration
        console.log("Constant Product Factory deployed at: %s", address(factory));

        // Deploy a V1 Hook
        address volatilityFeeHookV1 = address(new VolatilityFeeHookV1(vault, address(factory), address(router)));
        console.log("Volatility Fee Hook V1 deployed at: %s", address(volatilityFeeHookV1));

        // V1Hook Enabled Pool Address
        address volatilityFeeHookV1Pool = deployPoolWithHook(factory, poolConfigV1, initConfig,  volatilityFeeHookV1);
        console.log("CPP With VolatilityFeeHookV1 deployed at: %s", volatilityFeeHookV1Pool);

        vm.warp(block.timestamp + 15);
        // Deploy a V2 Hook
        address volatilityFeeHookV2 = address(new VolatilityFeeHookV2(vault, address(factory), address(router)));
        console.log("Volatility Fee Hook V2 deployed at: %s", address(volatilityFeeHookV2));

        // V2Hook Enabled Pool Address
        address volatilityFeeHookV2Pool = deployPoolWithHook(factory, poolConfigV2, initConfig,  volatilityFeeHookV2);
        console.log("CPP With VolatilityFeeHookV2 deployed at: %s", volatilityFeeHookV2Pool);

        vm.stopBroadcast();
    }

    // Function to deploy Pool with Hook
    // @Returns Pool Address
    function deployPoolWithHook(
        ConstantProductFactory factory,
        CustomPoolConfig memory poolConfig, 
        InitializationConfig memory initConfig,
        address hook
    ) internal returns(address){
        // Deploy a pool and register it with the vault
        address pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            hook, // poolHooksContract
            poolConfig.liquidityManagement
        );
        console.log("Pool Deployed successfully!");

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
        console.log("Pool initialized successfully!");

        //Return Pool Address
        return pool;
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getCPPConfig(
        address token1,
        address token2,
        string memory name,
        string memory symbol,
        bytes32 salt
    ) internal returns (CustomPoolConfig memory config) {
        // string memory name = "Constant Product Pool"; // name for the pool
        // string memory symbol = "CPP"; // symbol for the BPT
        // bytes32 salt = keccak256(abi.encode(block.timestamp));// salt for the pool deployment via factory
        // nonce++ ;
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
            disableUnbalancedLiquidity: true, // Must be true to register pool with the Lottery Hook
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: false
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
    function getCPPInitConfig(
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
}
