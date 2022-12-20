// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UsingCryptoPunksMosaicRegistryStructs.sol";

interface ICryptoPunksMosaicRegistry is UsingCryptoPunksMosaicRegistryStructs {

    // TODO: fill it out
    function create(
        uint256 punkId,
        uint64 totalClaimableCount
    ) external returns (uint192 originalId);

    function mint(
        address contributor,
        uint192 originalId,
        string calldata metadataUri
    ) external returns (uint256 mosaicId);
}
