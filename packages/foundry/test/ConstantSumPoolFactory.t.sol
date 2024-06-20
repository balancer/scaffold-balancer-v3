// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {TokenConfig, TokenType} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/vault/IRateProvider.sol";

import {VaultMock} from "@balancer-labs/v3-vault/contracts/test/VaultMock.sol";
import {VaultExtensionMock} from "@balancer-labs/v3-vault/contracts/test/VaultExtensionMock.sol";
import {VaultMockDeployer} from "@balancer-labs/v3-vault/test/foundry/utils/VaultMockDeployer.sol";
import {ERC20TestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import {RateProviderMock} from "@balancer-labs/v3-vault/contracts/test/RateProviderMock.sol";

import {ConstantSumPool} from "../contracts/ConstantSumPool.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";

contract ConstantSumPoolFactoryTest is Test {
    VaultMock vault;
    CustomPoolFactoryExample factory;
    RateProviderMock rateProvider;
    ERC20TestToken tokenA;
    ERC20TestToken tokenB;

    address alice = vm.addr(1);

    function setUp() public {
        vault = VaultMockDeployer.deploy();
        factory = new CustomPoolFactoryExample(
            IVault(address(vault)),
            365 days
        );

        tokenA = new ERC20TestToken("Token A", "TKNA", 18);
        tokenB = new ERC20TestToken("Token B", "TKNB", 6);
    }

    function testFactoryPausedState() public {
        uint256 pauseWindowDuration = factory.getPauseWindowDuration();
        assertEq(pauseWindowDuration, 365 days);
    }

    function testPoolCreation__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        TokenConfig[] memory tokens = new TokenConfig[](2);

        // assign tokens in alphanumeric order - FYI in ConstantPool.t.sol, they are sorted via a helper
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        ConstantSumPool pool = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, bytes32(0))
        );

        assertEq(pool.symbol(), "CP2", "Wrong pool symbol");
    }

    function testPoolSalt__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        ConstantSumPool pool = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, bytes32(0))
        );
        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        ConstantSumPool secondPool = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        );

        assertFalse(
            address(pool) == address(secondPool),
            "Two deployed pool addresses are equal"
        );
        assertEq(
            address(secondPool),
            expectedPoolAddress,
            "Unexpected pool address"
        );
    }

    function testPoolSender__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);
        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        // Different sender should change the address of the pool, given the same salt value
        vm.prank(alice);
        ConstantSumPool pool = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        );
        assertFalse(
            address(pool) == expectedPoolAddress,
            "Unexpected pool address"
        );

        vm.prank(alice);
        address aliceExpectedPoolAddress = factory.getDeploymentAddress(salt);
        assertTrue(
            address(pool) == aliceExpectedPoolAddress,
            "Unexpected pool address"
        );
    }

    function testPoolCrossChainProtection__Fuzz(
        bytes32 salt,
        uint16 chainId
    ) public {
        vm.assume(chainId > 1);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        vm.prank(alice);
        ConstantSumPool poolMainnet = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        );

        vm.chainId(chainId);

        vm.prank(alice);
        ConstantSumPool poolL2 = ConstantSumPool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        );

        // Same sender and salt, should still be different because of the chainId.
        assertFalse(
            address(poolL2) == address(poolMainnet),
            "L2 and mainnet pool addresses are equal"
        );
    }
}
