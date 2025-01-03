pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    address public admin;

    // Mapping to track rewards for each user
    mapping(address => uint256) public userRewards;

    event RewardsDistributed(address indexed user, uint256 amount);

    constructor() ERC20("BadgeToken", "RWD") {
        admin = msg.sender; // Assign the contract deployer as admin
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // Function to mint rewards for a user
    function distributeRewards(address user, uint256 amount) external onlyAdmin {
        userRewards[user] += amount;
        _mint(user, amount); // Mint the specified amount of tokens
        emit RewardsDistributed(user, amount);
    }

    // Function to claim rewards
    function claimRewards() external {
        uint256 amount = userRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        
        userRewards[msg.sender] = 0; // Reset user rewards
        _mint(msg.sender, amount); // Mint the tokens to the user
    }
}
