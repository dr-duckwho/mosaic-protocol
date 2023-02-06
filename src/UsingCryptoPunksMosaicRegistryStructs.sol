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
        Sold
    }

    struct Mono {
        uint256 mosaicId;
        /**
         * @dev mosaicId (originalId + monoId) => uri
         *
         * TODO: Decide whether to use URI or JSON data
         */
        string metadataUri;
        MonoGovernanceOptions governanceOptions;
    }

    enum MonoLifeCycle {
        // @dev pre-design, just minted
        Raw,
        // @dev post-design, valid
        Active,
        // @dev belonging to invalid/reconstituted Original
        Dead
    }

    struct MonoGovernanceOptions {
        uint256 proposedReservePrice;
        MonoBidResponse bidResponse;
        // @dev Bid ID
        uint256 bidId;
    }

    enum MonoBidResponse {
        None,
        Yes,
        No
    }

    struct Bid {
        uint256 id;
        address bidder;
        uint40 createdAt;
        uint40 expiry; // duration in block.timestamp, in seconds
        uint256 price;
    }
}
