// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "../interfaces/VaultTypes.sol";
import { IVaultExtensionMock } from "../interfaces/IVaultExtensionMock.sol";
import { IVaultAdmin } from "../interfaces/IVaultAdmin.sol";
import { IVault } from "../interfaces/IVault.sol";

import { PoolConfigLib, PoolConfigBits } from "../lib/PoolConfigLib.sol";
import { VaultExtension } from "../interfaces/VaultExtension.sol";

contract VaultExtensionMock is IVaultExtensionMock, VaultExtension {
    using PoolConfigLib for PoolConfigBits;

    constructor(IVault vault, IVaultAdmin vaultAdmin) VaultExtension(vault, vaultAdmin) {}

    function mockExtensionHash(bytes calldata input) external payable returns (bytes32) {
        return keccak256(input);
    }

    function manuallySetSwapFee(address pool, uint256 newSwapFee) external {
        _poolConfigBits[pool] = _poolConfigBits[pool].setStaticSwapFeePercentage(newSwapFee);
    }

    function manualRegisterPoolReentrancy(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts calldata roleAccounts,
        address poolHooksContract,
        LiquidityManagement calldata liquidityManagement
    ) external nonReentrant {
        IVault(address(this)).registerPool(
            pool,
            tokenConfig,
            swapFeePercentage,
            pauseWindowEndTime,
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

    function manualInitializePoolReentrancy(
        address pool,
        address to,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bytes memory userData
    ) external nonReentrant {
        IVault(address(this)).initialize(pool, to, tokens, exactAmountsIn, minBptAmountOut, userData);
    }
}