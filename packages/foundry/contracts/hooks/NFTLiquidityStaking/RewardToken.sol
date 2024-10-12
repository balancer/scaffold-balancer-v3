
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    address public stakingHook;

    constructor(address _stakingHook) ERC20("Reward Token", "RWD") {
        stakingHook = _stakingHook;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == stakingHook, "Only staking hook can mint");
        _mint(to, amount);
    }
}
