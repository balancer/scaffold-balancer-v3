// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockBalancerVault {
    uint256 private mockAmountOut;

    function setMockAmountOut(uint256 _amount) external {
        mockAmountOut = _amount;
    }

    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        for (uint i = 0; i < tokens.length; i++) {
            uint256 balanceBefore = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(recipient, amounts[i]);
            
            (bool success, ) = recipient.call(
                abi.encodeWithSignature(
                    "receiveFlashLoan(address[],uint256[],uint256[],bytes)",
                    tokens,
                    amounts,
                    new uint256[](tokens.length), // Mock fee amounts
                    userData
                )
            );
            require(success, "Flash loan callback failed");

            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
            require(balanceAfter >= balanceBefore, "Flash loan not repaid");
        }
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256) {
        require(block.timestamp <= deadline, "Deadline exceeded");
        require(mockAmountOut >= limit, "Limit not satisfied");

        IERC20(singleSwap.assetIn).transferFrom(funds.sender, address(this), singleSwap.amount);
        IERC20(singleSwap.assetOut).transfer(funds.recipient, mockAmountOut);

        return mockAmountOut;
    }
}

struct SingleSwap {
    bytes32 poolId;
    uint8 kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}