// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MockToken1} from "../contracts/MockToken1.sol";
import {MockToken2} from "../contracts/MockToken2.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/**
 * @dev This is where all configurations are set for mock token deployment, factory deployment, pool deployment, and pool initialization
 * @dev Each pool deployed must have a unique name
 * @dev If using this and the associated deployment scripts to help troubleshoot your own custom pool type, then it is advised to use this HelperConfig to outline the appropriate details of your custom pool to use the already written example scripts within this repo.
 */
contract HelperConfig {
    // BalancerV3 Sepolia addresses (5th testnet release)
    IVault public vault = IVault(0xD5584b37D1845fFeD958C2d94bC675603DdCce68);
    IRouter public router = IRouter(0x1c58cc548a23956469c7C528Bb3a846c842dfaF9);
    // Canonical permit2 Sepolia address
    IPermit2 public permit2 =
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /**
     * @notice Creates mock tokens for the pool and mints 1000 of each to the deployer wallet
     */
    function deployMockTokens() internal returns (address, address) {
        MockToken1 scUSD = new MockToken1("Scaffold USD", "scUSD");
        MockToken2 scDAI = new MockToken2("Scaffold DAI", "scDAI");
        return (address(scDAI), address(scUSD));
    }

    /**
     * @dev Set the pause window duration for the pool factory here
     */
    function getFactoryConfig()
        public
        pure
        returns (uint32 pauseWindowDuration)
    {
        pauseWindowDuration = 365 days;
    }

    /**
     * @dev Set the name, symbol, and token configuration for the pool here
     * @dev TokenConfig encapsulates the data required for the Vault to support a token of the given type. For STANDARD tokens,
     * the rate provider address must be 0, and paysYieldFees must be false. All WITH_RATE tokens need a rate provider,
     * and may or may not be yield-bearing.
     */
    function getPoolConfig(
        address token1,
        address token2
    )
        public
        pure
        returns (
            string memory name,
            string memory symbol,
            TokenConfig[] memory tokenConfig
        )
    {
        name = "Scaffold Balancer Constant Price Pool #1"; // name for the pool
        symbol = "SB-50scUSD-50scDAI"; // symbol for the BPT

        tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.
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
    }

    /**
     * @dev Set the tokens, exactAmountsIn, minBptAmountOut, wethIsEth, and userData here
     */
    function getInitializationConfig(
        TokenConfig[] memory tokenConfig
    )
        public
        pure
        returns (
            IERC20[] memory tokens,
            uint256[] memory exactAmountsIn,
            uint256 minBptAmountOut,
            bool wethIsEth,
            bytes memory userData
        )
    {
        tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = tokenConfig[0].token;
        tokens[1] = tokenConfig[1].token;
        exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = 10 ether; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = 10 ether; // amount of token2 to send during pool initialization
        minBptAmountOut = 1 ether; // Minimum amount of pool tokens to be received
        wethIsEth = false; // If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
        userData = bytes(""); // Additional (optional) data required for adding initial liquidity
    }

    function sortTokenConfig(
        TokenConfig[] memory tokenConfig
    ) public pure returns (TokenConfig[] memory) {
        for (uint256 i = 0; i < tokenConfig.length - 1; i++) {
            for (uint256 j = 0; j < tokenConfig.length - i - 1; j++) {
                if (tokenConfig[j].token > tokenConfig[j + 1].token) {
                    // Swap if they're out of order.
                    (tokenConfig[j], tokenConfig[j + 1]) = (
                        tokenConfig[j + 1],
                        tokenConfig[j]
                    );
                }
            }
        }

        return tokenConfig;
    }
}
