// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IOracle,TokenData} from "./interfaces/IOracle.sol";

contract Oracle is IOracle {
    uint256 immutable public baseFee;
    address public oracle;

    event FeeUpdate(address indexed pool, uint256 fee); 
    event PositionUpdate(address indexed pool, TokenData); 

    error UnAuthorized();

    mapping (address => uint256) public dynamicFee;

    mapping(address => TokenData[]) public poolTokens;
    error NotOracle();

    modifier onlyOracle() {
        if(msg.sender != oracle) {
            revert UnAuthorized();
        }
        _;
    }

    constructor(uint256 _baseFee, address _oracle) {
        baseFee = _baseFee;
        oracle = _oracle;
    }

    function setFee(address pool, uint256 fee) external override  {
        dynamicFee[pool] = fee;
        emit FeeUpdate(pool, fee);
    }

    function setPoolTokensData(
        address pool,
        TokenData[] memory _tokensData
    ) external onlyOracle {
  
        TokenData[] storage poolRebalanceData = poolTokens[pool];

        if (poolRebalanceData.length > 0) {
            delete poolTokens[pool];
        }

        for (uint256 i = 0; i < _tokensData.length; i++) {
            poolRebalanceData.push(_tokensData[i]);
        }
    }

    function getFee(address pool) external view override returns (uint256) {
        return dynamicFee[pool];
    }

    function getPoolTokensData(address pool) external view override returns (TokenData[] memory){
        return poolTokens[pool];
    }

}