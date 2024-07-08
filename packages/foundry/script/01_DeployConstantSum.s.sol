//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import { ScaffoldETHDeploy, console } from "./ScaffoldETHDeploy.s.sol";
import { ConstantSumFactory } from "../contracts/pools/ConstantSumFactory.sol";
import { VeBALFeeDiscountHook } from "../contracts/hooks/VeBALFeeDiscountHook.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { MockToken1 } from "../contracts/mocks/MockToken1.sol";
import { MockToken2 } from "../contracts/mocks/MockToken2.sol";
import { MockVeBAL } from "../contracts/mocks/MockVeBAL.sol";

/**
 * @title Deploy Constant Sum
 * @notice Deploys mock tokens, a factory contract, a hooks contract, and a custom pool
 * @dev Set the deployment configurations in the internal getter functions below
 * @dev Run this script with `yarn deploy`
 */
contract DeployConstantSum is HelperConfig, ScaffoldETHDeploy {
    function run() external virtual {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        uint32 pauseWindowDuration = getFactoryConfig();

        vm.startBroadcast(deployerPrivateKey);
        // Deploy a factory contract
        ConstantSumFactory factory = new ConstantSumFactory(IVault(vault), pauseWindowDuration);
        console.log("Deployed Factory Address: %s", address(factory));

        // Deploy mock tokens
        IERC20 token1 = new MockToken1("Mock Token 1", "MT1", 1000e18);
        IERC20 token2 = new MockToken2("Mock Token 2", "MT2", 1000e18);
        IERC20 veBAL = new MockVeBAL("Vote-escrow BAL", "veBAL", 1000e18);
        console.log("Deployed MockToken1 Address: %s", address(token1));
        console.log("Deployed MockToken2 Address: %s", address(token2));
        console.log("Deployed Vote-escrow BAL Address: %s", address(veBAL));

        // Deploy a hooks contract
        VeBALFeeDiscountHook poolHooksContract = new VeBALFeeDiscountHook(
            IVault(vault),
            address(factory),
            address(veBAL),
            address(router)
        );
        console.log("Deployed hooks contract at address: %s", address(poolHooksContract));
        vm.stopBroadcast();

        // Grab arguments for pool deployment and initialization outside of broadcast to save gas
        RegistrationConfig memory regConfig = getPoolConfig(token1, token2);
        InitializationConfig memory initConfig = getInitializationConfig(token1, token2);

        vm.startBroadcast(deployerPrivateKey);
        // Deploy a pool and register it with the vault
        address pool = factory.create(
            regConfig.name,
            regConfig.symbol,
            regConfig.salt,
            regConfig.tokenConfig,
            regConfig.swapFeePercentage,
            regConfig.protocolFeeExempt,
            regConfig.roleAccounts,
            address(poolHooksContract),
            regConfig.liquidityManagement
        );
        console.log("Deployed Pool Address: %s", pool);

        // Seed the pool with initial liquidity
        initializePool(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Pool initialized successfully!");
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    /**
     * @dev Set the factory's pauseWindowDuration here
     */
    function getFactoryConfig() internal pure returns (uint32 pauseWindowDuration) {
        pauseWindowDuration = 365 days;
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getPoolConfig(IERC20 token1, IERC20 token2) internal view returns (RegistrationConfig memory regConfig) {
        string memory name = "Constant Sum Pool"; // name for the pool
        string memory symbol = "CS-50scUSD-50scDAI"; // symbol for the BPT
        bytes32 salt = keccak256(abi.encode(block.number)); // salt for the pool deployment via factory
        uint256 swapFeePercentage = 1e12; // 0.00001%
        bool protocolFeeExempt = false;
        address poolHooksContract = address(0); // zero address if no hooks contract is needed

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
        tokenConfig[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: token1,
            tokenType: TokenType.STANDARD, // STANDARD or WITH_RATE
            rateProvider: IRateProvider(address(0)), // The rate provider for a token (see further documentation above)
            paysYieldFees: false // Flag indicating whether yield fees should be charged on this token
        });
        tokenConfig[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: token2,
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
        IERC20 token1,
        IERC20 token2
    ) internal pure returns (InitializationConfig memory poolInitConfig) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = token1;
        tokens[1] = token2;
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
