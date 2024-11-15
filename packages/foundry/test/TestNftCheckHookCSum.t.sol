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

import { NftCheckHook } from "../contracts/hooks/NftCheckHook.sol";
import { MockNft } from "../contracts/mocks/MockNft.sol";
import { MockLinked } from "../contracts/mocks/MockLinked.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import { InitializationConfig } from "../script/PoolHelpers.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";


contract TestNftCheckHookCSum is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal linkedTokenIdx;
    uint256 internal usdcIdx;

    address payable internal hookOwner;
    uint256 internal hookOwnerKey;
    address payable internal randomUser;
    uint256 internal randomUserKey;

    MockNft mockNft;
    uint256 tokenId;
    address nftCheckHook;
    bool nftIsDeposited;
    MockLinked linkedToken;
    bool linkedTokenIsMinted;
    address linkedTokenAddress;

    uint256 constant OWNER_LINKED_TOKEN_INITIAL_BALANCE = 1e3*1e18;
    uint256 constant OWNER_USDC_INITIAL_BALANCE = 1e3*1e18;
    uint256 constant RANDOM_USER_USDC_INITIAL_BALANCE = 100*1e18;
    uint256 constant POOL_INITIAL_AMOUNT = 50e18;
    // random user swap amount in
    uint256 constant USDC_SWAP_AMOUNT_IN = 40e18;
    uint256 constant SETTLEMENT_FEE = 10e16;


    modifier transferNFT_approveBPT_initializePool() {
        // Transfer NFT, approve bpt transfer to hook and initialize pool
        vm.startPrank(hookOwner);
        mockNft.transferFrom(hookOwner, nftCheckHook, 0);
        PoolMock(pool).approve(nftCheckHook, type(uint256).max);
        initPool();
        vm.stopPrank();
        // Owner has no BPT
        assertEq(PoolMock(pool).balanceOf(hookOwner), 0, "hookOwner has BPT");
        _;
    }

    function setUp() public override {
        address hookOwnerP;
        (hookOwnerP, hookOwnerKey) = makeAddrAndKey("hookOwner");
        hookOwner = payable(hookOwnerP);
        address randomUserP;
        (randomUserP, randomUserKey) = makeAddrAndKey("randomUser");
        randomUser = payable(randomUserP);

        mintNft();

        super.setUp();
        poolInitAmount = POOL_INITIAL_AMOUNT; // overriding
        poolHooksContract = nftCheckHook; // overriding
        usdc.mint(hookOwner, OWNER_USDC_INITIAL_BALANCE);
        usdc.mint(randomUser, RANDOM_USER_USDC_INITIAL_BALANCE);

        linkedTokenAddress = NftCheckHook(nftCheckHook).getLinkedToken(); // get linked token address
        linkedToken = MockLinked(linkedTokenAddress); // linked token
        tokens.push(ERC20TestToken(linkedTokenAddress)); // push linked token to tokens as ERC20TestToken
        linkedTokenIsMinted = true; // to enable the pool creation
        (linkedTokenIdx, usdcIdx) = getSortedIndexes(address(linkedToken), address(usdc));

        pool = createPool();
        vaultConvertFactor = vault.getConvertFactor();

        // Grants hookOwner the ability to change the static swap fee percentage.
        authorizer.grantRole(vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector), hookOwner);
    }

    ////////////////////////////////////////
    // Tests ///////////////////////////////
    ////////////////////////////////////////

    function testInitialBalances() public {
        /// Owner
        // Owner has an NFT
        assertEq(mockNft.balanceOf(hookOwner) > 0, true, "hookOwner does not have an NFT");
        // Hook expects the mockNft NFT
        assertEq(address(mockNft), NftCheckHook(nftCheckHook).getNftContract());
        // Owner balances
        uint256 hookOwnerLinkedBalance = linkedToken.balanceOf(hookOwner);
        assertEq(hookOwnerLinkedBalance, OWNER_LINKED_TOKEN_INITIAL_BALANCE, "hookOwner wrong liniked tokens balance");
        uint256 hookOwnerUsdcBalance = usdc.balanceOf(hookOwner);
        assertEq(hookOwnerUsdcBalance, OWNER_USDC_INITIAL_BALANCE, "hookOwner wrong usdc tokens balance");
        // Owner has no BPT
        assertEq(PoolMock(pool).balanceOf(hookOwner), 0);

        /// RandomUser
        uint256 randomUserLinkedBalance = linkedToken.balanceOf(randomUser);
        assertEq(randomUserLinkedBalance, 0, "RandomUser has some linked tokens");
        uint256 randomUserUsdcBalance = usdc.balanceOf(randomUser);
        assertEq(randomUserUsdcBalance, RANDOM_USER_USDC_INITIAL_BALANCE, "RandomUser wrong usdc tokens balance");
    }

    function testSwapFeeZero() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 0; // 0%
        _userSwapsOwnerSettlesUserRedeemsUserSwapsWithRevert(swapFeePercentage);
    }

    function testSwapFeeTen() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 10e16; // 10%
        vm.prank(hookOwner);
        vault.setStaticSwapFeePercentage(pool, swapFeePercentage);
       _userSwapsOwnerSettlesUserRedeemsUserSwapsWithRevert(swapFeePercentage);
    }

    function testSwapFeeTwentyFive() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 25e16; // 25%
        vm.prank(hookOwner);
        vault.setStaticSwapFeePercentage(pool, swapFeePercentage);
        _userSwapsOwnerSettlesUserRedeemsUserSwapsWithRevert(swapFeePercentage);
    }

    function testOwnerCanRemoveLiquidityAfterSettlement() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 0;
        console.log("BPT amount of hook: ", IERC20(pool).balanceOf(nftCheckHook));
        _userSwapsOwnerSettlesUserRedeemsUserSwapsWithRevert(swapFeePercentage);

        uint256 bptAmount = IERC20(pool).balanceOf(hookOwner);
        // for some reason the bpt amount is slightly different than 2*POOL_INITIAL_AMOUNT, TODO
        assertEq(bptAmount, 99999999999999000000, "Wrong bpt amount");
        _ownerRemovesLiquidityProportional(bptAmount, false);
    }

    function testRugPulling() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 0; // 0%

        // random user swaps usdc for linked token
        uint256 expectedLinkedTokenOut = _firstUserSwaps(swapFeePercentage);

        // Owner removes liquidity but has no bpt
        uint256 bptAmount = IERC20(pool).balanceOf(hookOwner);
        assertEq(bptAmount, 0, "Wrong bpt amount");
        // true means it reverts
        _ownerRemovesLiquidityProportional(POOL_INITIAL_AMOUNT/10, true);
    }

    // amount of linked tokens in the pool = 2 * amount of usdc in the pool 
    function testRedeemRationWhenStablePoolRatioIsBig() public transferNFT_approveBPT_initializePool {
        uint256 swapFeePercentage = 0; // 0%

        // random user swaps 40e18 usdc for 40e18 linked token
        uint256 expectedLinkedTokenOut = _firstUserSwaps(swapFeePercentage);
        // pool 10e18/90e18 linked/usdc

        // Owner adds 170e18 linked tokens
        uint256 linkedAmountIn = 170e18;
        uint256[] memory amountsToAdd = linkedTokenIdx == 0 ? 
            [linkedAmountIn, uint256(0)].toMemoryArray() : [uint256(0), linkedAmountIn].toMemoryArray();
        _ownerAddsLiquidity(amountsToAdd);
        // pool 180e18/90e18 linked/usdc so linked/usdc rato is 2

        uint256 stableAmountRequired = NftCheckHook(nftCheckHook).getSettlementAmount();

        // user has 40 linked tokens so stableAmountRequired = 40e18 * 2 = 80e18
        uint256 expectedStableAmountRequired = 80e18;
        assertEq(stableAmountRequired, expectedStableAmountRequired, "Wrong stableAmountRequired");
    }

    ////////////////////////////////////////
    // Helpers /////////////////////////////
    ////////////////////////////////////////

    function mintNft() internal {
        vm.prank(hookOwner);
        mockNft = new MockNft("NFTFactory", "NFTF");
        vm.prank(hookOwner);
        tokenId = mockNft.mintNft("https://0a050602b1c1aeae1063a0c8f5a7cdac.ipfscdn.io/ipfs/QmSiA82PQNuWuBfQtuzWKwnZV94qs34jrW1L6PaR69jeoE/metadata.json");
    }

    function createHook() internal override returns (address) {
        // hookOwner will be the owner of the hook
        vm.prank(hookOwner);
        nftCheckHook = address(
            new NftCheckHook(
                vault,
                address(mockNft),
                tokenId,
                address(usdc),
                "RWA Token",
                "RWAT",
                OWNER_LINKED_TOKEN_INITIAL_BALANCE,
                SETTLEMENT_FEE
            )
        );
        vm.label(nftCheckHook, "Nft Check Hook");
        return nftCheckHook;
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

    function initPool() internal override {
        if (mockNft.ownerOf(tokenId) == nftCheckHook) {
            vm.startPrank(hookOwner);
            usdc.approve(address(permit2), type(uint256 ).max);
            linkedToken.approve(address(permit2), type(uint256 ).max);
            permit2.approve(address(linkedToken), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(usdc), address(router), type(uint160).max, type(uint48).max);
            _initPool(pool, [poolInitAmount, poolInitAmount].toMemoryArray(), 0);
            vm.stopPrank();
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

    // user and owner actions

    function _swap(address user, IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn, bool reverts) internal {
        vm.startPrank(user);
        // permissions
        usdc.approve(address(permit2), type(uint256 ).max);
        linkedToken.approve(address(permit2), type(uint256 ).max);
        permit2.approve(address(usdc), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(linkedToken), address(router), type(uint160).max, type(uint48).max);
        // expect revert?
        if (reverts) {
            vm.expectRevert();
        }
        RouterMock(router).swapSingleTokenExactIn(
            pool,
            tokenIn,
            tokenOut,
            amountIn,
            0,
            MAX_UINT256,
            false,
            bytes("")
        );
        vm.stopPrank();
    }

    function _firstUserSwaps(uint256 _swapFeePercentage) internal returns (uint256 expectedLinkedTokenOut) {
        _swap(randomUser, usdc, IERC20(linkedTokenAddress), USDC_SWAP_AMOUNT_IN, false);
        uint256 expectedPoolFee = USDC_SWAP_AMOUNT_IN * _swapFeePercentage / 1e18;
        expectedLinkedTokenOut = USDC_SWAP_AMOUNT_IN - expectedPoolFee;
        assertEq(usdc.balanceOf(randomUser), RANDOM_USER_USDC_INITIAL_BALANCE - USDC_SWAP_AMOUNT_IN, "RandomUser wrong usdc tokens balance");
        assertEq(linkedToken.balanceOf(randomUser), expectedLinkedTokenOut, "RandomUser has some linked tokens");
    }

    function _ownerSettlesPool() internal {
        // hook owner settles pool
        vm.startPrank(hookOwner);
        usdc.approve(nftCheckHook, type(uint256).max);
        NftCheckHook(nftCheckHook).settle();
        vm.stopPrank();
    }

    function _userRedeemsAfterFirstSwapAndOwnerSettlement(uint256 expectedLinkedTokenOut) internal {
        // random user redeems
        vm.startPrank(randomUser);
        linkedToken.approve(nftCheckHook, type(uint256).max);
        NftCheckHook(nftCheckHook).redeem();
        vm.stopPrank();
        uint256 settlementAmount = (expectedLinkedTokenOut * (1 ether + SETTLEMENT_FEE)) / 1 ether;
        assertEq(usdc.balanceOf(hookOwner), OWNER_USDC_INITIAL_BALANCE - POOL_INITIAL_AMOUNT - settlementAmount, 'hookOwner wrong usdc balance');
        assertEq(linkedToken.balanceOf(hookOwner), OWNER_LINKED_TOKEN_INITIAL_BALANCE - POOL_INITIAL_AMOUNT + expectedLinkedTokenOut, 'hookOwner wrong linked token balance');
        assertEq(usdc.balanceOf(randomUser), RANDOM_USER_USDC_INITIAL_BALANCE - USDC_SWAP_AMOUNT_IN + settlementAmount, 'randomUser wrong usdc balance');
        assertEq(linkedToken.balanceOf(randomUser), 0, 'randomuser wrong linked token balance');
    }

    function _userSwapsOwnerSettlesUserRedeemsUserSwapsWithRevert(uint256 _swapFeePercentage) internal {
        // random user swaps usdc for linked token
        uint256 expectedLinkedTokenOut = _firstUserSwaps(_swapFeePercentage);

        // Owner settles pool
        _ownerSettlesPool();

        // random user redeems
        _userRedeemsAfterFirstSwapAndOwnerSettlement(expectedLinkedTokenOut);

        // random user swap reverts because pool is settled
        _swap(randomUser, usdc, IERC20(linkedTokenAddress), USDC_SWAP_AMOUNT_IN, true);
    }

    function _ownerRemovesLiquidityProportional(uint256 amountOut, bool reverts) internal {
        vm.startPrank(hookOwner);
        IERC20(pool).approve(address(router), type(uint256).max);
        
        if (reverts) vm.expectRevert();
        router.removeLiquidityProportional(pool, amountOut, [uint256(0),uint256(0)].toMemoryArray(), false, bytes(""));
        vm.stopPrank();
    }

    function _ownerAddsLiquidity(uint256[] memory exactAmountsIn) internal {
        vm.prank(hookOwner);
        router.addLiquidityUnbalanced(
            pool,
            exactAmountsIn,
            0,
            false,
            bytes("")
        );
    }
}
