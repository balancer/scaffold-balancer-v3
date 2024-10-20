// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IOracle,TokenData} from "./interfaces/IOracle.sol";

abstract contract Oracle is IOracle {
    uint24 immutable public baseFee;
    address public oracle;

    event FeeUpdate(address indexed pool, uint24 fee); 
    event PositionUpdate(address indexed pool, TokenData); 

    error UnAuthorized();

    mapping (address => uint24) public dynamicFee;

    mapping(address => TokenData[]) public poolTokens;
    error NotOracle();

    modifier onlyOracle() {
        if(msg.sender != oracle) {
            revert UnAuthorized();
        }
        _;
    }

    constructor(uint24 _baseFee, address _oracle) {
        baseFee = _baseFee;
        oracle = _oracle;
    }

    function setFee(address pool, uint24 fee) external override onlyOracle {
        dynamicFee[pool] = fee;
        emit FeeUpdate(pool, fee);
    }

    function setPoolTokenData(
        address pool,
        uint i,
        uint256 latestRoundPrice,
        uint256 predictedPrice
    ) external override onlyOracle {
        TokenData[] storage tokensData = poolTokens[pool];
        tokensData[i].latestRoundPrice = latestRoundPrice;
        tokensData[i].predictedPrice = predictedPrice;
    }

    function getFee(address pool) external view override returns (uint24) {
        return dynamicFee[pool];
    }

    function getPoolTokensData(address pool) external view override returns (TokenData[] memory){
        return poolTokens[pool];
    }

}