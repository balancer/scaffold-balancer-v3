//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MockLPRewardToken is ERC20,Ownable{
    uint256 private _totalPointSupply;
    mapping(address => uint256) private LPRewardPoints;

    address public HOOK_ADDRESS;

    error TransferNotAllowed();

    // Mint the initial supply to the deployer
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender){
    }

    modifier onlyHook
    { 
        require(HOOK_ADDRESS == msg.sender); 
        _; 
    }

    function updateHookAddress(address _hook) external onlyOwner{
        HOOK_ADDRESS = _hook;
    }

    // Allow any user to mint any amount of tokens to their wallet
    function mint(address sender,uint256 amount) external onlyHook {
        LPRewardPoints[sender] += amount;
        _totalPointSupply += amount;
    }

    /**
     * @notice Retrieves the number of decimals for the Eduxp points.
     * @dev This function is an override of the ERC20 function, so that we can pass the 0 value.
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * @notice Retrieves the total supply of Eduxp points.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalPointSupply;
    }

    /**
     * @notice Retrieves the Eduxp points balance of an account.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     * @param account The account to retrieve the EDUXP points balance of
     * @return The EDUXP points balance of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return LPRewardPoints[account];
    }

    /**
     * @notice The override of the transfer method to prevent the EDUXP token from being transferred.
     * @dev This function will always revert as we don't allow EDUXP transfers.
     * @param recipient The recipient of the EDUXP points
     * @param amount The amount of EDUXP points to transfer
     * @return A boolean indicating if the transfer was successful
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        revert TransferNotAllowed();
    }

    /**
     * @notice The override of the transferFrom method to prevent the EDUXP token from being transferred.
     * @dev This function will always revert as we don't allow EDUXP transfers.
     * @param sender The sender of the EDUXP points
     * @param recipient The recipient of the EDUXP points
     * @param amount The amount of EDUXP points to transfer
     * @return A boolean indicating if the transfer was successful
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        revert TransferNotAllowed();
    }
}
