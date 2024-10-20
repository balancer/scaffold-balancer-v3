import "forge-std/Test.sol";
import "@balancer-labs/v3-vault/contracts/Vault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";
import "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "permit2/src/interfaces/IPermit2.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTLiquidityStakingHook.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTMetadata.sol";
import "../contracts/hooks/NFTLiquidityStaking/NFTGovernor.sol";
import "../contracts/hooks/NFTLiquidityStaking/RewardToken.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

contract MockProtocolFeeController is IProtocolFeeController {
    function getProtocolFeePercentages(uint256) external pure returns (uint256, uint256) {
        return (0, 0);
    }

    function collectAggregateFees(address) external pure {}

    function computeAggregateFeePercentage(
        uint256 protocolFeePercentage,
        uint256 poolCreatorFeePercentage
    ) external pure returns (uint256) {
        // Mock implementation: simply return the sum of the two percentages
        return protocolFeePercentage + poolCreatorFeePercentage;
    }

    function registerPool(
        address pool,
        address poolCreator,
        bool protocolFeeExempt
    ) external pure returns (uint256, uint256) {
        return (0, 0);
    }

    function getGlobalProtocolSwapFeePercentage() external pure returns (uint256) {
        return 0;
    }
    function getGlobalProtocolYieldFeePercentage() external pure returns (uint256) {
        return 0;
    }
    function getPoolCreatorFeeAmounts(address) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }
    function getPoolProtocolSwapFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }
    function getPoolProtocolYieldFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
