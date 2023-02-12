// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UsingCryptoPunksMosaicRegistryStructs {
    struct Original {
        uint192 id;
        // @dev punkIndex
        uint256 punkId;
        /**
         * @dev To calculate governance quorum and token circulation.
         *      Corresponds to total ticket circulation per group.
         */
        uint128 totalMonoSupply;
        uint128 claimedMonoCount;
        uint256 purchasePrice;
        uint256 minReservePrice;
        uint256 maxReservePrice;
        string metadataBaseUri;
        OriginalStatus status;
        uint256 activeBidId;
    }

    enum OriginalStatus {
        Active,
        Sold
    }

    struct Mono {
        uint256 mosaicId;
        uint8 presetId;
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

    // @dev There can be at most one ongoing bid per original
    struct Bid {
        // @dev keccak256(abi.encodePacked(originalId, bidder, uint40(block.timestamp))
        uint256 id;
        address payable bidder;
        uint192 originalId;
        uint256 price;
        // block.timestamp
        uint40 createdAt;
        // duration in block.timestamp, in seconds
        uint40 expiry;
        // @dev updated upon any following Bid's creation or explicit external state updates
        BidState state;
    }

    enum BidState {
        // Initial state, awaiting the result until the bidder explicitly reconstitutes the original or admits failure
        Proposed,
        // Resulting states upon vote results
        Accepted,
        Rejected,
        // Final/terminal states after bidder's action
        Won,
        Refunded
    }
}
