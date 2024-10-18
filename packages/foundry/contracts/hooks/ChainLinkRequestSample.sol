// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {console} from "forge-std/console.sol";


contract ATestnetConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = (1 * LINK_DIVISIBILITY) / 10; // 0.1 * 10**18
    string public poolName;
    uint256 public balance;

    event RequestPoolNameFullfilled(
        bytes32 indexed requestId,
        string _name
    );

    event RequestBalanceFullfilled(
        bytes32 indexed requestId,
        uint256 _balance
    );

    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */
    constructor() ConfirmedOwner(msg.sender) {
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function requestPoolBalance(
        address _oracle,
        string memory _jobId
    ) public {
        Chainlink.Request memory req = _buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillPoolBalance.selector
        );
        string memory url = 'https://test-api-v3.balancer.fi/?query=query {poolGetPool(id:"0xEA34209c9c86b358Ebf9C92156aA8D12b81508B6", chain:SEPOLIA){poolTokens {balance}}}';
        req._add(
            "get",
            url
        );
        req._add("path", "data,poolGetPool,poolTokens,0,balance");
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillPoolBalance(
        bytes32 requestId,
       bytes calldata data
    ) public recordChainlinkFulfillment(requestId) {
        (uint256 bal) = abi.decode(data, (uint256));
        console.log("Balance found in fulfillPoolBalance: ", bal);
        emit RequestBalanceFullfilled(requestId, bal);
        balance = bal;
    }

    function requestPoolName(
        address _oracle,
        string memory _jobId
    ) public {
        Chainlink.Request memory req = _buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillPoolName.selector
        );
        string memory url = 'https://test-api-v3.balancer.fi/?query=query {poolGetPool(id:"0xEA34209c9c86b358Ebf9C92156aA8D12b81508B6", chain:SEPOLIA){name}}';
        req._add(
            "get",
            url
        );
        req._add("path", "data,poolGetPool,name");
        _sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    function fulfillPoolName(
        bytes32 requestId,
       bytes calldata data
    ) public recordChainlinkFulfillment(requestId) {
        (string memory name) = abi.decode(data, (string));
        emit RequestPoolNameFullfilled(requestId, name);
        poolName = name;
    }


    function getChainlinkToken() public view returns (address) {
        return _chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        _cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
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
