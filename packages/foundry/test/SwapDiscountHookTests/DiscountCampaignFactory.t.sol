// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import { PoolMock } from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";

import { DiscountCampaignFactory } from "../../contracts/hooks/SwapDiscountHook/DiscountCampaignFactory.sol";
import { SwapDiscountHook } from "../../contracts/hooks/SwapDiscountHook/SwapDiscountHook.sol";
import {
    IDiscountCampaignFactory
} from "../../contracts/hooks/SwapDiscountHook/Interfaces/IDiscountCampaignFactory.sol";
import { console } from "forge-std/console.sol";

contract DiscountCampaignFactoryTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    DiscountCampaignFactory discountCampaignFactory;
    SwapDiscountHook discountHook;
    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address payable internal trustedRouter;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        discountHook = SwapDiscountHook(poolHooksContract);
        discountCampaignFactory.setSwapDiscountHook(address(discountHook));
    }

    function testSuccessfullDeploymentOfCampaignContract() public {
        deal(address(dai), address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory params = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(params);

        // test the struct
        (address _campaignAddress, address _owner) = discountCampaignFactory.discountCampaigns(address(pool));

        assertEq(_campaignAddress, campaignAddress, "Invalid campaign Address");
        assertEq(_owner, address(this), "Invalid owner Address");
    }

    function testUnsuccessfulDeploymentsOfCampaignContract() public {
        vm.expectRevert();
        IDiscountCampaignFactory.CampaignParams memory params = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        discountCampaignFactory.createCampaign(params);

        deal(address(dai), address(discountCampaignFactory), 100e18);

        discountCampaignFactory.createCampaign(params);

        vm.expectRevert(IDiscountCampaignFactory.PoolCampaignAlreadyExist.selector);
        discountCampaignFactory.createCampaign(params);
    }

    function testUnsuccessfulCampaignUpdate() public {
        deal(address(dai), address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(createParams);

        IDiscountCampaignFactory.CampaignParams memory updateParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 5 days,
            coolDownPeriod: 0,
            discountAmount: 20e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        vm.expectRevert(IDiscountCampaignFactory.PoolCampaignHasnotExpired.selector);
        discountCampaignFactory.updateCampaign(updateParams);

        vm.expectRevert(IDiscountCampaignFactory.PoolCampaignDoesnotExist.selector);
        updateParams.pool = address(bob);
        discountCampaignFactory.updateCampaign(updateParams);

        vm.prank(address(bob));
        vm.expectRevert(IDiscountCampaignFactory.NOT_AUTHORIZED.selector);
        updateParams.pool = address(pool);
        discountCampaignFactory.updateCampaign(updateParams);

        // campaign hasn't expired yet
        vm.warp(block.timestamp + 7 days);
        vm.expectRevert();
        discountCampaignFactory.updateCampaign(updateParams);
    }

    function testSuccessfulCampaignUpdate() public {
        deal(address(dai), address(discountCampaignFactory), 100e18);

        IDiscountCampaignFactory.CampaignParams memory createParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 100e18,
            expirationTime: 2 days,
            coolDownPeriod: 0,
            discountAmount: 50e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        address campaignAddress = discountCampaignFactory.createCampaign(createParams);

        vm.warp(block.timestamp + 7 days);
        deal(address(dai), address(discountCampaignFactory), 1000e18);

        IDiscountCampaignFactory.CampaignParams memory updateParams = IDiscountCampaignFactory.CampaignParams({
            rewardAmount: 1000e18,
            expirationTime: 5 days,
            coolDownPeriod: 0,
            discountAmount: 20e18,
            pool: address(pool),
            owner: address(this),
            rewardToken: address(dai)
        });

        discountCampaignFactory.updateCampaign(updateParams);
    }

    // ===============================================================================

    function createHook() internal override returns (address) {
        trustedRouter = payable(router);
        discountCampaignFactory = new DiscountCampaignFactory();
        // lp will be the owner of the hook. Only LP is able to set hook fee percentages.
        vm.prank(lp);
        address swapDiscountHook = address(
            new SwapDiscountHook(
                IVault(address(vault)),
                address(factoryMock),
                trustedRouter,
                address(discountCampaignFactory),
                "SwapDiscountNFT",
                "SDN"
            )
        );
        vm.label(swapDiscountHook, "Swap Discount Hook");
        return swapDiscountHook;
    }

    function _registerPoolWithHook(address swapDhookPool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(factory).registerPool(
            swapDhookPool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
