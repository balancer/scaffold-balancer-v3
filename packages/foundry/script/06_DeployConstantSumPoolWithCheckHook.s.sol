//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { PoolHelpers, CustomPoolConfig, InitializationConfig } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { ConstantSumFactory } from "../contracts/factories/ConstantSumFactory.sol";
import { NftCheckHook } from "../contracts/hooks/NftCheckHook.sol";
import { MockNft } from "../contracts/mocks/MockNft.sol";
import { MockERC20Factory } from "../contracts/mocks/MockERC20Factory.sol";
import { ERC20Ownable } from "../contracts/mocks/ERC20Ownable.sol";
import { Router } from "../contracts/mocks/Router.sol";


/**
 * @title Deploy Constant Sum Pool
 * @notice Deploys, registers, and initializes a constant sum pool that uses a swap fee discount hook
 */
contract DeployConstantSumPoolWithCheckHook is PoolHelpers, ScaffoldHelpers {
    function deployConstantSumPoolWithCheckHook(address token) internal {
        // Start creating the transactions
        address deployerAddress = address(uint160(getDeployerAddress()));
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a factory
        ConstantSumFactory factory = new ConstantSumFactory(vault, 365 days); // pauseWindowDuration
        console.log("Constant Sum Factory deployed at: %s", address(factory));

        // Deploy an Nft and mint one
        MockNft mockNft = new MockNft("NFTFactory", "NFTF");


        MockERC20Factory mockERC20Factory = new MockERC20Factory("MockERC20Factory");
        MockNft(mockNft).setLinkedTokenFactory(address(mockERC20Factory));
        
        address[] memory membersToFund = new address[](1);
        membersToFund[0] = deployerAddress;
        uint256[] memory amountsToFund = new uint256[](1);
        amountsToFund[0] = 1000e18;

        // Deploy a Sample Token - will throw warning on deploy as it is not used in the following code
        // however it is needed in order to interact with the contract via scaffold's patterns
        ERC20Ownable mockRwa = new ERC20Ownable(
            "Sample Token",
            "ST",
            deployerAddress,
            address(mockERC20Factory),
            address(0),
            0,
            membersToFund,
            amountsToFund
        );

         (uint256 tokenId, address linkedTokenAddress) = MockNft(mockNft).mint(
            deployerAddress,
            "https://0a050602b1c1aeae1063a0c8f5a7cdac.ipfscdn.io/ipfs/QmSiA82PQNuWuBfQtuzWKwnZV94qs34jrW1L6PaR69jeoE/metadata.json",
            address(0),
            new string[](0),
            "RWA Token",
            "RWAT",
            membersToFund,
            amountsToFund
        );

        // Set the pool's deployment, registration, and initialization config
        console.log("linkedTokenAddress: %s", linkedTokenAddress);
        CustomPoolConfig memory poolConfig = getCheckSumPoolConfig(linkedTokenAddress, token);
        InitializationConfig memory initConfig = getCheckSumPoolInitConfig(linkedTokenAddress, token);

        // Deploy a hook
        address nftCheckHook = address(
            new NftCheckHook(vault, address(mockNft), tokenId, linkedTokenAddress, token)
        );
        console.log("NftCheckHook deployed at address: %s", nftCheckHook);


        MockNft(mockNft).approve(nftCheckHook, tokenId);
        MockNft(mockNft).transferFrom(deployerAddress, nftCheckHook, tokenId);

        // Deploy a pool and register it with the vault
        address pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            nftCheckHook, // poolHooksContract
            poolConfig.liquidityManagement
        );
        console.log("SumPoolWithNftCheckHook deployed at: %s", pool);

        Router router = new Router();  // this is deployed so we can get the abi to call the initialize function


        // Approve the router to spend tokens for pool initialization
        approveRouterWithPermit2(initConfig.tokens);

        // Seed the pool with initial liquidity
        // router.initialize(
        //     pool,
        //     initConfig.tokens,
        //     initConfig.exactAmountsIn,
        //     initConfig.minBptAmountOut,
        //     initConfig.wethIsEth,
        //     initConfig.userData
        // );
        // console.log("SumPoolWithNftCheckHook initialized successfully!");
        vm.stopBroadcast();
    }

    /**
     * @dev Set all of the configurations for deploying and registering a pool here
     * @notice TokenConfig encapsulates the data required for the Vault to support a token of the given type.
     * For STANDARD tokens, the rate provider address must be 0, and paysYieldFees must be false.
     * All WITH_RATE tokens need a rate provider, and may or may not be yield-bearing.
     */
    function getCheckSumPoolConfig(address token1, address token2) internal view returns (CustomPoolConfig memory config) {
        string memory name = "NFT Constant Sum Pool"; // name for the pool
        string memory symbol = "NFTCSP"; // symbol for the BPT
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
     * @notice this is where the amounts of tokens to be initially added to the pool are set
     */
    function getCheckSumPoolInitConfig(
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
