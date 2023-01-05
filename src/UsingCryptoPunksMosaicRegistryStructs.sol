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
        OriginalStatus status;
        Bid bid;
    }

    enum OriginalStatus {
        Active,
        Bid,
        Sold
    }

    struct Mono {
        uint256 mosaicId;
        /**
         * @dev mosaicId (originalId + monoId) => uri
         *
         * TODO: Decide whether to use URI or JSON data
         */
        string metadata;
        MonoGovernanceOptions governanceOptions;
    }

    struct MonoGovernanceOptions {
        uint256 proposedReservePrice;
        MonoBidResponse bidResponse;
    }

    enum MonoBidResponse {
        None,
        Yes,
        No
    }

    struct Bid {
        address bidder;
        uint40 expiry; // block.timestamp, in seconds
        uint256 price;
    }
}
