// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;


import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

interface IOracle {
    function getDynamicFee() external view returns (uint256);
}

contract Oracle is IOracle, ChainlinkClient, ConfirmedOwner {

    uint256 private dynamicFee;

    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    address _ORACLE = 0xD2e4d744c5dECC4Dbb0994bFc220Fe059237A177;
    string _JOBID = "d2b1f3b3b3b94b3b9";

    event RequestFullfilled(
        bytes32 indexed requestId,
        uint256 _fee
    );

    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */

    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function requestDynamicFee(
        address _oracle,
        string memory _jobId
    ) public {
        Chainlink.Request memory req = _buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillPoolBalance.selector
        );
        string memory url = "http://ec2-15-206-127-108.ap-south-1.compute.amazonaws.com:3000";
        req._add(
            "get",
            url
        );  
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillPoolBalance(
        bytes32 requestId,
        bytes calldata data
    ) public recordChainlinkFulfillment(requestId) {
        (uint256 fee) = abi.decode(data, (uint256));
        dynamicFee = fee;
        emit RequestFullfilled(requestId, fee);
    }

    function getDynamicFee() external view returns (uint256) {
        return dynamicFee;
    }


    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}