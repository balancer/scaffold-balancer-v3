// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-npm/token/ERC20/ERC20.sol";
import "@openzeppelin-npm/access/Ownable.sol";
import "@openzeppelin-npm/security/Pausable.sol";
import "./MockERC20Factory.sol";

contract ERC20Ownable is ERC20, Ownable, Pausable {
	address public factory;
	address public linkedNFT;
	uint256 public linkedNFTId;
	string public status;
	bool public locked = false;

	// Add state variables for name and symbol
	string private _customName;
	string private _customSymbol;

	event Locked();
	event Unlocked();
	event NFTDataUpdated(address indexed newAddress, uint256 id);
	event TokensMinted(address indexed to, uint256 amount);
	event TokensBurned(address indexed from, uint256 amount);
	event NameChanged(string newName);
	event SymbolChanged(string newSymbol);
	event StatusChanged(string newStatus);

	modifier notLocked() {
		require(!locked, "Contract is locked");
		_;
	}

	constructor(
		string memory name_,
		string memory symbol_,
		address owner_,
		address factory_,
		address linkedNFT_,
		uint256 linkedNFTId_,
		address[] memory membersToFund,
		uint256[] memory amountsToFund
	) ERC20(name_, symbol_) Ownable() {
		transferOwnership(owner_);
		require(membersToFund.length == amountsToFund.length, "Mismatched input lengths");
		status = "active";
		factory = factory_;
		linkedNFT = linkedNFT_;
		linkedNFTId = linkedNFTId_;
		_customName = name_;
		_customSymbol = symbol_;

		for (uint256 i = 0; i < membersToFund.length; i++) {
			_mint(membersToFund[i], amountsToFund[i]);
		}
	}

	// Override name and symbol functions to return the custom values
	function name() public view virtual override returns (string memory) {
		return _customName;
	}

	function symbol() public view virtual override returns (string memory) {
		return _customSymbol;
	}

	function mint(address to, uint256 amount) external onlyOwner notLocked whenNotPaused {
		_mint(to, amount);
		emit TokensMinted(to, amount);
	}

	function burn(address from, uint256 amount) external onlyOwner notLocked whenNotPaused {
		_burn(from, amount);
		emit TokensBurned(from, amount);
	}

	function updateNFTData(address linkedNFT_, uint256 linkedNFTId_) external onlyOwner notLocked whenNotPaused {
		linkedNFT = linkedNFT_;
		linkedNFTId = linkedNFTId_;
		emit NFTDataUpdated(linkedNFT_, linkedNFTId_);
	}

	function changeStatus(string memory newStatus) external onlyOwner notLocked whenNotPaused {
		status = newStatus;
		emit StatusChanged(newStatus);
	}

	function changeName(string memory newName) external onlyOwner notLocked whenNotPaused {
		_customName = newName;
		emit NameChanged(newName);
	}

	function changeSymbol(string memory newSymbol) external onlyOwner notLocked whenNotPaused {
		_customSymbol = newSymbol;
		emit SymbolChanged(newSymbol);
	}

	function lock() external {
		require(msg.sender == factory || msg.sender == owner(), "Only factory or owner can lock");
		locked = true;
		emit Locked();
	}

	function unlock() external {
		require(msg.sender == factory, "Only factory can unlock");
		locked = false;
		emit Unlocked();
	}

	function _transferOwnership(address newOwner) internal override {
		address oldOwner = owner();
		super._transferOwnership(newOwner);
		// Check if the factory address is defined and not an empty address
		if (factory != address(0)) {
			MockERC20Factory(factory).notifyOwnershipChange(oldOwner, newOwner);
		}
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}
