// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";

interface IGroupRegistry {
    /**
     * @dev WON if the group has successfully purchased and acquired the target original;
     *  LOST if the group has not procured the target original within the expiry.
     */
    enum GroupStatus {
        OPEN,
        WON,
        LOST,
        CLAIMABLE
    }

    struct Group {
        uint192 id;
        address creator;
        uint256 targetPunkIndex;
        uint256 targetMaxPrice;
        uint64 totalTicketSupply;
        uint256 unitTicketPrice;
        uint256 totalContribution;
        uint64 ticketsBought;
        uint40 expiry; // in seconds, with respect to block.timestamp
        GroupStatus status;
        uint256 purchasePrice; // price at which the target is bought
        address exhibit; // set only when won and finalized
        uint192 exhibitId;
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
        uint96 ticketQuantity
    );

    event Claimed(
        address indexed claimer,
        uint192 indexed groupId,
        address indexed exhibitRegistry,
        uint256 tokenId
    );

    // TODO: Add signatures; consider `forfeit`
}
