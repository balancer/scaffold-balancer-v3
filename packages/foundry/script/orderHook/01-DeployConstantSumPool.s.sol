//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TokenConfig, TokenType, LiquidityManagement, PoolRoleAccounts} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {IVault} from "@balancer-labs/contracts/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";

import {Router} from "@balancer-labs/contracts/vault/contracts/Router.sol";

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ConstantSumFactory} from "../src/factories/ConstantSumFactory.sol";
import {OrderHook} from "../src/OrderHook.sol";

import {Script, console} from "forge-std/Script.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {PoolHelpers, CustomPoolConfig, InitializationConfig} from "./PoolHelpers.sol";

/**
 * @title Deploy Constant Sum Pool
 * @notice Deploys, registers, and initializes a constant sum pool that uses a swap fee discount hook
 */
contract DeployConstantSumPool is Script, PoolHelpers {
    function deployConstantSumPool(
        address token1,
        address token2
    ) public returns (address orderHook, address pool) {
        HelperConfig helperConfig = new HelperConfig();
        // Set the pool's deployment, registration, and initialization config
        CustomPoolConfig memory poolConfig = getSumPoolConfig(token1, token2);
        InitializationConfig memory initConfig = getSumPoolInitConfig(
            token1,
            token2
        );

        // Start creating the transactions
        address deployer = helperConfig.getConfig().account;
        vm.startBroadcast(deployer);

        // Deploy a factory
        ConstantSumFactory factory = new ConstantSumFactory(
            IVault(helperConfig.getConfig().vault),
            0 days
        ); // pauseWindowDuration
        console.log("Constant Sum Factory deployed at: %s", address(factory));

        // Deploy a hook
        orderHook = address(
            new OrderHook(
                IVault(helperConfig.getConfig().vault),
                address(factory),
                helperConfig.getConfig().router,
                IPermit2(helperConfig.getConfig().permit2)
            )
        );
        console.log("OrderHook deployed at address: %s", orderHook);

        // Deploy a pool and register it with the vault
        pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            orderHook, // poolHooksContract
            poolConfig.liquidityManagement
        );
        console.log("Constant Sum Pool deployed at: %s", pool);

        // Approve the router to spend tokens for pool initialization
        approveRouterWithPermit2(initConfig.tokens);

        // Seed the pool with initial liquidity
        router.initialize(
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
    function getSumPoolConfig(
        address token1,
        address token2
    ) internal view returns (CustomPoolConfig memory config) {
        string memory name = "Constant Sum Pool"; // name for the pool
        string memory symbol = "CSP"; // symbol for the BPT
        bytes32 salt = keccak256(abi.encode(block.number)); // salt for the pool deployment via factory
        uint256 swapFeePercentage = 0.01e18; // 1%
        bool protocolFeeExempt = true;
        address poolHooksContract = address(0); // zero address if no hooks contract is needed

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
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
            disableUnbalancedLiquidity: false,
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
     * @notice this is where the amounts of tokens to be initially added to the pool are set
     */
    function getSumPoolInitConfig(
        address token1,
        address token2
    ) internal pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 50e18; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 50e18; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 99e18; // Minimum amount of pool tokens to be received
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
