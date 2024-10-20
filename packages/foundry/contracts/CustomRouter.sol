// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IVaultExtension } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import { FixedPointMathLib } from "permit2/lib/solmate/src/utils/FixedPointMathLib.sol";

import {console} from "forge-std/console.sol";

import "./NFTUserId.sol";



import { MinimalRouter } from "./MinimalRouter.sol";
/// @title Custom Router
/// @notice This contract provides Limit Order Price Based functionality for a custom router 
/// @dev This is an abstract contract that should be inherited and implemented
contract OrderBook  {
    struct OrderArgs  {
        uint256 amountIn;
        uint256 maxExecutionTime;
        uint256 minExecutionPrice;
        uint256 maxExecutionPrice;
        address tokenIn;
        address tokenOut;
    }

    struct PositionData {
        address owner;
        uint256 executionTime;
        bool isActive;
        OrderArgs args;
    }

    // to fill up
    struct ExecutionData {
        address tokenX;
        address tokenY;
        uint256 totalAmountInTokenX;
        uint256 totalAmountInTokenY;
        uint256 totalAmountOutTokenX;
        uint256 totalAmountOutTokenY;
        uint256[] orderIds;
    }


    IVaultExtension private immutable assignedVault;

    MinimalRouter private immutable assignedRouter; 

    uint256 private constant MAX_ORDER_AT_PRICEPOINT = 10; 

    uint256 private _nextOrderId = 1;

    uint256 private _nextExectoorId = 1;

    uint256 private lastExectuionPriceXY = 0;

    uint256 private lastExectuionPriceYX = 0;

    uint256 private lastBlockNumber;

    uint256[] private inTransitCurrentPrices;

    // uint256[] private pricePoints;

    NFTUserIdentification public immutable executoorBadge;

    NFTUserIdentification public immutable orderPositionToken;

    bool private isExecutingLock;

    

    mapping(uint256 => uint256[]) public minPricePoint2OrderIds;
    mapping(uint256 => uint256[]) public maxPricePoint2OrderIds;


    mapping(uint256 => PositionData) public orderId2PositionData;

    mapping( uint256 => ExecutionData) public executionTime2ExecData;

    constructor(
        address vault,
        address payable router,
        string memory executoorTokenName,
        string memory executoorTokenSymbol,
        string memory orderPositionTokenName,
        string memory orderPositionTokenSymbol
    )  {
        assignedVault = IVaultExtension(vault);
        assignedRouter = MinimalRouter(router);
        executoorBadge = new NFTUserIdentification(address(this), executoorTokenName, executoorTokenSymbol);
        orderPositionToken = new NFTUserIdentification(address(this), orderPositionTokenName, orderPositionTokenSymbol);
        lastBlockNumber = block.number;
        console.log(address(assignedVault));
    }

    function executoorRegisterWithRouter() external {
        executoorBadge.safeMint(msg.sender, _nextExectoorId);

        _nextExectoorId += 1;
    }

    function placeLimitOrder(
        uint256 _amountIn, 
        uint256 _maxExecutionTIme, 
        uint256 _minTokenInExecutionPrice, 
        uint256 _maxTokenInExecutionPrice, 
        address _tokenIn, 
        address _tokenOut
        ) external returns (uint256 orderId) {
            require(
                _maxExecutionTIme > block.timestamp, 
                "BLOCK TIME STAMP < MAX EXECUTION TIME"
                );

            orderId = _nextOrderId;

            _createLimitOrder(OrderArgs({
                amountIn: _amountIn,
                maxExecutionTime: _maxExecutionTIme,
                minExecutionPrice: _minTokenInExecutionPrice,
                maxExecutionPrice: _maxTokenInExecutionPrice,
                tokenIn: _tokenIn,
                tokenOut: _tokenOut
            }));

            orderPositionToken.safeMint(msg.sender, orderId);

            _nextOrderId += 1;

             return orderId;
    }

    function _createLimitOrder(OrderArgs memory orderArgs) internal {
        require(
            IERC20(orderArgs.tokenIn).transferFrom(msg.sender, address(this), orderArgs.amountIn), 
            "Token Amount Transfer Failed"
            );

        orderId2PositionData[_nextOrderId] = PositionData({
            args: orderArgs,
            owner: msg.sender,
            isActive: true,
            executionTime: 0
        });

        minPricePoint2OrderIds[orderArgs.minExecutionPrice].push(_nextOrderId);

        maxPricePoint2OrderIds[orderArgs.maxExecutionPrice].push(_nextOrderId);
    }

    // called by beforeSwapHook
    function executeOrder(address pool, address executoor) external returns (bool) {
         if (executoorBadge.balanceOf(executoor) == 0) {
            return true;
        }
       
        require(address(assignedRouter) == msg.sender, "Execute order: Caller not authorized");
        
        require(block.number > lastBlockNumber, "Execute order: Same block execution not allowed");
       
        if (isExecutingLock) {
            return false;
        }

        isExecutingLock = true;

        (
            uint256 tokenRateXY, uint256 tokenRateYX, address tokenX, address tokenY
        ) = getTokenRatesXYYX(pool);

        uint256[] memory pricePoints2Check = getPricePointsToCheck(tokenRateXY, tokenRateYX);

        (
            ExecutionData memory executionData, uint256 executionTimestamp
        ) = prepareExecutionData(pricePoints2Check, tokenRateXY, tokenRateYX, tokenX, tokenY);

        if (executionData.orderIds.length == 0) {
            return true;
        }

        uint256 expAmount = (tokenRateYX - 20e18);

        bytes memory data = abi.encodeWithSelector(
            MinimalRouter.swapSingleTokenExactInMod.selector, 
            pool,
            IERC20(tokenX), 
            IERC20(tokenY), 
            executionData.totalAmountInTokenX, 
            expAmount, 
            FixedPointMathLib.MAX_UINT256, 
            false, 
            bytes("")
        );
        console.log(address(tokenX));
        IERC20(tokenX).approve(address(0x000000000022D473030F116dDEE9F6B43aC78BA3), executionData.totalAmountInTokenX * 5);
        // IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3).approve(tokenX, address(assignedVault), type(uint160).max, type(uint48).max);
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3).approve(tokenX, address(assignedRouter), type(uint160).max, type(uint48).max);
        console.log("address of contract b4 delegate call", address(this));
        console.log("address of router b4 delegate call", address(assignedRouter));
        // (bool success, ) = address(assignedRouter).delegatecall(data);

//         // 3190369403016232278795
//         // 3199979550818106973514
// console.log(address(this));
        // assignedRouter.swapSingleTokenExactInMod(pool, IERC20(tokenX), IERC20(tokenY), 1000000000000000000, expAmount, FixedPointMathLib.MAX_UINT256, false, bytes(""));
//     // struct ExecutionData {
//     //     address tokenX;
//     //     address tokenY;
//     //     uint256 totalAmountInTokenX;
//     //     uint256 totalAmountInTokenY;
//     //     uint256 totalAmountOutTokenX;
//     //     uint256 totalAmountOutTokenY;
//     //     uint256[] orderIds;
//     // }
//         // TODO: Implement order execution logic here
//         // This could involve:
        
//         // 2. Executing swaps for each valid order
//         // 3. Updating order states and balances

//         // Example:
//         // uint256[] memory ordersToExecute = getRelevantOrders(tokenRateXY, tokenRateYX);
//         // for (uint256 i = 0; i < ordersToExecute.length; i++) {
//         //     executeSwapForOrder(ordersToExecute[i], tokenX, tokenY, tokenRateXY, tokenRateYX);
//         // }

//         lastBlockNumber = block.number;
//         lastExectuionPriceXY = tokenRateXY;
//         lastExectuionPriceYX = tokenRateYX;

//         // emit OrderExecuted(pool, executoor, tokenRateXY, tokenRateYX);
            return true;
    }

    function getTokenRatesXYYX(address pool) internal view returns (uint256 tokenRateXY, uint256 tokenRateYX, address tokenX, address tokenY) {
        IERC20[] memory tokens = assignedVault.getPoolTokens(pool);
        
        require(tokens.length >= 2, "Execute order: Pool must have at least 2 tokens");

        uint256 tokenXidx = 0;
        uint256 tokenYidx = 1;
        tokenX = address(tokens[tokenXidx]);
        tokenY = address(tokens[tokenYidx]);

        tokenRateXY = assignedRouter.queryTokenRateXY(pool, tokenXidx, tokenYidx);
        tokenRateYX = assignedRouter.queryTokenRateXY(pool, tokenYidx, tokenXidx);

        require(tokenRateXY > 0, "Execute order: Invalid token rate XY");
        require(tokenRateYX > 0, "Execute order: Invalid token rate YX");

        return (tokenRateXY, tokenRateYX, tokenX, tokenY);
    }

    function getPricePointsToCheck(uint256 currentRateXY, uint256 currentRateYX) private view returns (uint256[] memory)  {
        bool isInitialExecution = lastExectuionPriceXY == 0 && lastExectuionPriceYX == 0;

        uint256 pricePointsBetweenXY = isInitialExecution ? 0 : (currentRateXY > lastExectuionPriceXY) 
            ? currentRateXY - lastExectuionPriceXY 
            : lastExectuionPriceXY - currentRateXY;
        uint256 pricePointsBetweenYX = isInitialExecution ? 0 : (currentRateYX > lastExectuionPriceYX) 
            ? currentRateYX - lastExectuionPriceYX 
            : lastExectuionPriceYX - currentRateYX;

        uint256[] memory allPricePoints = new uint256[](
            2 + inTransitCurrentPrices.length + pricePointsBetweenXY + pricePointsBetweenYX + (isInitialExecution ? 0 : 2)
        );

        uint256 idx = 0; 

        allPricePoints[idx++] = currentRateXY;
        allPricePoints[idx++] = currentRateYX;

        for (uint256 i = 0; i < inTransitCurrentPrices.length; i++) {
            allPricePoints[idx++] = inTransitCurrentPrices[i];
        }

        if (!isInitialExecution) {
            allPricePoints[idx++] = lastExectuionPriceXY;
            allPricePoints[idx++] = lastExectuionPriceYX;
        }

        if (!isInitialExecution) {
            for (uint256 i = 1; i < pricePointsBetweenXY; i++) {
                allPricePoints[idx++] = lastExectuionPriceXY < currentRateXY
                    ? lastExectuionPriceXY + i
                    : lastExectuionPriceXY - i;
            }
            for (uint256 i = 1; i < pricePointsBetweenYX; i++) {
                allPricePoints[idx++] = lastExectuionPriceYX < currentRateYX
                    ? lastExectuionPriceYX + i
                    : lastExectuionPriceYX - i;
            }
        }
        return sortAndDeduplicate(allPricePoints, idx);
    }

    function prepareExecutionData(
        uint256[] memory _pricePoints,
        uint256 currentRateXY,
        uint256 currentRateYX,
        address tokenX,
        address tokenY
    ) private  returns (ExecutionData memory executionData, uint256 executionTimestamp) {
        executionTimestamp = block.timestamp;
        executionData.orderIds = new uint256[](_pricePoints.length * MAX_ORDER_AT_PRICEPOINT);
        uint256 totalOrderIds;

        for (uint256 i = 0; i < _pricePoints.length; i++) {
           try2BuildExecDataWithUserPosition(
                totalOrderIds,
                _pricePoints[i],
                currentRateXY,
                currentRateYX, 
                executionTimestamp,
                tokenX,
                tokenY, 
                executionData
            );
            totalOrderIds += 1;
        }

        totalOrderIds -= 1;

        uint256[] memory resizedOrderIds = new uint256[](totalOrderIds);
        for (uint256 i = 0; i < totalOrderIds; i++) {
            resizedOrderIds[i] = executionData.orderIds[i];
        }
        executionData.orderIds = resizedOrderIds;

        return (executionData, executionTimestamp);
    }

    function try2BuildExecDataWithUserPosition(
        uint256 nextOrderIdx,
        uint256 pricePoint, 
        uint256 currentRateXY, 
        uint256 currentRateYX, 
        uint256 executionTimestamp,
        address tokenX, 
        address tokenY,
        ExecutionData memory executionData
    ) private {
        
        uint256[][] memory orderIdArrays = new uint256[][](2);
        orderIdArrays[0] = minPricePoint2OrderIds[pricePoint];
        orderIdArrays[1] = maxPricePoint2OrderIds[pricePoint];
        console.log(pricePoint);
        console.log("order ids min price arr len: ", orderIdArrays[0].length);
        console.log("order ids min price arr len: ", minPricePoint2OrderIds[3199979550818106973514].length);
        for (uint256 k = 0; k < orderIdArrays.length; k++) {
            uint256[] memory orderIds = orderIdArrays[k];
            for (uint256 j = 0; j < orderIds.length; j++) {
                PositionData memory position = orderId2PositionData[orderIds[j]];
                
                if (block.timestamp > position.args.maxExecutionTime) {
                    if (position.isActive) {
                        orderId2PositionData[orderIds[j]].isActive = false;
                    }
                    continue;
                } else if (position.isActive && position.executionTime == 0) {
                    
                    if (position.args.tokenIn == tokenY && position.args.tokenOut == tokenX) {
                            if (currentRateXY == position.args.minExecutionPrice || currentRateXY == position.args.maxExecutionPrice) {
                                executionData.orderIds[nextOrderIdx] = orderIds[j];
                                nextOrderIdx++;
                                orderId2PositionData[orderIds[j]].executionTime = executionTimestamp;
                                executionData.totalAmountInTokenX += position.args.amountIn;
                            }
                    } else if (position.args.tokenIn == tokenX && position.args.tokenOut == tokenY) {
                            if (currentRateYX == position.args.minExecutionPrice || currentRateYX == position.args.maxExecutionPrice) {
                                executionData.orderIds[nextOrderIdx] = orderIds[j];
                                nextOrderIdx++;
                                orderId2PositionData[orderIds[j]].executionTime = executionTimestamp;
                                executionData.totalAmountInTokenX += position.args.amountIn;
                                console.log("we have one");
                            }
                        }
                    }
                }
        }
    }

    function sortAndDeduplicate(uint256[] memory arr, uint256 length) private pure returns (uint256[] memory) {
        if (length == 0) return new uint256[](0);
        if (length == 1) return arr;

        for (uint256 i = 1; i < length; i++) {
            uint256 key = arr[i];
            int j = int(i) - 1;
            while (j >= 0 && arr[uint(j)] > key) {
                arr[uint(j + 1)] = arr[uint(j)];
                j--;
            }
            arr[uint(j + 1)] = key;
        }

        uint256 uniqueCount = 1;
        for (uint256 i = 1; i < length; i++) {
            if (arr[i] != arr[i - 1]) {
                arr[uniqueCount] = arr[i];
                uniqueCount++;
            }
        }

        uint256[] memory result = new uint256[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            result[i] = arr[i];
        }
        return result;
    }
}