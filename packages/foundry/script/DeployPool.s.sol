// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";

import {IERC20} from "../contracts/interfaces/IVaultExtension.sol";
import {LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType} from "../contracts/interfaces/VaultTypes.sol";
import {HelperFunctions} from "../utils/HelperFunctions.sol";
import {HelperConfig} from "../utils/HelperConfig.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title DeployPool Script
 * @author BuidlGuidl Labs
 * @notice The script, using the `.env` specified deployer wallet, creates new pools from a pre-existing custom pool factory (adhering to the Constant Price Pool example by default).
 * @dev You need to assign the appropriate custom pool factory address (and associated dependencies / params requirements). This script is to be used after DeployCustomPoolFactoryAndNewPoolExample.s.sol.  It does all of this so the new pool is ready to use with the ScaffoldBalancer front end tool.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFromFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 */
contract DeployPool is HelperConfig, HelperFunctions, Script {
    IERC20[] tokens = new IERC20[](2); // Tokens used to seed the pool (must match the registered tokens)

    /**
     * @param factoryAddress the address of the pool factory
     * @param name of the pool
     * @param symbol of the pool
     * @param token1 for the pool
     * @param token2 for the pool
     */
    function deployPoolFromFactory(
        address factoryAddress,
        string memory name,
        string memory symbol,
        address token1,
        address token2
    ) internal returns (address) {
        CustomPoolFactoryExample poolFactory = CustomPoolFactoryExample(
            factoryAddress
        );

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

        // make sure to have proper token order (alphanumeric)
        tokenConfig[0] = TokenConfig({
            token: IERC20(address(token1)),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });
        tokenConfig[1] = TokenConfig({
            token: IERC20(address(token2)),
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
     * Initilizes a pool with the router by adding liquidity
     * The resulting BPT tokens are sent to the deployer wallet
     * @param pool address of the pool to be initialized
     */
    function initializePool(
        address pool,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) internal {
        // Approve the vault to spend the tokens that are sent to the pool
        maxApproveVault();

        router.initialize(
            pool,
            tokens,
            exactAmountsIn,
            minBptAmountOut,
            wethIsEth,
            userData
        );
    }

    // Only need to approve the vault since only vault handles possession of tokens
    function maxApproveVault() internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(vault), type(uint256).max);
        }
    }

    /**
     * Create mock tokens for the pool and mint 1000 of each to the deployer wallet
     * @return addresses of the mock tokens
     */
    function deployMockTokens() internal returns (address, address) {
        FakeTestERC20 scUSD = new FakeTestERC20(
            "Scaffold Balancer Test Token #1",
            "scUSD"
        );
        FakeTestERC20 scDAI = new FakeTestERC20(
            "Scaffold Balancer Test Token #2",
            "scDAI"
        );

        return (address(scUSD), address(scDAI));
    }

    // Deploy only the pool factory with CLI command `yarn deploy:pool`
    function run() external virtual {
        // Pool deployment configurations
        string memory name = "Scaffold Balancer Pool #2";
        string memory symbol = "SB-50scDAI-50scUSD";
        address poolFactoryAddress = DevOpsTools.get_most_recent_deployment(
            "CustomPoolFactoryExample", // Must match the factory contract name
            block.chainid
        ); // Get the most recently deployed address of the pool factory

        // Pool initialization configurations
        uint256[] memory exactAmountsIn = new uint256[](2); // Tokens used to seed the pool (must match the registered tokens)
        exactAmountsIn[0] = 10 ether;
        exactAmountsIn[1] = 10 ether;
        uint256 minBptAmountOut = 1 ether;
        bool wethIsEth = false;
        bytes memory userData = bytes("");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address token1, address token2) = deployMockTokens();

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
