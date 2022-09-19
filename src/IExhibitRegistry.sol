// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IExhibitRegistry {
    // TODO: fill it out
    function create(
        address originalTokenContract,
        uint256 originalTokenId,
        uint64 totalClaimableCount
    ) external returns (uint192 exhibitId);

    function mint(
        address contributor,
        uint192 exhibitId,
        string calldata metadataUri
    ) external returns (uint256 erc1155TokenId);
}
