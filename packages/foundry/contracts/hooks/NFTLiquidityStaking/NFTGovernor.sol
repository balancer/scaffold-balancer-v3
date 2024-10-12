 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract NFTGovernor is Governor, GovernorCountingSimple, GovernorVotes {
    constructor(IVotes _token)
        Governor("NFTGovernor")
        GovernorVotes(_token)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1 days; 
    }

    function votingPeriod() public pure override returns (uint256) {
        return 1 weeks; 
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 1000e18; 
    }

      function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
       public
       override(Governor)
       returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }
}