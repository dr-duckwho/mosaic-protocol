// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UsingCryptoPunksMosaicRegistryStructs {
    struct Original {
        uint192 id;
        uint256 punkId;
        /**
         * @dev To calculate governance quorum and token circulation.
         *      Corresponds to total ticket circulation per group.
         */
        uint128 totalMonoCount;
        uint128 claimedMonoCount;
        uint256 purchasePrice;
        uint256 minReservePrice;
        uint256 maxReservePrice;
        OriginalStatus status;
        Bid bid;
    }

    enum OriginalStatus {
        Active,
        Bid,
        Sold
    }

    struct Bid {
        address bidder;
        uint40 expiry; // block.timestamp, in seconds
        uint256 price;
    }
}
