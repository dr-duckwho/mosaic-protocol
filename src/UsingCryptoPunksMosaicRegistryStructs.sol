// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UsingCryptoPunksMosaicRegistryStructs {
    //
    // Original
    //

    struct Original {
        uint192 id;
        // @dev punkIndex
        uint256 punkId;
        /**
         * @dev To calculate governance quorum and token circulation.
         *      Corresponds to total ticket circulation per group.
         */
        uint96 totalMonoSupply;
        uint96 claimedMonoCount;
        uint256 purchasePrice;
        uint256 minReservePrice;
        uint256 maxReservePrice;
        string metadataBaseUri;
        OriginalState state;
        uint256 activeBidId;
    }

    enum OriginalState {
        Active,
        Sold
    }

    event OriginalSold(uint192 indexed originalId, uint256 indexed bidId);

    //
    // Mono
    //

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

    event MonoRefunded(uint192 indexed originalId, address indexed monoOwner);

    //
    // Bid
    //

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
        None,
        // Initial state, awaiting the result until the bidder explicitly reconstitutes the original or admits failure
        Proposed,
        // Resulting states upon vote results
        Accepted,
        Rejected,
        // Final/terminal states after bidder's action
        Won,
        Refunded
    }

    event BidProposed(uint256 indexed bidId, uint192 indexed originalId);

    event BidAccepted(uint256 indexed bidId, uint192 indexed originalId);

    event BidRejected(uint256 indexed bidId, uint192 indexed originalId);

    event BidWon(uint256 indexed bidId, uint192 indexed originalId);

    event BidRefunded(uint256 indexed bidId, uint192 indexed originalId);

    //
    // Meta statuses regarding Original/Mono/Bid/etc.
    //

    enum DistributionStatus {
        // Mono distribution is active for a given Original
        Active,
        // All Monos are minted for a given Original
        Complete
    }

    enum ReconstitutionStatus {
        // No reconstitution attempt is currently in progress
        None,
        // Some active Bid is ongoing with a governance vote session
        Active,
        // Bid past its expiry is accepted but is not processed completely
        Pending,
        // Bid is accepted
        Complete
    }

    enum FinalizationStatus {
        // No process ongoing; not applicable
        None,
        // Bid is finalized and the fund must be reclaimed pro rata
        Active,
        // All remaining funds are reclaimed
        Complete
    }

    error IllegalBidStateTransition(BidState given, BidState required);
    error NotEnoughProposals(uint64 validCount, uint256 thresholdBps);
}
