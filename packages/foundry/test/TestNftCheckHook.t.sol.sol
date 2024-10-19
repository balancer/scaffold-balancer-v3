// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";

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

import { VeBALFeeDiscountHookExample } from "../contracts/hooks/VeBALFeeDiscountHookExample.sol";
import { NftCheckHook } from "../contracts/hooks/NftCheckHook.sol";
import { MockNft } from "../contracts/mocks/MockNft.sol";
// import { ConstantSumFactory } from "../contracts/factories/ConstantSumFactory.sol";
import { MockLinked } from "../contracts/mocks/MockLinked.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import { InitializationConfig } from "../script/PoolHelpers.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";


contract TestNftCheckHook is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal linkedTokenIdx;
    uint256 internal usdcIdx;

    // Maximum swap fee of 10%
    uint64 public constant MAX_SWAP_FEE_PERCENTAGE = 10e16;

    address payable internal hookOwner;
    uint256 internal hookOwnerKey;
    address payable internal trustedRouter;

    MockNft mockNft;
    uint256 tokenId;
    address nftCheckHook;
    // ConstantSumFactory factory = new ConstantSumFactory(vault, 365 days); // pauseWindowDuration
    bool nftIsDeposited;
    MockLinked linkedToken;
    bool linkedTokenIsMinted;
    address linkedTokenAddress;

    uint256 constant LINKED_TOKEN_SUPPLY = 1e5*1e18;

    function setUp() public override {
        (hookOwner, hookOwnerKey) = createUser("hookOwner");
        users.push(hookOwner);
        userKeys.push(hookOwnerKey);

        vm.prank(hookOwner);
        mintNft();

        super.setUp();
        poolHooksContract = nftCheckHook; // overriding

        linkedTokenAddress = NftCheckHook(nftCheckHook).getLinkedToken(); // get linked token address
        linkedToken = MockLinked(linkedTokenAddress); // linked token
        tokens.push(ERC20TestToken(linkedTokenAddress)); // push linked token to tokens as ERC20TestToken
        linkedTokenIsMinted = true; // to enable the pool creation
        (linkedTokenIdx, usdcIdx) = getSortedIndexes(address(linkedToken), address(usdc));

        pool = createPool();
        approveForPool(IERC20(pool));
        vaultConvertFactor = vault.getConvertFactor();

        InitializationConfig memory initConfig = getCheckSumPoolInitConfig(address(linkedToken), address(usdc));
        approveRouterWithPermit2(initConfig.tokens);
        // Grants LP the ability to change the static swap fee percentage.
        // authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), lp);
        
        // initPool();
    }

    function mintNft() internal {
        mockNft = new MockNft("NFTFactory", "NFTF");
        vm.prank(hookOwner);
        tokenId = mockNft.mintNft("https://0a050602b1c1aeae1063a0c8f5a7cdac.ipfscdn.io/ipfs/QmSiA82PQNuWuBfQtuzWKwnZV94qs34jrW1L6PaR69jeoE/metadata.json");
    }

    function getCheckSumPoolInitConfig(
        address token1,
        address token2
    ) internal returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2); // Array of tokens to be used in the pool
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2); // Exact amounts of tokens to be added, sorted in token alphanumeric order
        exactAmountsIn[0] = poolInitAmount; // amount of token1 to send during pool initialization
        exactAmountsIn[1] = poolInitAmount; // amount of token2 to send during pool initialization
        uint256 minBptAmountOut = bptAmountRoundDown; // Minimum amount of pool tokens to be received
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



    function createHook() internal override returns (address) {
        // HookFlags memory hookFlags;

        trustedRouter = payable(router);

        // hookOwner will be the owner of the hook. Only hookOwner is able to set hook fee percentages.
        vm.prank(hookOwner);
        nftCheckHook = address(
            new NftCheckHook(vault, address(mockNft), tokenId, address(usdc), "RWA Token", "RWAT", LINKED_TOKEN_SUPPLY)
        );
        vm.label(nftCheckHook, "Nft Check Hook");
        return nftCheckHook;
    }

    function testMintNft() public {
        assertEq(mockNft.balanceOf(hookOwner) > 0, true, "hookOwner does not have an NFT");
    }

    function testLinkedTokenInitialBalances() public {
        uint256 hookOwnerBalance = linkedToken.balanceOf(hookOwner);
        assertEq(hookOwnerBalance, LINKED_TOKEN_SUPPLY, "hookOwner has no linked tokens");
        uint256 bobBalance = linkedToken.balanceOf(bob);
        assertEq(bobBalance, 0, "Bob has some linked tokens");
    }

    // function testInitializePoolWithoutNftTransfer() public {
    //     assertEq(address(mockNft), NftCheckHook(nftCheckHook).getNftContract());
    //     vm.expectRevert();
    //     initPool();
    // }

    function testInitializePoolWithNftTransfer() public {
        assertEq(address(mockNft), NftCheckHook(nftCheckHook).getNftContract());
        vm.prank(hookOwner);
        mockNft.transferFrom(hookOwner, nftCheckHook, 0);
        // permit2.approve(linkedTokenAddress, address(vault), 1000e18, 0);
        initPool();
    }

    function createPool() internal override returns (address) {
        if (!linkedTokenIsMinted) return address(0);
        return _createPool([address(linkedToken), address(usdc)].toMemoryArray(), "pool");
    }

    function _createPool(address[] memory tokens, string memory label) internal virtual override returns (address) {
        PoolMock newPool = new PoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL");
        vm.label(address(newPool), label);

        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;
        liquidityManagement.enableDonation = true;


        factoryMock.registerPool(
            address(newPool),
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        return address(newPool);
    }

    function _registerPoolWithHook(address exitFeePool, TokenConfig[] memory tokenConfig, address factory) private {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true
        });

        PoolFactoryMock(factory).registerPool(
            exitFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }

    function initPool() internal override {
        if (mockNft.ownerOf(tokenId) == nftCheckHook) {
            vm.startPrank(hookOwner);
            permit2.approve(address(linkedToken), nftCheckHook, type(uint160).max, type(uint48).max);
            permit2.approve(address(usdc), nftCheckHook, type(uint160).max, type(uint48).max);
            permit2.approve(address(linkedToken), address(vault), type(uint160).max, type(uint48).max);
            permit2.approve(address(usdc), address(vault), type(uint160).max, type(uint48).max);
            _initPool(pool, [poolInitAmount, poolInitAmount].toMemoryArray(), 0);
            vm.stopPrank();
        }
    }

    function approveRouterWithPermit2(IERC20[] memory tokens) internal {
        approveSpenderOnToken(address(permit2), tokens);
        approveSpenderOnPermit2(address(router), tokens);
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param spender Address of the spender
     * @param tokens Array of tokens to approve
     */
    function approveSpenderOnToken(address spender, IERC20[] memory tokens) internal {
        uint256 maxAmount = type(uint256).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, maxAmount);
        }
    }

    /**
     * @notice Max approving to speed up UX on frontend
     * @param spender Address of the spender
     * @param tokens Array of tokens to approve
     */
    function approveSpenderOnPermit2(address spender, IERC20[] memory tokens) internal {
        uint160 maxAmount = type(uint160).max;
        uint48 maxExpiration = type(uint48).max;
        for (uint256 i = 0; i < tokens.length; ++i) {
            permit2.approve(address(tokens[i]), spender, maxAmount, maxExpiration);
        }
    }

    function _initPool(
        address poolToInit,
        uint256[] memory amountsIn,
        uint256 minBptOut
    ) internal override returns (uint256 bptOut) {
        
        IERC20[] memory tokens =  new IERC20[](2);
        if (address(linkedToken) > address(usdc)) {
            tokens[0] = IERC20(address(usdc));
            tokens[1] = IERC20(linkedTokenAddress);

        } else {
            tokens[1] = IERC20(address(usdc));
            tokens[0] = IERC20(linkedTokenAddress);
        }

        return router.initialize(poolToInit, tokens, amountsIn, minBptOut, false, bytes(""));
    }
}
