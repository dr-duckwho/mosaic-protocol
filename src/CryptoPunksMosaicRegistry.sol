// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721Upgradeable} from "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {SafeCast} from "@openzeppelin/utils/math/SafeCast.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./lib/BasisPoint.sol";
import "./external/ICryptoPunksMarket.sol";
import "./ICryptoPunksMosaicRegistry.sol";
import "./CryptoPunksMuseum.sol";
import "./CryptoPunksMosaicStorage.sol";
import "./CryptoPunksMosaicStorage.sol";
import "./CryptoPunksMosaicStorage.sol";

// TODO: Reconsider the ID scheme so that the same origin contract's same groups map to the same ID (contract, group) => (internal id)
contract CryptoPunksMosaicRegistry is
    ICryptoPunksMosaicRegistry,
    ERC721Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeCast for uint256;

    uint256 private constant MONO_ID_BITS = 64;
    uint256 private constant MONO_ID_BITMASK = (1 << (MONO_ID_BITS + 1)) - 1; // lower 64 bits
    address private constant NO_BIDDER = address(0x0);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * Default values for AdminGovernanceOptions
     */
    uint256 public constant RESERVE_PRICE_PROPOSAL_TURNOUT_THRESHOLD_BPS = 3000; // 30%
    uint40 public constant BID_EXPIRY_BLOCK_SECONDS = 604800;
    uint256 public constant BID_ACCEPTANCE_THRESHOLD_BPS = 3000; // 30%

    CryptoPunksMuseum public museum;

    function initialize(address museumAddress) public initializer {
        __ERC721_init("CryptoPunks Mosaic", "PUNKSMOSAIC");
        museum = CryptoPunksMuseum(museumAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, museumAddress);
        setAdminGovernanceOptions(
            true,
            RESERVE_PRICE_PROPOSAL_TURNOUT_THRESHOLD_BPS,
            BID_EXPIRY_BLOCK_SECONDS,
            BID_ACCEPTANCE_THRESHOLD_BPS
        );
    }

    modifier onlyWhenActive() {
        require(
            address(museum) != address(0) && museum.isActive(),
            "Museum must be active"
        );
        require(CryptoPunksMosaicStorage.isSetAdminGovernanceOptions());
        _;
    }

    modifier onlyActiveOriginal(uint192 originalId) {
        require(
            CryptoPunksMosaicStorage.get().originals[originalId].state ==
                OriginalState.Active
        );
        _;
    }

    modifier onlyMosaicOwner(uint256 mosaicId) {
        require(ownerOf(mosaicId) == msg.sender);
        _;
    }

    //
    // Core
    //

    function create(
        uint256 punkId,
        uint64 totalClaimableCount,
        uint256 purchasePrice,
        uint256 minReservePrice,
        uint256 maxReservePrice
    )
        external
        override
        onlyWhenActive
        onlyRole(MINTER_ROLE)
        returns (uint192 originalId)
    {
        require(
            museum.cryptoPunksMarket().punkIndexToAddress(punkId) ==
                address(this),
            "The contract must own the punk"
        );
        originalId = ++CryptoPunksMosaicStorage.get().latestOriginalId;
        ++CryptoPunksMosaicStorage.get().nextMonoIds[originalId];
        CryptoPunksMosaicStorage.get().originals[originalId] = Original({
            id: originalId,
            punkId: punkId,
            totalMonoSupply: totalClaimableCount,
            claimedMonoCount: 0,
            purchasePrice: purchasePrice,
            minReservePrice: minReservePrice,
            maxReservePrice: maxReservePrice,
            state: OriginalState.Active,
            activeBidId: 0,
            metadataBaseUri: ""
        });
        return originalId;
    }

    function mint(
        address contributor,
        uint192 originalId
    )
        external
        override
        onlyWhenActive
        onlyRole(MINTER_ROLE)
        returns (uint256 mosaicId)
    {
        require(
            CryptoPunksMosaicStorage.get().nextMonoIds[originalId] > 0,
            "Original must be initialized first"
        );
        uint64 monoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ]++;
        mosaicId = toMosaicId(originalId, monoId);
        CryptoPunksMosaicStorage.get().monos[mosaicId] = Mono({
            mosaicId: mosaicId,
            presetId: 0,
            governanceOptions: MonoGovernanceOptions({
                proposedReservePrice: 0,
                bidResponse: MonoBidResponse.None,
                bidId: 0
            })
        });
        CryptoPunksMosaicStorage.get().originals[originalId].claimedMonoCount++;
        _safeMint(contributor, mosaicId);

        return mosaicId;
    }

    //
    // Design: Mosaic owners
    //

    function setPresetId(
        uint256 mosaicId,
        uint8 presetId
    ) public onlyMosaicOwner(mosaicId) {
        // TODO: Validate presetId
        Mono storage mono = CryptoPunksMosaicStorage.get().monos[mosaicId];
        mono.presetId = presetId;
    }

    //
    // Governance: Mosaic owners
    //

    function proposeReservePrice(
        uint256 mosaicId,
        uint256 price
    ) external override onlyWhenActive onlyMosaicOwner(mosaicId) {
        // TODO: Check the bid state requirement
        //  and decide whether to allow reserve price proposals
        //  when there is an ongoing Bid already
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        require(
            original.minReservePrice <= price &&
                price <= original.maxReservePrice,
            "Must be within the range"
        );
        Mono storage mono = CryptoPunksMosaicStorage.get().monos[mosaicId];
        mono.governanceOptions.proposedReservePrice = price;
    }

    function proposeReservePriceBatch(
        uint192 originalId,
        uint256 price
    ) external override onlyWhenActive {
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        require(
            original.minReservePrice <= price &&
                price <= original.maxReservePrice,
            "Must be within the range"
        );
        uint64 nextMonoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ];
        for (uint64 monoId = 1; monoId < nextMonoId; monoId++) {
            uint256 mosaicId = toMosaicId(originalId, monoId);
            if (_ownerOf(mosaicId) == msg.sender) {
                Mono storage mono = CryptoPunksMosaicStorage.get().monos[
                    mosaicId
                ];
                mono.governanceOptions.proposedReservePrice = price;
            }
        }
    }

    //
    // Reconstitution: bidder
    //

    function bid(
        uint192 originalId,
        uint256 price
    )
        external
        payable
        onlyWhenActive
        onlyActiveOriginal(originalId)
        returns (uint256 newBidId)
    {
        require(msg.value == price, "Must send the exact value as proposed");

        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        require(
            price >= original.minReservePrice &&
                price >= getAverageReservePriceProposals(originalId) &&
                price <= original.maxReservePrice,
            "Bid price must be within the reserve price range"
        );

        uint256 oldBidId = original.activeBidId;
        if (oldBidId != 0) {
            // A preceding bid exists, so its state must be updated first
            BidState oldBidState = this.finalizeProposedBid(oldBidId);
            require(
                oldBidState == BidState.Rejected,
                "The previous bid must be rejected"
            );
        }
        uint256 newBidId = toBidId(originalId, msg.sender, block.timestamp);
        CryptoPunksMosaicStorage.get().bids[newBidId] = Bid({
            id: newBidId,
            originalId: originalId,
            bidder: payable(msg.sender),
            createdAt: uint40(block.timestamp),
            expiry: CryptoPunksMosaicStorage
                .getAdminGovernanceOptions()
                .bidExpiryBlockSeconds,
            price: price,
            state: BidState.Proposed
        });
        CryptoPunksMosaicStorage.get().bidDeposits[newBidId] = msg.value;
        original.activeBidId = newBidId;

        emit BidProposed(newBidId, originalId);
        return newBidId;
    }

    function toBidId(
        uint192 originalId,
        address bidder,
        uint256 blockTimestamp
    ) public pure returns (uint256 id) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(originalId, bidder, uint40(blockTimestamp))
                )
            );
    }

    function refundBidDeposit(
        uint256 bidId
    ) external override nonReentrant onlyWhenActive {
        Bid storage bid = CryptoPunksMosaicStorage.get().bids[bidId];
        require(
            bid.state == BidState.Rejected,
            "Only rejected bids can be refunded"
        );
        require(
            bid.bidder == msg.sender,
            "Only the bidder can retrieve its own fund"
        );

        uint256 deposit = CryptoPunksMosaicStorage.get().bidDeposits[bidId];
        (bool sent, ) = msg.sender.call{value: deposit}("");
        require(sent, "Failed to refund");

        bid.state = BidState.Refunded;
        emit BidRefunded(bidId, bid.originalId);
    }

    //
    // Reconstitution: Mosaic owners
    //

    function respondToBidBatch(
        uint192 originalId,
        MonoBidResponse response
    ) external onlyWhenActive returns (uint256 bidId, uint64 changedMonoCount) {
        require(hasOngoingBid(originalId), "No bid ongoing");

        uint64 nextMonoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ];
        uint256 activeBidId = CryptoPunksMosaicStorage
            .get()
            .originals[originalId]
            .activeBidId;
        for (uint64 monoId = 1; monoId < nextMonoId; monoId++) {
            uint256 mosaicId = toMosaicId(originalId, monoId);
            if (_ownerOf(mosaicId) == msg.sender) {
                changedMonoCount++;
                MonoGovernanceOptions
                    storage governanceOptions = CryptoPunksMosaicStorage
                        .get()
                        .monos[mosaicId]
                        .governanceOptions;
                governanceOptions.bidId = activeBidId;
                governanceOptions.bidResponse = response;
            }
        }
        return (activeBidId, changedMonoCount);
    }

    //
    // Reconstitution: common
    //

    function finalizeProposedBid(
        uint256 bidId
    ) external override onlyWhenActive returns (BidState) {
        Bid storage bid = CryptoPunksMosaicStorage.get().bids[bidId];
        require(
            bid.state == BidState.Proposed,
            "Only bids in proposal can be updated"
        );
        require(
            bid.createdAt + bid.expiry < block.timestamp,
            "Bid vote is ongoing"
        );
        bid.state = isBidAcceptable(bid.originalId)
            ? BidState.Accepted
            : BidState.Rejected;

        if (bid.state == BidState.Accepted) {
            emit BidAccepted(bidId, bid.originalId);
        } else {
            emit BidRejected(bidId, bid.originalId);
        }
        return bid.state;
    }

    // TODO: Introduce a way for Mosaic owners to force Bid finalization to prevent limbo cases where
    //  the winning bidder makes no further transaction
    function finalizeAcceptedBid(
        uint256 bidId
    ) external override onlyWhenActive {
        Bid storage bid = CryptoPunksMosaicStorage.get().bids[bidId];
        require(bid.state == BidState.Accepted, "Bid must be accepted");

        Original storage original = CryptoPunksMosaicStorage.get().originals[
            bid.originalId
        ];
        CryptoPunksMosaicStorage.get().resalePrices[original.id] = bid.price;
        original.state = OriginalState.Sold;
        emit OriginalSold(bid.originalId, bidId);

        museum.cryptoPunksMarket().transferPunk(bid.bidder, original.punkId);

        bid.state = BidState.Won;
        emit BidWon(bidId, bid.originalId);
    }

    //
    // Post-reconstitution: Mosaic owners
    //

    // @dev Burn all owned Monos and send refunds
    function refundOnSold(
        uint192 originalId
    )
        external
        override
        nonReentrant
        onlyWhenActive
        returns (uint256 totalResaleFund)
    {
        // TODO: Double-check whether arithmetic division may cause under/over-refunding
        uint256 burnedMonoCount = 0;
        uint64 nextMonoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ];
        for (uint64 monoId = 1; monoId < nextMonoId; monoId++) {
            uint256 mosaicId = toMosaicId(originalId, monoId);
            if (_ownerOf(mosaicId) == msg.sender) {
                _burn(mosaicId);
                burnedMonoCount++;
            }
        }
        require(burnedMonoCount > 0, "No Monos owned to refund");

        totalResaleFund = burnedMonoCount * getPerMonoResaleFund(originalId);
        (bool sent, ) = msg.sender.call{value: totalResaleFund}("");
        require(sent, "Failed to refund");

        emit MonoRefunded(originalId, msg.sender);
    }

    //
    // Reconstitution helpers
    //

    function getAverageReservePriceProposals(
        uint192 originalId
    ) public view returns (uint256 average) {
        (
            uint256 sum,
            uint64 valids,
            uint64 invalids
        ) = sumReservePriceProposals(originalId);
        require(
            valids >=
                BasisPoint.calculateBasisPoint(
                    (valids + invalids),
                    CryptoPunksMosaicStorage
                        .getAdminGovernanceOptions()
                        .reservePriceProposalTurnoutThresholdBps
                ),
            "Not enough reserve price proposals set"
        );
        return sum / valids;
    }

    function sumReservePriceProposals(
        uint192 originalId
    )
        public
        view
        returns (
            uint256 priceSum,
            uint64 validProposalCount,
            uint64 invalidProposalCount
        )
    {
        uint64 nextMonoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ];
        for (uint64 monoId = 1; monoId < nextMonoId; monoId++) {
            Mono storage mono = CryptoPunksMosaicStorage.get().monos[
                toMosaicId(originalId, monoId)
            ];
            if (mono.governanceOptions.proposedReservePrice > 0) {
                validProposalCount++;
                priceSum += mono.governanceOptions.proposedReservePrice;
            } else {
                invalidProposalCount++;
            }
        }
        return (priceSum, validProposalCount, invalidProposalCount);
    }

    // TODO: Consider taking bidId instead of originalId
    function sumBidResponses(
        uint192 originalId
    ) public view virtual returns (uint64 yes, uint64 no) {
        if (!hasOngoingBid(originalId)) {
            return (0, 0);
        }
        uint64 nextMonoId = CryptoPunksMosaicStorage.get().nextMonoIds[
            originalId
        ];
        uint256 activeBidId = CryptoPunksMosaicStorage
            .get()
            .originals[originalId]
            .activeBidId;
        for (uint64 monoId = 1; monoId < nextMonoId; monoId++) {
            MonoGovernanceOptions storage options = CryptoPunksMosaicStorage
                .get()
                .monos[toMosaicId(originalId, monoId)]
                .governanceOptions;
            if (options.bidId == activeBidId) {
                if (options.bidResponse == MonoBidResponse.Yes) {
                    yes++;
                } else if (options.bidResponse == MonoBidResponse.No) {
                    no++;
                }
            }
        }
        return (yes, no);
    }

    // TODO: Consider taking bidId instead of originalId
    function isBidAcceptable(
        uint192 originalId
    ) public view virtual returns (bool) {
        (uint64 yes, ) = sumBidResponses(originalId);
        uint128 totalVotable = CryptoPunksMosaicStorage
            .get()
            .originals[originalId]
            .totalMonoSupply;
        return
            yes >=
            BasisPoint.calculateBasisPoint(
                totalVotable,
                CryptoPunksMosaicStorage
                    .getAdminGovernanceOptions()
                    .bidAcceptanceThresholdBps
            );
    }

    function getPerMonoResaleFund(
        uint192 originalId
    ) public view virtual returns (uint256 perMonoResaleFund) {
        uint256 resalePrice = CryptoPunksMosaicStorage.get().resalePrices[
            originalId
        ];
        require(resalePrice > 0, "No resale price set");
        uint256 perMonoBps = BasisPoint.WHOLE_BPS /
            CryptoPunksMosaicStorage
                .get()
                .originals[originalId]
                .totalMonoSupply;

        return BasisPoint.calculateBasisPoint(resalePrice, perMonoBps);
    }

    //
    // Model views
    //
    function getLatestOriginalId()
        external
        view
        returns (uint192 latestOriginalId)
    {
        return CryptoPunksMosaicStorage.get().latestOriginalId;
    }

    function getMono(
        uint192 originalId,
        uint64 monoId
    ) external view returns (Mono memory) {
        return
            CryptoPunksMosaicStorage.get().monos[
                toMosaicId(originalId, monoId)
            ];
    }

    function getOriginal(
        uint192 originalId
    ) external view returns (Original memory) {
        return CryptoPunksMosaicStorage.get().originals[originalId];
    }

    function getMonoLifeCycle(
        uint256 mosaicId
    ) public view returns (MonoLifeCycle) {
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        require(
            originalId <= CryptoPunksMosaicStorage.get().latestOriginalId,
            "Invalid originalId"
        );

        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        if (original.state == OriginalState.Sold) {
            return MonoLifeCycle.Dead;
        }
        if (CryptoPunksMosaicStorage.get().monos[mosaicId].presetId == 0) {
            return MonoLifeCycle.Raw;
        }
        return MonoLifeCycle.Active;
    }

    function hasOngoingBid(uint192 originalId) public view returns (bool) {
        uint256 bidId = CryptoPunksMosaicStorage
            .get()
            .originals[originalId]
            .activeBidId;
        Bid storage bid = CryptoPunksMosaicStorage.get().bids[bidId];
        return
            bidId != 0 &&
            bid.bidder != NO_BIDDER &&
            bid.createdAt + bid.expiry >= block.timestamp;
    }

    function getDistributionStatus(
        uint192 originalId
    ) public view returns (DistributionStatus) {
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        if (original.totalMonoSupply == original.claimedMonoCount) {
            return DistributionStatus.Complete;
        }
        return DistributionStatus.Active;
    }

    function getReconstitutionStatus(
        uint192 originalId
    ) public view returns (ReconstitutionStatus) {
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        if (original.state == OriginalState.Sold) {
            return ReconstitutionStatus.Complete;
        }
        if (hasOngoingBid(originalId)) {
            return ReconstitutionStatus.Active;
        }
        Bid storage bid = CryptoPunksMosaicStorage.get().bids[
            original.activeBidId
        ];
        if (
            original.activeBidId == 0 ||
            bid.id == 0 ||
            bid.state == BidState.Rejected
        ) {
            return ReconstitutionStatus.None;
        }
        return ReconstitutionStatus.Pending;
    }

    //
    // Internal Helpers
    //

    function toMosaicId(
        uint192 originalId,
        uint64 monoId
    ) public pure returns (uint256 mosaicId) {
        return (uint256(originalId) << MONO_ID_BITS) | uint256(monoId);
    }

    function fromMosaicId(
        uint256 mosaicId
    ) public pure returns (uint192 originalId, uint64 monoId) {
        return (
            uint192(mosaicId >> MONO_ID_BITS),
            uint64(mosaicId & MONO_ID_BITMASK)
        );
    }

    //
    // Implementation internals
    //

    function grantMintAuthority(
        address addr
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        return _grantRole(MINTER_ROLE, addr);
    }

    function setInvalidMetadataUri(
        string calldata _uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CryptoPunksMosaicStorage.get().invalidMetadataUri = _uri;
    }

    function setMetadataBaseUri(
        uint192 originalId,
        string calldata _uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        original.metadataBaseUri = _uri;
    }

    //
    // ERC721
    //

    function tokenURI(
        uint256 mosaicId
    ) public view override returns (string memory) {
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        Original storage original = CryptoPunksMosaicStorage.get().originals[
            originalId
        ];
        if (original.state == OriginalState.Sold) {
            return CryptoPunksMosaicStorage.get().invalidMetadataUri;
        }
        string memory baseUrl = original.metadataBaseUri;
        uint8 presetId = CryptoPunksMosaicStorage
            .get()
            .monos[mosaicId]
            .presetId;
        return
            string.concat(
                baseUrl,
                "/",
                Strings.toString(original.punkId),
                "_",
                Strings.toString(uint256(presetId)),
                ".json"
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    //
    // Admin
    //

    function setAdminGovernanceOptions(
        bool isSet,
        uint256 reservePriceProposalTurnoutThresholdBps,
        uint40 bidExpiryBlockSeconds,
        uint256 bidAcceptanceThresholdBps
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        CryptoPunksMosaicStorage.AdminGovernanceOptions
            storage options = CryptoPunksMosaicStorage
                .getAdminGovernanceOptions();
        options.isSet = isSet;
        options
            .reservePriceProposalTurnoutThresholdBps = reservePriceProposalTurnoutThresholdBps;
        options.bidExpiryBlockSeconds = bidExpiryBlockSeconds;
        options.bidAcceptanceThresholdBps = bidAcceptanceThresholdBps;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
