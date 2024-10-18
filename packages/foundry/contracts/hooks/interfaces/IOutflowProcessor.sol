// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IOutflowProcessor {
    error ErrLocked();
    error ErrInvalidAddress();
    error ErrZeroAmount();
    error ErrOnlyOutflowRequester();
    error ErrOnlyOutflowApprover();
    error ErrInvalidSourceID();
    error ErrInconsistency();
    error ErrInvalidOutflowRequestID();
    error ErrInvalidOutflowRequestStatus();
    error ErrMinResolutionPeriod();
    error ErrMerkleTreeRootHashNotProvided();

    event LogOutflowRequester(address outflowRequester);
    event LogOutflowApprover(address outflowApprover);
    event LogOutflowRequest(uint256 outflowRequestID);
    event LogDistributor(address distributor);
    event LogOutflowRequestApproved(uint256 outflowRequestID);
    event LogOutflowRequestDeclined(uint256 outflowRequestID);
    event LogPaidOut(
        uint256 outflowRequestID,
        address pool,
        address asset,
        uint256 requestedAmount,
        uint256 releasedAmount,
        address recipient
    );

    enum OutflowRequestStatus {
        REQUESTED,
        DECLINED,
        PROCESSED
    }

    struct OutflowRequest {
        address protocol;
        uint256 sourceID;
        uint256 entityID;
        address recipient;
        bool merkleTreeDistribution;
        address baseAsset;
        address[] outflowPools;
        uint256[] outflowPoolAssetAmounts;
        uint256 requestedBaseAssetAmount;
        uint256 createdAt;
        OutflowRequestStatus status;
        bytes32 merkleTreeDistributionRootHash;
        string data;
    }

    struct CreateOutflowRequestParams {
        address protocol;
        uint256 sourceID;
        uint256 entityID;
        address recipient;
        address baseAsset;
        uint256 baseAssetAmount;
        address[] outflowPools;
        uint256[] outflowPoolAssetAmounts;
        bytes32 merkleTreeDistributionRootHash;
        string data;
    }

    function createOutflowRequest(
        CreateOutflowRequestParams calldata params
    ) external returns (uint256 outflowRequestID);

    function approveOutflowRequest(uint256 outflowRequestID) external;

    function declineOutflowRequest(uint256 outflowRequestID) external;

    function outflowRequest(uint256 outflowRequestID) view external returns(uint requestedAmount);

    function factory() external view returns (address);
}