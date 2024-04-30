// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { ERC20 } from "../../../../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {  IVaultExtension } from "../../contracts/interfaces/IVaultExtension.sol";
import {  IVault } from "../../contracts/interfaces/IVault.sol";
import {IRouter} from "../../contracts/interfaces/IRouter.sol";


contract TestAddresses {

    // BalancerV3 Sepolia addresses

    // Core
    IVault public vault = IVault(0x1FC7F1F84CFE61a04224AC8D3F87f56214FeC08c);
    IVaultExtension public vaultExtension = IVaultExtension(0x718e1176f01dDBb2409A77B2847B749c8dF4457f);
    IRouter public router = IRouter(0xA0De078cd5cFa7088821B83e0bD7545ccfb7c883);
    address batchRouter = 0x8A8B9f35765899B3a0291700141470D79EA2eA88;

    // Balancer Pools
    address public testPool = 0x37495BE0Af7B427Ddb9C504cE53617F9F04620aD; // already deployed by BLabs?

    // DeFi Ecosystem
    address public ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // ERC20s
    ERC20 public sepoliaDAI = ERC20(0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613);
	ERC20 public sepoliaUSDC = ERC20(0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A);


}