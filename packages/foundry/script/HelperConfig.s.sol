// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IRateProvider, TokenConfig, TokenType} from "../contracts/interfaces/VaultTypes.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";
import {IVault} from "../contracts/interfaces/IVault.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";
import {Script} from "forge-std/Script.sol";

/**
 * @title HelperConfig Script
 * @author BuidlGuidl Labs
 * @dev This script is where all configurations are set for the factory deployment, pool deployment, and pool initialization
 * @dev Each pool deployed must have a unique name
 */
contract HelperConfig {
    // BalancerV3 Sepolia addresses
    IVault public vault = IVault(0x1FC7F1F84CFE61a04224AC8D3F87f56214FeC08c);
    IRouter public router = IRouter(0xA0De078cd5cFa7088821B83e0bD7545ccfb7c883);

    /**
     * @dev Set the pause window duration for the pool factory here
     */
    function getFactoryConfig() public pure returns (uint256) {
        uint256 pauseWindowDuration = 365 days;
        return pauseWindowDuration;
    }

    /**
     * @dev Set the name, symbol, and token configuration for the pool here
     */
    function getPoolConfig(
        IERC20 token1,
        IERC20 token2
    ) public pure returns (string memory, string memory, TokenConfig[] memory) {
        string memory name = "Scaffold Balancer Pool #1";
        string memory symbol = "SB-50scUSD-50scDAI";

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
        tokenConfig[0] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: token1,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });
        tokenConfig[1] = TokenConfig({ // Make sure to have proper token order (alphanumeric)
            token: token2,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });

        return (name, symbol, tokenConfig);
    }

    /**
     * @dev Set the tokens, exactAmountsIn, minBptAmountOut, wethIsEth, and userData here
     */
    function getInitializationConfig(
        TokenConfig[] memory tokenConfig
    )
        public
        pure
        returns (IERC20[] memory, uint256[] memory, uint256, bool, bytes memory)
    {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = tokenConfig[0].token;
        tokens[1] = tokenConfig[1].token;
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 10 ether; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 10 ether; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
        bool wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        bytes memory userData = bytes(""); // Additional (optional) data required for adding initial liquidity

        return (tokens, exactAmountsIn, minBptAmountOut, wethIsEth, userData);
    }

    /**
     * @notice Creates mock tokens for the pool and mints 1000 of each to the deployer wallet
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
}
