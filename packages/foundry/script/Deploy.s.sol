//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ScaffoldHelpers } from "./ScaffoldHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployMockTokens } from "./00_DeployMockTokens.s.sol";
import { DeployConstantSumPool } from "./01_DeployConstantSumPool.s.sol";
import { DeployConstantProductPool } from "./02_DeployConstantProductPool.s.sol";
import { DeployWeightedPool8020 } from "./03_DeployWeightedPool8020.s.sol";
import { DeployNFTLiquidityStakingHook } from "./04_DeployNFTLiquidityStakingHook.s.sol";

/**
 * @title Deploy Script
 * @dev Run all deploy scripts here to allow for scaffold integrations with nextjs front end
 * @dev Run this script with `yarn deploy`
 */
contract DeployScript is
    ScaffoldHelpers,
    DeployMockTokens,
    DeployConstantSumPool,
    DeployConstantProductPool,
    DeployWeightedPool8020,
    DeployNFTLiquidityStakingHook
{
    function run() external scaffoldExport {
       
        (address mockToken1, address mockToken2, address mockVeBAL) = deployMockTokens();

        
        deployConstantSumPool(mockToken1, mockToken2, mockVeBAL);

        
        deployConstantProductPool(mockToken1, mockToken2);

       
        deployWeightedPool8020(mockToken1, mockToken2);

        address vaultAddress = 0x7966FE92C59295EcE7FB5D9EfDB271967BFe2fbA; 
        address factoryAddress = 0x765ce16dbb3D7e89a9beBc834C5D6894e7fAA93c; 
        this.run(vaultAddress, factoryAddress); 
    }

    modifier scaffoldExport() {
        _;
        exportDeployments();
    }
}
