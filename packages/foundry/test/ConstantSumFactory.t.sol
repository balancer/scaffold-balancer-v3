// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { VaultMock } from "@balancer-labs/v3-vault/contracts/test/VaultMock.sol";
import { VaultMockDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultMockDeployer.sol";
import { ERC20TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ConstantSumPool } from "../contracts/pools/ConstantSumPool.sol";
import { ConstantSumFactory } from "../contracts/factories/ConstantSumFactory.sol";

contract ConstantSumFactoryTest is Test {
    uint256 internal DEFAULT_SWAP_FEE = 1e16; // 1%

    VaultMock vault;
    ConstantSumFactory factory;
    ERC20TestToken tokenA;
    ERC20TestToken tokenB;

    address alice = vm.addr(1);

    function setUp() public {
        vault = VaultMockDeployer.deploy();
        factory = new ConstantSumFactory(IVault(address(vault)), 365 days);
        tokenA = new ERC20TestToken("Token A", "TKNA", 18);
        tokenB = new ERC20TestToken("Token B", "TKNB", 6);
    }

    function _createPool(
        string memory name,
        string memory symbol,
        IERC20 token1,
        IERC20 token2,
        bytes32 salt
    ) private returns (ConstantSumPool) {
        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0].token = token1;
        tokenConfigs[1].token = token2;
        bool protocolFeeExempt = false;
        PoolRoleAccounts memory roleAccounts;
        address poolHooksContract = address(0);
        LiquidityManagement memory liquidityManagement;

        return
            ConstantSumPool(
                factory.create(
                    name,
                    symbol,
                    salt,
                    tokenConfigs,
                    DEFAULT_SWAP_FEE, // swapFeePercentage
                    protocolFeeExempt,
                    roleAccounts,
                    poolHooksContract,
                    liquidityManagement
                )
            );
    }

    function testFactoryPausedState() public view {
        uint256 pauseWindowDuration = factory.getPauseWindowDuration();
        assertEq(pauseWindowDuration, 365 days);
    }

    function testPoolCreation__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        ConstantSumPool pool = _createPool("Constant Sum Pool #1", "CSP1", tokenA, tokenB, salt);
        assertEq(pool.name(), "Constant Sum Pool #1", "Wrong pool name");
        assertEq(pool.symbol(), "CSP1", "Wrong pool symbol");
        assertEq(pool.decimals(), 18, "Wrong pool decimals");
    }

    function testPoolSalt__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        ConstantSumPool pool = _createPool("Constant Sum Pool #1", "CSP1", tokenA, tokenB, bytes32(0));
        ConstantSumPool secondPool = _createPool("Constant Sum Pool #2", "CSP2", tokenA, tokenB, salt);

        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        assertFalse(address(pool) == address(secondPool), "Two deployed pool addresses are equal");
        assertEq(address(secondPool), expectedPoolAddress, "Unexpected pool address");
    }

    function testPoolSender__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);
        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0].token = tokenA;
        tokenConfigs[1].token = tokenB;

        // Different sender should change the address of the pool, given the same salt value
        vm.prank(alice);
        ConstantSumPool pool = _createPool("Constant Sum Pool #1", "CSP1", tokenA, tokenB, salt);

        assertFalse(address(pool) == expectedPoolAddress, "Unexpected pool address");

        vm.prank(alice);
        address aliceExpectedPoolAddress = factory.getDeploymentAddress(salt);
        assertTrue(address(pool) == aliceExpectedPoolAddress, "Unexpected pool address");
    }

    function testPoolCrossChainProtection__Fuzz(bytes32 salt, uint16 chainId) public {
        vm.assume(chainId > 1);

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0].token = tokenA;
        tokenConfigs[1].token = tokenB;

        vm.prank(alice);
        ConstantSumPool poolMainnet = _createPool("Constant Sum Pool #1", "CSP1", tokenA, tokenB, salt);

        vm.chainId(chainId);

        vm.prank(alice);
        ConstantSumPool poolL2 = _createPool("Constant Sum Pool #2", "CSP2", tokenA, tokenB, salt);

        // Same sender and salt, should still be different because of the chainId.
        assertFalse(address(poolL2) == address(poolMainnet), "L2 and mainnet pool addresses are equal");
    }
}
