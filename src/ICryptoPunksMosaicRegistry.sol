// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UsingCryptoPunksMosaicRegistryStructs.sol";

interface ICryptoPunksMosaicRegistry is UsingCryptoPunksMosaicRegistryStructs {
    // TODO: fill it out
    function create(
        uint256 punkId,
        uint64 totalClaimableCount,
        uint256 purchasePrice,
        uint256 minReservePrice,
        uint256 maxReservePrice
    ) external returns (uint192 originalId);

    function mint(
        address contributor,
        uint192 originalId
    ) external returns (uint256 mosaicId);

    function bid(
        uint192 originalId,
        uint256 price
    ) external payable returns (uint256 newBidId);

    function proposeReservePrice(uint256 mosaicId, uint256 price) external;

    function proposeReservePriceBatch(
        uint192 originalId,
        uint256 price
    ) external;

    function refundBidDeposit(uint256 bidId) external;

    function respondToBidBatch(
        uint192 originalId,
        MonoBidResponse response
    ) external returns (uint256 bidId, uint64 changedMonoCount);

    function finalizeProposedBid(uint256 bidId) external returns (BidState);

    function finalizeAcceptedBid(uint256 bidId) external;

    function refundOnSold(
        uint192 originalId
    ) external returns (uint256 totalResaleFund);

    function grantMintAuthority(address addr) external;
}
