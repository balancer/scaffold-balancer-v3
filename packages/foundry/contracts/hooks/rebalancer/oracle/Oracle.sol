// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Ownable} from "@openzepplin/contracts/access/Ownable.sol";
import {IOracle,position} from "./interfaces/IOracle.sol";

contract Oracle is IOracle,Ownable {
    uint24 immutable public baseFee;
    address public oracle;

    event FeeUpdate(address indexed pool, uint24 fee); 
    event PositionUpdate(address indexed pool, PositionData); 

    error UnAuthorized();

    mapping (address => uint24) public dynamicFee;

    mapping (address => PositionData) public position;

    error NotOracle();

    modifier onlyOracle() {
        if(msg.sender != oracle) {
            revert UnAuthorized();
        }
        _;
    }

    constructor(uint24 _baseFee, address _oracle) Ownable(msg.sender) {
        baseFee = _baseFee;
        oracle = _oracle;
    }

    function setFee(address pool, uint24 fee) external override onlyOracle {
        dynamicFee[pool] = fee;
        emit FeeUpdate(pool, fee);
    }


    function setPositionData(address pool, uint24 _lowerTick, uint24 _upperTick) external override onlyOracle {
        position[pool] = PositionData(_lowerTick, _upperTick);
        emit PositionUpdate(pool, PositionData(_lowerTick, _upperTick));
    }
    
    function getFee(address pool) external view override returns (uint24) {
        return dynamicFee[pool];
    }

    function getPosition(address pool) external view override returns (PositionData memory) {
        return position[pool];
    }
}