// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";

import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {
    TokenConfig,
    LiquidityManagement,
    HookFlags,
    AddLiquidityKind,
    RemoveLiquidityKind,
    AddLiquidityParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { MinimalRouter } from "./MinimalRouter.sol";
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/// @notice Based on NftLiquidityPositionExample.
contract Quid is MinimalRouter, ERC20, BaseHooks, Ownable {
    using FixedPoint for uint256;

    // This contract uses timestamps to update its withdrawal fee over time.
    //solhint-disable not-rely-on-time

    // Initial fee of 10%.
    uint256 public constant INITIAL_FEE_PERCENTAGE = 10e16;
    uint256 public constant ONE_PERCENT = 1e16;
    // After this number of days the fee will be 0%.
    uint256 public constant DECAY_PERIOD_DAYS = 10;

    address public WETH;
    address public DAI;
    uint internal FEE = WAD / 28; 
    uint constant WAD = 1e18;

    // `tokenId` uniquely identifies the NFT minted upon deposit.
    mapping(uint256 tokenId => uint256 bptAmount) public bptAmount;
    mapping(uint256 tokenId => uint256 timestamp) public startTime;
    mapping(uint256 tokenId => address pool) public nftPool;

    struct FoldState { uint delta; uint price;
        uint average_price; uint average_value;
        uint deductible; uint cap; uint minting;
        bool liquidate; uint repay; uint collat; 
    }
    uint public _PRICE;
    uint public START;  
    // "Walked in the 
    // kitchen, found a 
    // [Pod] to [Piscine]" ~ tune chi
    Pod[44][16] Piscine; // 16 batches
    // 44th day stores batch's total
    uint constant PENNY = 1e16;
    uint constant DIME = 10 * WAD;
    uint constant public DAYS = 43 days; 
    uint public START_PRICE = 50 * PENNY;
    // https://www.law.cornell.edu/wex/consideration
    mapping(address => uint[16]) public consideration;
    // of legally sufficient value, bargained-for in 
    // an exchange agreement, for the breach of which
    // Moulinette gives an equitable remedy, and whose 
    // performance is recognised as reasonable duty or
    // tender (an unconditional offer to perform)...
    uint constant public MAX_PER_DAY = 777_777 * WAD;
    uint[90] public WEIGHTS; // sum of weights... 
    mapping (address => bool[16]) public hasVoted;
    // when a token-holder votes for a fee, their
    // QD balance is applied to the total weights
    // for that fee (weights are the balances)...
    // index 0 is the largest possible vote = 9%
    // index 89 represents the smallest one = 1%
    uint public deployed; uint internal K = 17;
    uint public SUM_FEE; // sum(weights[0...k]):
    mapping (address => uint) public feeVotes;
    address[][16] public voters; // by batch
    // continuous payment from Balancer LP fees
    // with a fixed charge (deductible) payable 
    // upfront (upon deposit), 1/2 on withdrawal
    // deducted as a % FEE from the $ value which
    // is either being deposited or moved in fold
    struct Pod { // for pledge.weth this amounts to
        uint credit; // sum[amt x price at deposit]
        uint debit; //  quantity of tokens pledged 
    } /* quid.credit = contribution to weighted...
    ...SUM of (QD / total QD) x (ROI / avg ROI) */
    uint public SUM = 1; uint public AVG_ROI = 1; 
    // formal contracts require a specific method of 
    // formation to be enforaceable; one example is
    // negotiable instruments like promissory notes 
    // an Offer is a promise or commitment to do
    // or refrain from doing something specific
    // in the future...our case is bilateral...
    // promise for a promise, aka quid pro quo...
    struct Offer { Pod weth; Pod carry; Pod work;
    // Pod last; } // timestamp of last liquidate & 
    // % that's been liquidated (smaller over time)
    uint last; } // TODO (after testing finished)
    // work is like a checking account (credit can
    // be drawn against it) while weth is savings,
    // but it pays interest to the contract itself;
    // together, and only if used in combination,
    // they form an insured revolving credit line;
    // carry is relevant for redemption purposes.
    // fold() holds depositors accountable for 
    // work as well as accountability for weth
    // recall 3rd Delphic maxim
    mapping (address => Offer) pledges;
    mapping (uint => address) owners; // tokenId => owner
    // NFT unique identifier. (not strictly necessary)
    uint256 private _nextTokenId;

    /**
     * @notice A new `NftLiquidityPositionExample` contract has been registered successfully for a given pool.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param pool The pool on which the hook was registered
     */
    event NftLiquidityPositionExampleRegistered(address indexed hooksContract, address indexed pool);

    /**
     * @notice A user has added liquidity to an associated pool, and received an NFT.
     * @param nftHolder The user who added liquidity to earn the NFT
     * @param pool The pool that received the liquidity
     * @param nftId The id of the newly minted NFT
     */
    event LiquidityPositionNftMinted(address indexed nftHolder, address indexed pool, uint256 nftId);

    /**
     * @notice A user has added liquidity to an associated pool, and received an NFT.
     * @param nftHolder The NFT holder who withdrew liquidity in exchange for the NFT
     * @param pool The pool from which the NFT holder withdrew liquidity
     * @param nftId The id of the NFT that was burned
     */
    event LiquidityPositionNftBurned(address indexed nftHolder, address indexed pool, uint256 nftId);

    /**
     * @notice An NFT holder withdrew liquidity during the decay period, incurring an exit fee.
     * @param nftHolder The NFT holder who withdrew liquidity in exchange for the NFT
     * @param pool The pool from which the NFT holder withdrew liquidity
     * @param feeToken The address of the token in which the fee was charged
     * @param feeAmount The amount of the fee, in native token decimals
     */
    event ExitFeeCharged(address indexed nftHolder, address indexed pool, IERC20 indexed feeToken, uint256 feeAmount);

    /**
     * @notice Hooks functions called from an external router.
     * @dev This contract inherits both `MinimalRouter` and `BaseHooks`, and functions as is its own router.
     * @param router The address of the router
     */
    error CannotUseExternalRouter(address router);

    /**
     * @notice The pool does not support adding liquidity through donation.
     * @dev There is an existing similar error (IVaultErrors.DoesNotSupportDonation), but hooks should not throw
     * "Vault" errors.
     */
    error PoolDoesNotSupportDonation();

    /**
     * @notice The pool supports adding unbalanced liquidity.
     * @dev There is an existing similar error (IVaultErrors.DoesNotSupportUnbalancedLiquidity), but hooks should not
     * throw "Vault" errors.
     */
    error PoolSupportsUnbalancedLiquidity();

    /**
     * @notice Attempted withdrawal of an NFT-associated position by an address that is not the owner.
     * @param withdrawer The address attempting to withdraw
     * @param owner The owner of the associated NFT
     * @param nftId The id of the NFT
     */
    error WithdrawalByNonOwner(address withdrawer, address owner, uint256 nftId);

    modifier onlySelfRouter(address router) {
        _ensureSelfRouter(router);
        _;
    }
    modifier postLaunch { 
        require(currentBatch() > 0, "after");  
        _; 
    }
    function restart() external onlyOwner { 
        if (START != 0) { uint batch = currentBatch();
            Pod memory day = Piscine[batch - 1][43];  
            AVG_ROI += FixedPoint.mulDivUp(WAD, 
            day.credit - day.debit, day.debit) / (DAYS / 1 days);
            
            AVG_ROI /= batch;
            require(block.timestamp > START + DAYS &&
                    currentBatch() < 17, "can't restart");
        }   
        START = block.timestamp;            
    }

    constructor(
        IVault vault,
        IWETH weth,
        address dai,
        IPermit2 permit2
    ) MinimalRouter(vault, weth, permit2) ERC20("BalancerLiquidityProvider", "BAL_LP") Ownable(msg.sender) {
        // solhint-disable-previous-line no-empty-blocks
        WETH = address(weth); deployed = block.timestamp;
        DAI = dai;
    }

    function dollar_amt_to_qd_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FixedPoint.mulDivUp(amt, 100 + (100 - cap), 100) : amt; 
    } 
    function qd_amt_to_dollar_amt(uint cap, uint amt) 
        public view returns (uint) { return (cap < 100) ? 
        FixedPoint.mulDivUp(amt, cap, 100) : amt;
    }
    
    function _max(uint128 _a, uint128 _b) 
        internal pure returns (uint128) {
        return (_a > _b) ? _a : _b;
    }
    function _min(uint _a, uint _b) 
        internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _minAmount(address from, address token, 
        uint amount) internal view returns (uint) {
        amount = _min(amount, IERC20(token).balanceOf(from));
        require(amount > 0, "0 balance"); 
        if (token != address(this)) {
            amount = _min(amount, IERC20(token).allowance(from, address(this)));
            require(amount > 0, "0 allowance"); 
        }
        return amount;
    }

    /***************************************************************************
                                  Token Functions
    ***************************************************************************/

    function transfer(address to, uint value) 
        public override(ERC20) returns (bool) {
        _transferHelper(msg.sender, to, value); return true;      
    }
    function transferFrom(address from, address to, uint value) 
        public override(ERC20) returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transferHelper(from, to, value); return true;
    }

    // ETH can only be withdrawn from
    // pledge.work.debit; if ETH was 
    // deposited pledge.weth.debit,
    // call fold() before withdraw()
    // amount is in units of QD...
    function withdraw(uint amount) 
        external payable { uint price = getPrice(false); 
        Offer memory pledge = pledges[msg.sender];
        require(amount >= DIME, "too small");
        if (msg.value > 0) { 
            IWETH(WETH).deposit{ value: msg.value }();
            pledges[address(this)].work.credit += 
            msg.value; pledge.work.debit += msg.value;
            // TODO provide single-sided liquidity !!
        }   uint debit = FixedPoint.mulDivUp(price, 
                            pledge.work.debit, WAD);
        uint buffered = debit - (debit / 5);
        require(buffered >= pledge.work.credit, "CR");
        amount = _min(amount, 
        buffered - pledge.work.credit);
        if (amount > 0) { 
            pledge.work.credit += amount;
            amount = dollar_amt_to_qd_amt(
            capitalisation(amount, false), amount); 
            consideration[msg.sender][currentBatch()] += amount;
            _mint(msg.sender, amount);
        }   
        pledges[msg.sender] = pledge;
    }

    function deposit(uint amount) external { // QD amount
        Offer memory pledge = pledges[msg.sender];
        amount = _minAmount(msg.sender, address(this), amount);
        uint cap = capitalisation(amount, true);
        amount = _min(qd_amt_to_dollar_amt(cap, 
        amount), pledge.work.credit); 
        pledge.work.credit -= amount;
        cap = capitalisation(amount, true); 
        _transferHelper(
           msg.sender, address(0), dollar_amt_to_qd_amt(cap, amount)); 
           // burn shouldn't affect carry.debit values of `from` or `to`
        pledges[msg.sender] = pledge;
    }

    function vote(uint new_vote) external 
        postLaunch { uint batch = currentBatch();
        if (batch < 16 && !hasVoted[msg.sender][batch]) {
            hasVoted[msg.sender][batch] = true;
            voters[batch].push(msg.sender);
        }
        uint old_vote = feeVotes[msg.sender];
        require(new_vote != old_vote &&
                new_vote < 89, "bad vote");
        feeVotes[msg.sender] = new_vote;
        uint stake = balanceOf(msg.sender);
        _calculateMedian(stake, new_vote, 
                         stake, old_vote);
    }

    function currentBatch() public view returns (uint batch) {
        batch = (block.timestamp - deployed) / DAYS;
        // for last 8 batches to be redeemable, batch reaches 24
        require(batch < 25, "42"); 
    }
    function matureBatches() 
        public view returns (uint) {
        uint batch = currentBatch(); 
        if (batch < 8) { return 0; }
        else if (batch < 25) {
            return batch - 8;
        } else { return 16; }
        // over 16 would result
        // in index out of bounds
        // in matureBalanceOf()...
    }
    function matureBalanceOf(address account)
        public view returns (uint total) {
        uint batches = matureBatches();
        for (uint i = 0; i < batches; i++) {
            total += consideration[account][i];
        }
    }

    function mint(uint amount, address beneficiary, address token) 
        external returns (uint cost) { uint batch = currentBatch();
        require (token == DAI, "discounted QD only mintable agaisnt DAI");
        Offer memory pledge = pledges[beneficiary];
        if (block.timestamp <= START + DAYS && batch < 16) {
            consideration[beneficiary][batch] += amount;
            // TODO parlay carry.credit burning QD... 
            uint in_days = ((block.timestamp - START) / 1 days);
            require(amount >= 10 * WAD, "mint more QD");
            Pod memory total = Piscine[batch][43];
            Pod memory day = Piscine[batch][in_days]; 
            uint supply_cap = (in_days + 1) * MAX_PER_DAY; 
            require(total.credit + amount < supply_cap, "cap"); 
            // Yesterday's price is NOT today's price,
            // and when I think I'm running low, you're 
            uint price = in_days * PENNY + START_PRICE;
            cost = _minAmount(beneficiary, token, // DAI...
                FixedPoint.mulDivUp(price, amount, WAD)
            ); // _minAmount returns less than expected
            // we calculate amount twice because maybe
            amount = FixedPoint.mulDivUp(WAD, cost, price); 
            consideration[beneficiary][batch] += amount;
            _mint(beneficiary, amount); // totalSupply++
            day.credit += amount; day.debit += cost;
            total.credit += amount; total.debit += cost;
            Piscine[batch][in_days] = day;
            Piscine[batch][43] = total;  
            IERC20(token).transferFrom( // TODO safeTransferFrom
                beneficiary, address(this), cost
            );  pledges[address(this)].carry.debit += cost;
            // ^needed for tracking total capitalisation
            pledge.carry.debit += cost; // contingent
            // variable for ROI as well as redemption,
            // carry.credit gets reset in _creditHelper
            pledges[beneficiary] = pledge; // save changes
            _creditHelper(beneficiary);
        } // TODO stake the DAI into sDAI
    }

    // call in QD's worth (обнал sans liabilities)
    // calculates the coverage absorption for each 
    // insurer by first determining their share %
    // and then adjusting based on average ROI...
    // (insurers w/ higher avg. ROI absorb more) 
    // "you never count your money while you're
    // sittin' at the table...there'll be time
    // enough for countin'...when,"
    function redeem(uint amount) 
        external returns (uint absorb) {
        amount = _min(matureBalanceOf(msg.sender),
        amount); // % share over the overall balance
        uint share = FixedPoint.mulDivUp(WAD, amount, 
                        balanceOf(msg.sender));
        Offer storage pledge = pledges[msg.sender]; 
        uint coverage = pledges[address(this)].carry.credit; 
        // maximum $ that pledge would absorb
        // if they redeemed all their QD...
        absorb = FixedPoint.mulDivUp(coverage, 
            FixedPoint.mulDivUp(WAD, 
            pledge.carry.credit, SUM), WAD  
        );  
        // if not 100% of the mature QD is
        if (WAD > share) { // being redeemed
            absorb = FixedPoint.mulDivUp(absorb, 
                                    share, WAD);
        }
        _transferHelper(msg.sender, address(0), amount);
        amount = qd_amt_to_dollar_amt(
            capitalisation(0, false),
            amount
        );  
        if (amount > absorb) {  amount -= absorb; 
            // remainder is $ value to be released 
            // after accounting for liabilities...
            uint third = 3 * amount / 10; // $
            // 70% of amount from carry.debit...
            require(IERC20(DAI).balanceOf(
                address(this)) >= (amount - third), 
                "not enough"
            ); IERC20(DAI).transfer(msg.sender, amount - third);
            // convert 1/3 of amount into USDC precision...
            uint usdc = _min(third / 1e12,
            pledges[address(this)].work.debit);
            
            bool sell = third > (pledges[address(this)].work.debit * 1e12);
            if (sell) { amount = FixedPoint.mulDivUp(WAD,
                (third - (usdc * 1e12)), getPrice(false));
            
                amount = _min(amount, 
                pledges[address(this)].weth.debit);
                pledges[address(this)].work.debit = 0;
                pledges[address(this)].weth.debit -= amount;
            } else { amount = 0; // ETH being sent out...
                pledges[address(this)].work.debit -= usdc; 
            }
            // TODO withdrawLiquidity from pool (amount ETH & USDC) to send out 
            pledges[address(this)].carry.credit -= absorb;
        } 
        else {
            pledges[address(this)].carry.credit -= amount;
            // else the entire amount being redeemed
            // is consumed by absorbing protocol debt
        }
        // TODO save pledges[msg.sender] = pledge
        // after subtracting from pledge.carry.credit
    } 


    /***************************************************************************
                                  Router Functions
    ***************************************************************************/

    function addLiquidityProportional(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender returns (uint256[] memory amountsIn) {
        Offer memory pledge = pledges[msg.sender];
        uint price = getPrice(false); // insuring the $ value...
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        require(tokens.length == maxAmountsIn.length, "must match");
        // Charge fees proportional to the `amountOut` of each token.
        for (uint256 i = 0; i < maxAmountsIn.length; i++) {
            if (address(tokens[i]) == WETH) { uint amount = maxAmountsIn[i];
                uint in_dollars = FixedPoint.mulDivUp(price, amount, WAD);
                uint deductible = FixedPoint.mulDivUp(in_dollars, FEE, WAD);
                in_dollars -= deductible; 
                // change deductible to be in units of ETH instead
                deductible = FixedPoint.mulDivUp(WAD, deductible, price);
                uint insured = amount - deductible; // in ETH
                pledge.weth.debit += insured; // withdrawable
                // by folding balance into pledge.work.debit...
                pledges[address(this)].weth.debit += deductible;
                pledges[address(this)].weth.credit += insured;
                pledge.weth.credit += in_dollars;
                in_dollars = FixedPoint.mulDivUp(price, 
                    pledges[address(this)].weth.credit, WAD
                );  require(pledges[address(this)].carry.debit
                            > in_dollars, "insuring too much"); 
                            break;
            }
        }
        // Do addLiquidity operation - BPT is minted to this contract.
        amountsIn = _addLiquidityProportional(
            pool,
            msg.sender,
            address(this),
            maxAmountsIn,
            exactBptAmountOut,
            wethIsEth,
            userData
        );
        uint256 tokenId = _nextTokenId++;
        // Store the initial liquidity amount associated with the NFT.
        bptAmount[tokenId] = exactBptAmountOut;
        // Store the initial start time associated with the NFT.
        startTime[tokenId] = block.timestamp;
        // Store the pool/bpt address associated with the NFT.
        nftPool[tokenId] = pool;
        // Mint the associated NFT to sender.
        // _safeMint(msg.sender, tokenId);
        owners[tokenId] = msg.sender;
        pledges[msg.sender] = pledge; // save changes

        emit LiquidityPositionNftMinted(msg.sender, pool, tokenId);
    }

    function removeLiquidityProportional(
        uint256 tokenId,
        uint256[] memory minAmountsOut,
        bool wethIsEth
    ) external payable saveSender returns 
        (uint256[] memory amountsOut) {
        // Ensure the user owns the NFT.
        address nftOwner = ownerOf(tokenId);

        if (nftOwner != msg.sender) {
            revert WithdrawalByNonOwner(msg.sender, nftOwner, tokenId);
        }

        address pool = nftPool[tokenId];

        // Do removeLiquidity operation - tokens sent to msg.sender.
        amountsOut = _removeLiquidityProportional(
            pool,
            address(this),
            msg.sender,
            bptAmount[tokenId],
            minAmountsOut,
            wethIsEth,
            abi.encode(tokenId) // tokenId is passed to index fee data in hook
        );

        // Set all associated NFT data to 0.
        bptAmount[tokenId] = 0;
        startTime[tokenId] = 0;
        nftPool[tokenId] = address(0);
        // Burn the NFT
        // _burn(tokenId);

        emit LiquidityPositionNftBurned(msg.sender, pool, tokenId);
    }

    /***************************************************************************
                                  Hook Functions
    ***************************************************************************/

    /// @inheritdoc BaseHooks
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        // This hook requires donation support to work (see above).
        if (liquidityManagement.enableDonation == false) {
            revert PoolDoesNotSupportDonation();
        }
        if (liquidityManagement.disableUnbalancedLiquidity == false) {
            revert PoolSupportsUnbalancedLiquidity();
        }

        emit NftLiquidityPositionExampleRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc BaseHooks
    function getHookFlags() public pure override 
        returns (HookFlags memory) {
        HookFlags memory hookFlags;
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallBeforeAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        return hookFlags;
    }

    /// @inheritdoc BaseHooks
    function onBeforeAddLiquidity(
        address router,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256,
        uint256[] memory,
        bytes memory
    ) public view override onlySelfRouter(router) returns (bool) {
        // We only allow addLiquidity via the Router/Hook itself (as it must custody BPT).
        return true;
    }

    /// @inheritdoc BaseHooks
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory userData
    ) public override onlySelfRouter(router) 
        returns (bool, uint256[] memory hookAdjustedAmountsOutRaw) {
        // We only allow removeLiquidity via the Router/Hook itself so that fee is applied correctly.
        uint256 tokenId = abi.decode(userData, (uint256));
        hookAdjustedAmountsOutRaw = amountsOutRaw;
        uint256 currentFee = getCurrentFeePercentage(tokenId);
        address beneficiary = IRouterCommon(router).getSender();
        if (currentFee > 0) {
            hookAdjustedAmountsOutRaw = _takeFee(beneficiary, pool, amountsOutRaw, currentFee);
        }
        return (true, hookAdjustedAmountsOutRaw);
    }

    // "Entropy" comes from a Greek word for transformation; 
    // Clausius interpreted as the magnitude of the degree 
    // to which Pods be separate from each other: "so close
    // no matter how far...rage be in it like you couldn’t
    // believe, or work like I could've scarcely imagined;
    // if one isn’t satisfied, indulge the latter, ‘neath 
    // the halo of a street-lamp, I turn my straddle to
    // the cold and damp...know when to hold 'em...know 
    // when to..." 
     function fold(address beneficiary, // amount is...
        uint amount, bool sell) external { // in ETH...
        FoldState memory state; state.price = getPrice(false);
        // call in collateral that's insured, or liquidate;
        // if there is an insured event, QD may be minted,
        // or simply clear the debt of a long position...
        // "we can serve our [wick nest] or we can serve
        // our purpose, but not both" ~ Mother Cabrini
        Offer memory pledge = pledges[beneficiary];
        amount = _min(amount, pledge.weth.debit);
        require(amount > 0, "amount too low");
        state.cap = capitalisation(0, false);
        if (pledge.work.credit > 0) {
            state.collat = FixedPoint.mulDivUp(
                state.price, pledge.work.debit, WAD
            );  // "lookin' too hot; simmer down"
            if (pledge.work.credit > state.collat) {
                state.repay = pledge.work.credit - state.collat; 
                state.repay += state.collat / 10;
                state.liquidate = true; // not final (can be saved)
            } else { // for using claimed coverage to payoff debt...
                state.delta = state.collat - pledge.work.credit;
                if (state.collat / 10 > state.delta) {
                    state.repay = (state.collat / 10) - state.delta;
                }
            }   
        } if (amount > 0) { // claim ETH amount that's been insured
            state.collat = FixedPoint.mulDivUp(amount, state.price, WAD);
            state.average_price = FixedPoint.mulDivUp(WAD, 
                pledge.weth.credit, pledge.weth.debit
            ); // ^^^^^^^^^^^^^^^^ must be in dollars
            state.average_value = FixedPoint.mulDivUp( 
                amount, state.average_price, WAD
            ); // if price drop > 10% (average_value > 10% more than current value) 
            if (state.average_price >= FixedPoint.mulDivUp(110, state.price, 100)) { 
                state.delta = state.average_value - state.collat;
                if (!sell) { state.minting = state.delta;  
                    state.deductible = FixedPoint.mulDivUp(WAD, 
                        FixedPoint.mulDivUp(state.collat, FEE, WAD), 
                        state.price
                    ); // the sell method ensures that
                    // ETH will always be bought at dips
                    // so it's practical for the protocol
                    // to hold on to it (prices will rise)
                } else if (!state.liquidate) {
                    // if liquidate = true it
                    // will be a sale anyway...
                    state.deductible = amount;  
                    state.minting = state.collat - 
                        FixedPoint.mulDivUp( // deducted
                            state.collat, FEE, WAD
                        );
                } if (state.repay > 0) { // capitalise into credit
                    state.cap = _min(state.minting, state.repay);
                    // ^^^^^^ variable being reused for space...
                    pledge.work.credit -= state.cap; 
                    state.minting -= state.cap; 
                    state.repay -= state.cap; 
                }
                pledges[address(this)].work.credit += amount;
                // we need to increment before calling capitalisation
                // in order for the ratio to be calculated correctly
                    state.cap = capitalisation(state.delta, false); 
                if (state.minting > state.delta || state.cap > 57) { 
                // minting will equal delta unless it's a sell, and if it's not,
                // we can't mint coverage if the protocol is under-capitalised...
                    state.minting = dollar_amt_to_qd_amt(state.cap, state.minting);
                    consideration[beneficiary][currentBatch()] += state.minting;
                    _mint(beneficiary, state.minting); 
                    pledges[address(this)].carry.credit += state.delta; 
                } else { state.deductible = 0; } // no mint = no charge  
                pledges[address(this)].weth.credit -= amount;
                // amount is no longer insured by the protocol
                pledge.weth.debit -= amount; // deduct amount
                pledge.weth.credit -= state.average_value;
                // if we were to deduct actual value instead
                // that could be taken advantage of (increased
                // payouts with each subsequent call to fold)... 
                pledge.work.debit += amount - state.deductible;
                // if sell true, pledge doesn't get any ETH back
                pledges[address(this)].work.credit -= state.deductible;
                pledges[address(this)].weth.debit += state.deductible;
                
                state.collat = FixedPoint.mulDivUp(pledge.work.debit, state.price, WAD);
                if (state.collat > pledge.work.credit) { state.liquidate = false; }
            } 
        } // "things have gotten closer to the sun, and I've done 
        // things in small doses, so don't think that I'm pushing 
        // you away...when you're...amount: the state repayment...
        if (state.liquidate && ( // the one that I've kept closest"
            block.timestamp - pledge.last/*.credit*/ > 1 hours)) {  
            state.cap = capitalisation(state.repay, true);
            amount = _min(dollar_amt_to_qd_amt(state.cap, 
                state.repay), balanceOf(beneficiary)
            );  
            _transferHelper(beneficiary, address(0), amount);
            amount = qd_amt_to_dollar_amt(state.cap, amount);
            // subtract the $ value of QD
            pledge.work.credit -= amount;
            // "lightnin' ⚡️ strikes and the 🏀 court lights...
            if (pledge.work.credit > state.collat) { // get dim"
                if (pledge.work.credit > DIME) { // assumes that 
                // liquidation bot will not skip opportunities...
                    amount = pledge.work.debit / 727; 
                    pledge.work.debit -= amount; 
                    pledges[address(this)].weth.debit += amount; 
                    amount = _min(pledge.work.credit, 
                        FixedPoint.mulDivUp(state.price, 
                                            amount, WAD)
                    ); // "It's like inch by inch, and step by 
                    // step, I'm closin' in on your position
                    // and [eviction] is my mission..."
                    // Euler’s disk 💿 erasure code
                    pledge.work.credit -= amount; 
                    pledge.last/*.credit*/ = block.timestamp;
                    // pledge.last.debit = // TODO
                } else { // "it don't get no better than this, you catch my [dust]"
                    // otherwise we run into a vacuum leak (infinite contraction)
                    pledges[address(this)].weth.debit += pledge.work.debit;
                    pledges[address(this)].carry.credit += pledge.work.credit;
                    // debt surplus absorbed ^^^^^^^^^ as if it were coverage
                    pledge.work.credit = 0; pledge.work.debit = 0; // reset
                }   
            }
        }   pledges[beneficiary] = pledge;
    }


    /***************************************************************************
                                Off-chain Getters
    ***************************************************************************/

     // present value of the expected cash flows...
    function capitalisation(uint qd, bool burn) 
        public view returns (uint) { // ^ extra in QD
        uint price = getPrice(false); // $ value of ETH
        // earned from deductibles and Uniswap fees
        Offer memory pledge = pledges[address(this)];
        uint collateral = FixedPoint.mulDivUp(price,
            pledge.work.credit, WAD // in $
        ); // collected in deposit and fold...
        uint deductibles = FixedPoint.mulDivUp(price,
            pledge.weth.debit, WAD // in $
        ); // composition of insurance capital:
        uint assets = collateral + deductibles + 
            // USDC (upscaled for precision)...
            (pledge.work.debit * 1e12) + // DAI...
             pledge.carry.debit; // not incl. yield
        // doesn't account for pledge.weth.credit,
        // which are liabilities (that are insured)
        uint total = totalSupply(); 
        if (qd > 0) { total = (burn) ? 
            total - qd : total + qd;
        }
        return FixedPoint.mulDivUp(100, assets, total); 
    } 

    function ownerOf(uint tokenId) view public returns (address) {
        return owners[tokenId];
    }

    function get_info(address who) view
        external returns (uint, uint) {
        Offer memory pledge = pledges[who];
        return (pledge.carry.debit, balanceOf(who));
        // never need pledge.carry.credit in the frontend,
        // this is more of an internal tracking variable...
    }
    function get_more_info(address who) view
        external returns (uint, uint, uint, uint) { 
        Offer memory pledge = pledges[who];
        return (pledge.work.debit, pledge.work.credit, 
                pledge.weth.debit, pledge.weth.credit);
        // for address(this), this ^^^^^^^^^^^^^^^^^^
        // is ETH amount (that we're insuring), and
        // for depositors it's the $ value insured
    }

    function getPrice(bool fetch) 
        public view returns (uint price) {
        AggregatorV3Interface chainlink; // the following address is ETH<>USD on Sepolia
        if (fetch) { 
            chainlink = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
            (, int priceAnswer,, uint timeStamp,) = chainlink.latestRoundData();
            price = uint(priceAnswer);
            require(timeStamp > 0 
                && timeStamp <= block.timestamp 
                && priceAnswer >= 0, "price");
            uint8 answerDigits = chainlink.decimals();
            // Aggregator returns an 8-digit precision, 
            // but we handle the case of future changes
            if (answerDigits > 18) { price /= 10 ** (answerDigits - 18); }
            else if (answerDigits < 18) { price *= 10 ** (18 - answerDigits); } 
        }   else { return _PRICE; }  
    }

    function setPrice(uint price) 
        external onlyOwner {
        _PRICE = price;
    }

    /**
     * @notice Get the instantaneous value of the fee at the current block.
     * @param tokenId The fee token
     * @return feePercentage The current fee percentage
     */
    function getCurrentFeePercentage(uint256 tokenId) public view returns (uint256 feePercentage) {
        // Calculate the number of days that have passed since startTime
        uint256 daysPassed = (block.timestamp - startTime[tokenId]) / 1 days;
        if (daysPassed < DECAY_PERIOD_DAYS) { // decreasing fee by 1% per day
            feePercentage = INITIAL_FEE_PERCENTAGE - ONE_PERCENT * daysPassed;
        }
    }

    /***************************************************************************
                                Internal Functions
    ***************************************************************************/

    // helpers allow treating QD balances
    // uniquely without needing ERC721...
    function _transferHelper(address from, 
        address to, uint amount) internal {
            if (to != address(0)) { // not burning
                // percentage of carry.debit gets 
                // transferred over in proportion 
                // to amount's % of total balance
                // determine % of total balance
                // transferred for ROI pro rata
                uint ratio = FixedPoint.mulDivUp(WAD, 
                    amount, balanceOf(from));
                // proportionally transfer debit...
                uint debit = FixedPoint.mulDivUp(ratio, 
                pledges[from].carry.debit, WAD);
                pledges[to].carry.debit += debit;  
                pledges[from].carry.debit -= debit;
                // pledge.carry.credit in helper...
                // QD minted in coverage claims or 
                // over-collateralisation does not 
                // transfer over carry.credit b/c
                // carry credit only gets created
                // in the discounted mint windows
                _creditHelper(to); 
            }   _creditHelper(from); 
            uint balance_from = balanceOf(from); 
            uint balance_to = balanceOf(to); 
            uint from_vote = feeVotes[from];
            uint to_vote = feeVotes[to];
            amount = _min(amount, balanceOf(from));
            require(amount > WAD, "insufficient QD"); 
            int i; // must be int otherwise tx reverts
            // when we go below 0 in the while loop...
            if (to == address(0)) {
                i = int(matureBatches()); 
                _burn(from, amount);
                // no _calculateMedian `to`
            } else { i = int(currentBatch()); 
                _transfer(from, to, amount);
                _calculateMedian(balance_to, to_vote, 
                           balanceOf(to), to_vote);
            }   // loop from newest to oldest batch
            // until requested amount fulfilled...
            while (amount > 0 && i >= 0) { uint k = uint(i);    
                uint amt = consideration[from][k];
                if (amt > 0) { amt = _min(amount, amt);
                    consideration[from][k] -= amt;
                    // `to` may be address(0) but it's 
                    // irrelevant, wastes a bit of gas
                    consideration[to][k] += amt; 
                    amount -= amt;
                }   i -= 1;
            }   require(amount == 0, "transfer");
            _calculateMedian(balance_from, from_vote, 
                        balanceOf(from), from_vote);
    }

    function _creditHelper(address who) // QD holder 
        internal { // until batch 1 we have no AVG_ROI
        if (currentBatch() > 0) { // to work with
            uint credit = pledges[who].carry.credit;
            SUM -= credit; // subtract old share, which
            // may be zero if this is the first time 
            // _creditHelper is called for `who`...
            uint balance = balanceOf(who);
            uint debit = pledges[who].carry.debit;
            uint share = FixedPoint.mulDivUp(WAD, 
                         balance, totalSupply());
            credit = share;
            if (debit > 0) { // share is product
                // projected ROI if QD is $1...
                uint roi = FixedPoint.mulDivUp(WAD, 
                        balance - debit, debit);
                // calculate individual ROI over total 
                roi = FixedPoint.mulDivUp(WAD, roi, AVG_ROI);
                credit = FixedPoint.mulDivUp(roi, share, WAD);
                // credit is the product (composite) of 
                // two separate share (ratio) quantities 
                // and the sum of products is what we use
                // in determining pro rata in redeem()...
            }   pledges[who].carry.credit = credit;
            SUM += credit; // update sum with new share
        }
    }

    /** https://x.com/QuidMint/status/1833820062714601782
     *  Find value of k in range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) = sum(Weights[k:len(Weights)+1]) = sum(Weights) / 2
     *  If there is no such value of k, there must be a value of k 
     *  in the same range range(0, len(Weights)) such that 
     *  sum(Weights[0:k]) > sum(Weights) / 2
     */ 
    function _calculateMedian(uint new_stake, uint new_vote, 
        uint old_stake, uint old_vote) internal postLaunch { 
        // TODO emit events to make sure this works properly
        if (old_vote != 17 && old_stake != 0) { 
            WEIGHTS[old_vote] -= old_stake;
            if (old_vote <= K) {   
                SUM_FEE -= old_stake;
            }
        }   if (new_stake != 0) {
                if (new_vote <= K) {
                    SUM_FEE += new_stake;
                }         
                WEIGHTS[new_vote] += new_stake;
        } uint mid = totalSupply() / 2; 
        if (mid != 0) {
            if (K > new_vote) {
                while (K >= 1 && (
                    (SUM_FEE - WEIGHTS[K]) >= mid
                )) { SUM_FEE -= WEIGHTS[K]; K -= 1; }
            } else { 
                while (SUM_FEE < mid) { 
                    K += 1; SUM_FEE += WEIGHTS[K];
                }
            } FEE = WAD / (K + 11);
        }  else { SUM_FEE = 0; } // reset
    }

    function _takeFee(
        address nftHolder,
        address pool,
        uint256[] memory amountsOutRaw,
        uint256 currentFee
    ) private returns (uint256[] memory hookAdjustedAmountsOutRaw) {
        uint price = getPrice(false);
        Offer memory pledge = pledges[nftHolder]; 
        hookAdjustedAmountsOutRaw = amountsOutRaw;
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256[] memory accruedFees = new uint256[](tokens.length);
        // Charge fees proportional to the `amountOut` of each token.
        for (uint256 i = 0; i < amountsOutRaw.length; i++) {
            if (address(tokens[i]) == WETH) {
                uint withdrawable; // uint of ETH...
                if (pledge.work.credit > 0) {
                    uint debit = FixedPoint.mulDivUp(price, 
                        pledge.work.debit, WAD
                    ); uint buffered = debit - debit / 5;
                    require(buffered >= pledge.work.credit, "CR!");
                    withdrawable = FixedPoint.mulDivUp(WAD, 
                    buffered - pledge.work.credit, price); 
                }   uint transferring = hookAdjustedAmountsOutRaw[i];
                if (transferring > withdrawable) {
                    withdrawable = FixedPoint.mulDivUp(
                        WAD, pledge.work.credit, price 
                    ); pledge.work.credit = 0; // clear
                    pledge.work.debit -= withdrawable;
                    pledges[address(this)].weth.debit += // sell ETH
                    withdrawable; // to clear work.credit of pledge          
                    transferring = _min(hookAdjustedAmountsOutRaw[i], pledge.work.debit);  
                }   pledges[address(this)].work.credit -= transferring;
                hookAdjustedAmountsOutRaw[i] = transferring;
            }
            uint256 exitFee = hookAdjustedAmountsOutRaw[i].mulDown(currentFee);
            accruedFees[i] = exitFee; hookAdjustedAmountsOutRaw[i] -= exitFee;
            // Fees don't need to be transferred to the hook, because donation will redeposit them in the vault.
            // In effect, we will transfer a reduced amount of tokensOut to the caller, and leave the remainder
            // in the pool balance.
            emit ExitFeeCharged(nftHolder, pool, tokens[i], exitFee);
        }
        pledges[nftHolder] = pledge;
        // Donates accrued fees back to LPs.
        _vault.addLiquidity(
            AddLiquidityParams({
                pool: pool,
                to: msg.sender, // It would mint BPTs to router, but it's a donation so no BPT is minted
                maxAmountsIn: accruedFees, // Donate all accrued fees back to the pool (i.e. to the LPs)
                minBptAmountOut: 0, // Donation does not return BPTs, any number above 0 will revert
                kind: AddLiquidityKind.DONATION,
                userData: bytes("") // User data is not used by donation, so we can set it to an empty string
            })
        );
    }

    function _ensureSelfRouter(address router) private view {
        if (router != address(this)) {
            revert CannotUseExternalRouter(router);
        }
    }
}
