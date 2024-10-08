// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-npm/access/Ownable.sol";
import "./ERC20Ownable.sol";

contract MockERC20Factory is Ownable {
	string public name;
	mapping(address => address[]) public tokensByOwner;
	address[] public allTokens;

	event TokenCreated(address indexed owner, address token);
	event TokenOwnershipUpdated(address indexed oldOwner, address indexed newOwner, address token);
	event TokenLocked(address indexed token);
	event TokenUnlocked(address indexed token);

	constructor(string memory _name) Ownable() {
		transferOwnership(msg.sender);
		name = _name;
	}

	function createToken(
		string memory name_,
		string memory symbol_,
		address tokenOwner_,
		address associatedNFT_,
		uint256 associatedNFTId_,
		address[] memory membersToFund,
		uint256[] memory amountsToFund
	) external virtual returns (address) {
		ERC20Ownable token = new ERC20Ownable(
			name_,
			symbol_,
			tokenOwner_,
			address(this),
			associatedNFT_,
			associatedNFTId_,
			membersToFund,
			amountsToFund
		);

		tokensByOwner[tokenOwner_].push(address(token));
		allTokens.push(address(token));

		emit TokenCreated(tokenOwner_, address(token));
		return address(token);
	}

	function getTokensByOwner(address owner) external view returns (address[] memory) {
		return tokensByOwner[owner];
	}

	function getAllTokens() external view returns (address[] memory) {
		return allTokens;
	}

	function updateTokenOwnership(address token, address newOwner) external onlyOwner {
		require(ERC20Ownable(token).factory() == address(this), "Invalid token");

		address oldOwner = ERC20Ownable(token).owner();
		ERC20Ownable(token).transferOwnership(newOwner);

		_updateOwnership(token, oldOwner, newOwner);
	}

	function lockToken(address token) external onlyOwner {
		require(ERC20Ownable(token).factory() == address(this), "Invalid token");
		ERC20Ownable(token).lock();
		emit TokenLocked(token);
	}

	function unlockToken(address token) external onlyOwner {
		require(ERC20Ownable(token).factory() == address(this), "Invalid token");
		ERC20Ownable(token).unlock();
		emit TokenUnlocked(token);
	}

	function notifyOwnershipChange(address oldOwner, address newOwner) external {
		require(ERC20Ownable(msg.sender).factory() == address(this), "Invalid caller");

		// Check if the token address exists in the allTokens array
		bool tokenExists = false;
		for (uint256 i = 0; i < allTokens.length; i++) {
			if (allTokens[i] == msg.sender) {
				tokenExists = true;
				break;
			}
		}

		// If the token address does not exist in the array, add it
		if (!tokenExists) {
			allTokens.push(msg.sender);
		}

		_updateOwnership(msg.sender, oldOwner, newOwner);
	}

	function _updateOwnership(address token, address oldOwner, address newOwner) internal {
		// Remove token from old owner
		address[] storage oldOwnerTokens = tokensByOwner[oldOwner];
		for (uint256 i = 0; i < oldOwnerTokens.length; i++) {
			if (oldOwnerTokens[i] == token) {
				oldOwnerTokens[i] = oldOwnerTokens[oldOwnerTokens.length - 1];
				oldOwnerTokens.pop();
				break;
			}
		}

		// Add token to new owner
		tokensByOwner[newOwner].push(token);

		emit TokenOwnershipUpdated(oldOwner, newOwner, token);
	}
}
