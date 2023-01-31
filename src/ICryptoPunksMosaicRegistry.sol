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

    function bid(uint192 originalId, uint256 price) external;
}
