// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

abstract contract CodeConstants {
    address public FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address account;
        address vault;
        address stablePoolFactory;
        address weightedPoolFactory;
        address router;
        address permit2;
        address DAI;
        address WETH;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            account: 0x05b8B8ed022FB7FC2e75983EAb003a6C7202E1A0,
            vault: 0x7966FE92C59295EcE7FB5D9EfDB271967BFe2fbA,
            stablePoolFactory: 0x4b4b45Edf6Ca26ae894377Cf4FeD1FA9F82D85C6,
            weightedPoolFactory: 0x765ce16dbb3D7e89a9beBc834C5D6894e7fAA93c,
            router: 0xDd10aDF05379D7C0Ee4bC9c72ecc5C01c40E25b8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            DAI: 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6,
            WETH: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        localNetworkConfig = NetworkConfig({
            account: FOUNDRY_DEFAULT_SENDER,
            vault: address(0),
            stablePoolFactory: address(0),
            weightedPoolFactory: address(0),
            router: address(0),
            permit2: address(0),
            DAI: makeAddr("DAI"),
            WETH: makeAddr("WETH")
        });

        return localNetworkConfig;
    }
}
