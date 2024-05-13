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

import {ConstantPricePool} from "../contracts/ConstantPricePool.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";

/**
 * @title Custom Pool Factory Starter Test Template
 * @author BUIDL GUIDL
 * @notice This test file serves as a starting template that developers can use when creating their own BalancerV3 custom pool factory tests.  Paired with the README, this template has comments marked "TODO" that help guide devlopers to address starting test aspects. This is not production ready, and it is the developers responsibility to carry out proper testing and auditing for their pool.
 * These tests roughly mirror the typical testing cases that are found in the BalancerV3 monorepo for weighted pool factory tests.  As a reference tool, it only makes sense to have tests that, at the very least, roughly mirror how weighted pool factories are tested within BalancerV3 monorepo.
 * @dev This template is written for the Constant Price Custom Pool Factory.
 * When creating your own custom pool factory, developers are expected to: create their own custom pool factory file, test file, script file, and of course update dependencies as needed. They simply can just duplicate or override the files that are in this repo marked as "example" within their title.
 */
contract CustomPoolFactoryTemplateTest is Test {
    VaultMock vault;
    CustomPoolFactoryExample factory; // TODO - Update with your own custom pool factory
    RateProviderMock rateProvider;
    ERC20TestToken tokenA;
    ERC20TestToken tokenB;

    address alice = vm.addr(1);

    function setUp() public {
        vault = VaultMockDeployer.deploy();
        factory = new CustomPoolFactoryExample(
            IVault(address(vault)),
            365 days
        ); // TODO - Update with your own custom pool factory

        tokenA = new ERC20TestToken("Token A", "TKNA", 18);
        tokenB = new ERC20TestToken("Token B", "TKNB", 6);
    }

    /**
     * @dev Checks that custom pool factory pauseWindowDuration is what is expected. Recall that this is specified in the custom pool factory smart contract, for this example see `CustomPoolFactoryExample.sol`
     */
    function testFactoryPausedState() public {
        uint256 pauseWindowDuration = factory.getPauseWindowDuration();
        assertEq(pauseWindowDuration, 365 days); // TODO - Update with your own custom pool factory specified values
    }

    /**
     * @dev Checks that custom pool factory creates new pools properly. It does this by carrying out fuzz tests with different `salt` values, and checking that the newly created pool has the proper `symbol` returned when queried.
     */
    function testPoolCreation__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        TokenConfig[] memory tokens = new TokenConfig[](2);

        // assign tokens in alphanumeric order - FYI in ConstantPool.t.sol, they are sorted via a helper
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        ConstantPricePool pool = ConstantPricePool(
            factory.create("New Custom Pool #2", "CP2", tokens, bytes32(0)) // TODO - Update with your own custom pool factory create() params rqd
        );

        assertEq(pool.symbol(), "CP2", "Wrong pool symbol");
    }

    /**
     * @dev Checks that custom pool factory creates new pools properly at an expected address using a salt value. It does this by carrying out fuzz tests with different `salt` values, and checking:
     * - A pool without the salt value does not have an address equal to the `expectedPoolAddress` when creating a pool from the factory with a specific salt value.
     * - The expected address for a pool created from a factory with a specific salt value is equal to an actual pool created from said factory with said salt.
     */
    function testPoolSalt__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        ConstantPricePool pool = ConstantPricePool(
            factory.create("New Custom Pool #2", "CP2", tokens, bytes32(0)) // TODO - Update with your own custom pool factory create() params rqd
        );
        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        ConstantPricePool secondPool = ConstantPricePool(
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

    /**
     * @dev Checks that custom pool factory creates new pools properly at an expected address using a salt value, for an appropriate user. It does this by carrying out fuzz tests with different `salt` values, and checking:
     * - A user (Alice) creates a new pool, and that its address does not equal to the `expectedPoolAddress` for a different user.
     * - The pool that Alice creates matches the expected address that would result from her creating a pool from a factory with a specific salt value.
     */
    function testPoolSender__Fuzz(bytes32 salt) public {
        vm.assume(salt > 0);
        address expectedPoolAddress = factory.getDeploymentAddress(salt);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        // Different sender should change the address of the pool, given the same salt value
        vm.prank(alice);
        ConstantPricePool pool = ConstantPricePool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        ); // TODO - Update with your own custom pool factory create() params rqd
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

    /**
     * @dev Checks that even though the same sender and salt values are used in creating a pool from a specific pool factory type, the chainIds will result in different addresses on each respective chain.
     * It does this carrying out fuzz tests with different salts and different chainIds.
     */
    function testPoolCrossChainProtection__Fuzz(
        bytes32 salt,
        uint16 chainId
    ) public {
        vm.assume(chainId > 1);

        TokenConfig[] memory tokens = new TokenConfig[](2);
        tokens[0].token = tokenB;
        tokens[1].token = tokenA;

        vm.prank(alice);
        ConstantPricePool poolMainnet = ConstantPricePool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        ); // TODO - Update with your own custom pool factory create() params rqd

        vm.chainId(chainId);

        vm.prank(alice);
        ConstantPricePool poolL2 = ConstantPricePool(
            factory.create("New Custom Pool #2", "CP2", tokens, salt)
        ); // TODO - Update with your own custom pool factory create() params rqd

        // Same sender and salt, should still be different because of the chainId.
        assertFalse(
            address(poolL2) == address(poolMainnet),
            "L2 and mainnet pool addresses are equal"
        );
    }
}
