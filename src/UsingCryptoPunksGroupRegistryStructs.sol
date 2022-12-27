// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UsingCryptoPunksGroupRegistryStructs {
    /**
     * @dev WON if the group has successfully purchased and acquired the target original;
     *  LOST if the group has not procured the target original within the expiry.
     */
    enum GroupStatus {
        Open,
        Won,
        Lost,
        Claimable
    }

    struct Group {
        uint192 id;
        address creator;
        uint256 targetPunkId;
        uint256 targetMaxPrice;
        uint64 totalTicketSupply;
        uint256 unitTicketPrice;
        uint256 totalContribution;
        uint64 ticketsBought;
        uint40 expiry; // in seconds, with respect to block.timestamp
        GroupStatus status;
        uint256 purchasePrice; // price at which the target is bought
        uint192 originalId;
    }

    event GroupCreated(
        uint192 indexed groupId,
        address indexed creator,
        uint256 targetMaxPrice,
        uint64 totalTicketSupply,
        uint256 unitTicketPrice
    );

    event GroupWon(uint192 indexed groupId);

    event Contributed(
        address indexed contributor,
        uint192 indexed groupId,
        uint96 indexed ticketQuantity
    );

    event Claimed(
        address indexed claimer,
        uint192 indexed groupId,
        uint256 indexed mosaicId
    );
}
