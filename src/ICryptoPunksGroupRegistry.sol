// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UsingCryptoPunksGroupRegistryStructs.sol";

interface ICryptoPunksGroupRegistry is UsingCryptoPunksGroupRegistryStructs {
    function create(
        uint256 targetPunkId,
        uint256 targetMaxPrice
    ) external returns (uint192 groupId);

    function contribute(
        uint192 groupId,
        uint64 ticketQuantity
    ) external payable;

    function buy(uint192 groupId) external;

    function claim(
        uint192 groupId
    )
    external
    returns (uint256[] memory mosaicIds);

    function refundExpired(
        uint192 groupId
    ) external;
}
