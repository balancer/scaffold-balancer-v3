// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Internal
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";
import {HelperFunctions} from "../utils/HelperFunctions.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
// External
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IRateProvider, TokenConfig, TokenType} from "../contracts/interfaces/VaultTypes.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployPool Script
 * @author BuidlGuidl Labs
 * @notice This script uses the PK specified in the .env file to create a new pool using the most recently deployed pool factory
 * @notice This script is inhereted by Deploy.s.sol but can be run directly with `yarn deploy:pool`
 * @dev if running directly, set the pool deployment and initialization configurations in the `run()` function below
 */
contract DeployPool is HelperConfig, HelperFunctions, Script {
    IERC20[] tokens = new IERC20[](2); // Array of tokens to be used in the pool

    /**
     * @notice Deploys a pool using a pool factory
     * @dev Be sure to review the TokenConfig since only specific sequences of tokenType, rateProvider, and yieldFeeExempt are allowed
     * @param factoryAddress the address of the pool factory
     * @param name for the pool
     * @param symbol for the pool
     * @param token1 for the pool
     * @param token2 for the pool
     */
    function deployPoolFromFactory(
        address factoryAddress,
        string memory name,
        string memory symbol,
        IERC20 token1,
        IERC20 token2
    ) internal returns (address) {
        CustomPoolFactoryExample poolFactory = CustomPoolFactoryExample(
            factoryAddress
        );

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

        // make sure to have proper token order (alphanumeric)
        tokenConfig[0] = TokenConfig({
            token: token1,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });
        tokenConfig[1] = TokenConfig({
            token: token2,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });

        bytes32 salt = convertNameToBytes32(name);

        address newPool = poolFactory.create(name, symbol, tokenConfig, salt);

        tokens[0] = tokenConfig[0].token;
        tokens[1] = tokenConfig[1].token;

        console.log("Deployed Pool Address: %s", newPool);

        return newPool;
    }

    /**
     * @notice Initilizes a pool using the router contract
     * @dev The resulting BPT tokens are sent to the deployer wallet set in the .env file
     * @param pool address of the pool to be initialized
     * @param exactAmountsIn amounts of tokens to be added, sorted in token alphanumeric order
     * @param minBptAmountOut minimum amount of pool tokens to be received
     * @param wethIsEth if true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
     * @param userData additional (optional) data required for adding initial liquidity
     */
    function initializePool(
        address pool,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) internal {
        maxApproveVault(); // Must approve the vault to spend tokens before adding liquidity

        router.initialize(
            pool,
            tokens,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
        );
    }

    /**
     * @notice Only need to approve the vault since only vault handles possession of tokens
     */
    function maxApproveVault() internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(vault), type(uint256).max);
        }
    }

    /**
     * Create mock tokens for the pool and mint 1000 of each to the deployer wallet
     * @return addresses of the mock tokens
     */
    function deployMockTokens() internal returns (IERC20, IERC20) {
        FakeTestERC20 scUSD = new FakeTestERC20(
            "Scaffold Balancer Test Token #1",
            "scUSD"
        );
        FakeTestERC20 scDAI = new FakeTestERC20(
            "Scaffold Balancer Test Token #2",
            "scDAI"
        );

        return (scUSD, scDAI);
    }

    /**
     * @dev Deploy only the pool with the CLI command `yarn deploy:pool`
     * @dev Set your pool deployment and initialization configurations below
     */
    function run() external virtual {
        // Pool Deployment Config (also requires review of TokenConfig in `deployPoolFromFactory` function)
        string memory name = "Scaffold Balancer Pool #2";
        string memory symbol = "SB-50scDAI-50scUSD";
        IERC20 token1; // Make sure to have proper token order (alphanumeric)
        IERC20 token2; // Make sure to have proper token order (alphanumeric)
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "CustomPoolFactoryExample", // Must match the factory contract name
            block.chainid
        ); // Get the most recently deployed address of the pool factory

        // Pool Initialization Config
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 10 ether; // amount for first token
        exactAmountsIn[1] = 10 ether; // amount for second token
        uint256 minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // 	If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (token1, token2) = deployMockTokens();

        address pool = deployPoolFromFactory(
            poolFactoryAddress,
            name,
            symbol,
            token1,
            token2
        );

        initializePool(
            pool,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
        );

        vm.stopBroadcast();
    }
}
