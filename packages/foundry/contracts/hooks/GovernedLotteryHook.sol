// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AfterSwapParams,
    LiquidityManagement,
    SwapKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { EnumerableMap } from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/EnumerableMap.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

contract GovernedLotteryHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.IERC20ToUint256Map;
    using SafeERC20 for IERC20;

    // Governance Proposal Struct
    struct Proposal {
        uint256 proposalId;
        string description;
        uint64 newSwapFeePercentage;
        uint8 newLuckyNumber;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
    }

    // State variables for proposals
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Lottery and fee variables
    uint8 public LUCKY_NUMBER = 10;
    uint8 public constant MAX_NUMBER = 20;
    uint64 public hookSwapFeePercentage;

    EnumerableMap.IERC20ToUint256Map private _tokensWithAccruedFees;
    uint256 private _counter = 0;
    address private immutable _trustedRouter;

    // Events for governance and fees
    event ProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalImplemented(uint256 proposalId, uint64 newSwapFeePercentage, uint8 newLuckyNumber);
    event LotteryWinningsPaid(
        address indexed hooksContract,
        address indexed winner,
        IERC20 indexed token,
        uint256 amountWon
    );

    constructor(IVault vault, address router) VaultGuard(vault) Ownable(msg.sender) {
        _trustedRouter = router;
    }

    // Create a new governance proposal
    function createProposal(
        string memory description,
        uint64 newSwapFeePercentage,
        uint8 newLuckyNumber
    ) external onlyOwner {
        proposals.push(
            Proposal({
                proposalId: proposals.length,
                description: description,
                newSwapFeePercentage: newSwapFeePercentage,
                newLuckyNumber: newLuckyNumber,
                votesFor: 0,
                votesAgainst: 0,
                votingDeadline: block.timestamp + 7 days
            })
        );

        emit ProposalCreated(proposals.length - 1, description);
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool support) external {
        require(block.timestamp <= proposals[proposalId].votingDeadline, "Voting period is over");
        require(!hasVoted[proposalId][msg.sender], "You have already voted");

        if (support) {
            proposals[proposalId].votesFor += 1;
        } else {
            proposals[proposalId].votesAgainst += 1;
        }

        hasVoted[proposalId][msg.sender] = true;
        emit VoteCast(proposalId, msg.sender, support);
    }

    // Implement the proposal if it has more votes for than against
    function implementProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            hookSwapFeePercentage = proposal.newSwapFeePercentage;
            LUCKY_NUMBER = proposal.newLuckyNumber;

            emit ProposalImplemented(proposalId, proposal.newSwapFeePercentage, proposal.newLuckyNumber);
        }
    }

    // Lottery logic (onAfterSwap remains unchanged for the most part)
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        uint8 drawnNumber;
        if (params.router == _trustedRouter) {
            drawnNumber = _getRandomNumber();
        }

        _counter++;

        hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;
        if (hookSwapFeePercentage > 0) {
            uint256 hookFee = params.amountCalculatedRaw.mulDown(hookSwapFeePercentage);
            if (params.kind == SwapKind.EXACT_IN) {
                uint256 feeToPay = _chargeFeeOrPayWinner(params.router, drawnNumber, params.tokenOut, hookFee);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw -= feeToPay;
                }
            } else {
                uint256 feeToPay = _chargeFeeOrPayWinner(params.router, drawnNumber, params.tokenIn, hookFee);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw += feeToPay;
                }
            }
        }
        return (true, hookAdjustedAmountCalculatedRaw);
    }

    // Function to set swap fee (can also be changed by governance)
    function setHookSwapFeePercentage(uint64 swapFeePercentage) external onlyOwner {
        hookSwapFeePercentage = swapFeePercentage;
    }

    // Pseudo-random number generation
    function _getRandomNumber() private view returns (uint8) {
        return uint8((uint(keccak256(abi.encodePacked(block.prevrandao, _counter))) % MAX_NUMBER) + 1);
    }

    // Lottery fee and reward logic
    function _chargeFeeOrPayWinner(
        address router,
        uint8 drawnNumber,
        IERC20 token,
        uint256 hookFee
    ) private returns (uint256) {
        if (drawnNumber == LUCKY_NUMBER) {
            address user = IRouterCommon(router).getSender();
            for (uint256 i = _tokensWithAccruedFees.length(); i > 0; i--) {
                (IERC20 feeToken, ) = _tokensWithAccruedFees.at(i - 1);
                _tokensWithAccruedFees.remove(feeToken);
                uint256 amountWon = feeToken.balanceOf(address(this));
                if (amountWon > 0) {
                    feeToken.safeTransfer(user, amountWon);
                    emit LotteryWinningsPaid(address(this), user, feeToken, amountWon);
                }
            }
            return 0;
        } else {
            _tokensWithAccruedFees.set(token, 1);
            if (hookFee > 0) {
                _vault.sendTo(token, address(this), hookFee);
            }
            return hookFee;
        }
    }

    function getHookFlags() public view virtual override returns (HookFlags memory) {}

    // SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AfterSwapParams,
    LiquidityManagement,
    SwapKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { EnumerableMap } from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/EnumerableMap.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

contract GovernedLotteryHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.IERC20ToUint256Map;
    using SafeERC20 for IERC20;

    // Governance Proposal Struct
    struct Proposal {
        uint256 proposalId;
        string description;
        uint64 newSwapFeePercentage;
        uint8 newLuckyNumber;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
    }

    // State variables for proposals
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Lottery and fee variables
    uint8 public LUCKY_NUMBER = 10;
    uint8 public constant MAX_NUMBER = 20;
    uint64 public hookSwapFeePercentage;

    EnumerableMap.IERC20ToUint256Map private _tokensWithAccruedFees;
    uint256 private _counter = 0;
    address private immutable _trustedRouter;

    // Events for governance and fees
    event ProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalImplemented(uint256 proposalId, uint64 newSwapFeePercentage, uint8 newLuckyNumber);
    event LotteryWinningsPaid(
        address indexed hooksContract,
        address indexed winner,
        IERC20 indexed token,
        uint256 amountWon
    );

    constructor(IVault vault, address router) VaultGuard(vault) Ownable(msg.sender) {
        _trustedRouter = router;
    }

    // Create a new governance proposal
    function createProposal(
        string memory description,
        uint64 newSwapFeePercentage,
        uint8 newLuckyNumber
    ) external onlyOwner {
        proposals.push(
            Proposal({
                proposalId: proposals.length,
                description: description,
                newSwapFeePercentage: newSwapFeePercentage,
                newLuckyNumber: newLuckyNumber,
                votesFor: 0,
                votesAgainst: 0,
                votingDeadline: block.timestamp + 7 days
            })
        );

        emit ProposalCreated(proposals.length - 1, description);
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool support) external {
        require(block.timestamp <= proposals[proposalId].votingDeadline, "Voting period is over");
        require(!hasVoted[proposalId][msg.sender], "You have already voted");

        if (support) {
            proposals[proposalId].votesFor += 1;
        } else {
            proposals[proposalId].votesAgainst += 1;
        }

        hasVoted[proposalId][msg.sender] = true;
        emit VoteCast(proposalId, msg.sender, support);
    }

    // Implement the proposal if it has more votes for than against
    function implementProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            hookSwapFeePercentage = proposal.newSwapFeePercentage;
            LUCKY_NUMBER = proposal.newLuckyNumber;

            emit ProposalImplemented(proposalId, proposal.newSwapFeePercentage, proposal.newLuckyNumber);
        }
    }

    // Lottery logic (onAfterSwap remains unchanged for the most part)
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        uint8 drawnNumber;
        if (params.router == _trustedRouter) {
            drawnNumber = _getRandomNumber();
        }

        _counter++;

        hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;
        if (hookSwapFeePercentage > 0) {
            uint256 hookFee = params.amountCalculatedRaw.mulDown(hookSwapFeePercentage);
            if (params.kind == SwapKind.EXACT_IN) {
                uint256 feeToPay = _chargeFeeOrPayWinner(params.router, drawnNumber, params.tokenOut, hookFee);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw -= feeToPay;
                }
            } else {
                uint256 feeToPay = _chargeFeeOrPayWinner(params.router, drawnNumber, params.tokenIn, hookFee);
                if (feeToPay > 0) {
                    hookAdjustedAmountCalculatedRaw += feeToPay;
                }
            }
        }
        return (true, hookAdjustedAmountCalculatedRaw);
    }

    // Function to set swap fee (can also be changed by governance)
    function setHookSwapFeePercentage(uint64 swapFeePercentage) external onlyOwner {
        hookSwapFeePercentage = swapFeePercentage;
    }

    // Pseudo-random number generation
    function _getRandomNumber() private view returns (uint8) {
        return uint8((uint(keccak256(abi.encodePacked(block.prevrandao, _counter))) % MAX_NUMBER) + 1);
    }

    // Lottery fee and reward logic
    function _chargeFeeOrPayWinner(
        address router,
        uint8 drawnNumber,
        IERC20 token,
        uint256 hookFee
    ) private returns (uint256) {
        if (drawnNumber == LUCKY_NUMBER) {
            address user = IRouterCommon(router).getSender();
            for (uint256 i = _tokensWithAccruedFees.length(); i > 0; i--) {
                (IERC20 feeToken, ) = _tokensWithAccruedFees.at(i - 1);
                _tokensWithAccruedFees.remove(feeToken);
                uint256 amountWon = feeToken.balanceOf(address(this));
                if (amountWon > 0) {
                    feeToken.safeTransfer(user, amountWon);
                    emit LotteryWinningsPaid(address(this), user, feeToken, amountWon);
                }
            }
            return 0;
        } else {
            _tokensWithAccruedFees.set(token, 1);
            if (hookFee > 0) {
                _vault.sendTo(token, address(this), hookFee);
            }
            return hookFee;
        }
    }

    function getHookFlags() public view virtual override returns (HookFlags memory) {}

    function getCurrentSettings() external view returns (uint64, uint8) {
        return (hookSwapFeePercentage, LUCKY_NUMBER);
    }
}

}

//this is contract
