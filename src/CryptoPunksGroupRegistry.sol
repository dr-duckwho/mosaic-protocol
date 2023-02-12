// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

import "./lib/BasisPoint.sol";
import "./external/ICryptoPunksMarket.sol";
import "./ICryptoPunksGroupRegistry.sol";
import "./ICryptoPunksMosaicRegistry.sol";

// TODO: Wire with Museum
// TODO: Migrate custom revert error messages to byte constants
contract CryptoPunksGroupRegistry is
    ICryptoPunksGroupRegistry,
    ERC1155,
    AccessControl,
    ReentrancyGuard
{
    /**
     * Arithmetic constants
     */
    uint64 public constant MIN_RESERVE_PRICE_BPS = 7000; // 70%
    uint64 public constant MAX_RESERVE_PRICE_BPS = 50000; // 500%

    /**
     * Business logic constants
     *
     * TODO: Introduce a global explicit storage contract
     */
    uint64 public constant TICKET_SUPPLY_PER_GROUP = 100;
    /**
     * @dev can create and curate the active group
     */
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    ICryptoPunksMarket public immutable cryptoPunksMarket;
    ICryptoPunksMosaicRegistry private mosaicRegistry;

    /**
     * @dev Starts from 1.
     *  Must increment this first when creating a new group.
     */
    uint192 public latestGroupId;
    mapping(uint192 => Group) private groups;

    /**
     * @dev groupId -> address -> shares (= the number of tickets bought)
     */
    mapping(uint192 => mapping(address => uint256)) private refundableTickets;

    constructor(
        address cryptoPunksMarketAddress,
        address mosaicRegistryAddress
    ) ERC1155("CryptoPunks Mosaic Ticket") {
        // TODO: Inherit a configuration storage from a Museum
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CURATOR_ROLE, msg.sender);
        // TODO: code it up with config passing
        cryptoPunksMarket = ICryptoPunksMarket(cryptoPunksMarketAddress);
        mosaicRegistry = ICryptoPunksMosaicRegistry(mosaicRegistryAddress);
    }

    modifier onlyValidGroup(uint192 groupId) {
        require(groupId <= latestGroupId, "Invalid groupId");
        _;
    }

    function create(
        uint256 targetPunkId,
        uint256 targetMaxPrice
    ) external onlyRole(CURATOR_ROLE) returns (uint192 groupId) {
        require(
            getGroupLifeCycle(latestGroupId) != GroupLifeCycle.Active,
            "Ongoing group exists"
        );

        ++latestGroupId;
        uint64 totalTicketSupply = TICKET_SUPPLY_PER_GROUP;
        uint256 unitTicketPrice = targetMaxPrice / totalTicketSupply;

        Group storage newGroup = groups[latestGroupId];
        newGroup.id = latestGroupId;
        newGroup.creator = msg.sender;
        newGroup.targetPunkId = targetPunkId;
        newGroup.targetMaxPrice = targetMaxPrice;
        newGroup.totalTicketSupply = totalTicketSupply;
        newGroup.unitTicketPrice = unitTicketPrice;
        newGroup.status = GroupStatus.Open;
        // TODO: Make it configurable
        newGroup.expiry = uint40(block.timestamp + 604800);

        emit GroupCreated(
            latestGroupId,
            msg.sender,
            targetMaxPrice,
            totalTicketSupply,
            unitTicketPrice
        );
        return latestGroupId;
    }

    function contribute(
        uint192 groupId,
        uint64 ticketQuantity
    ) external payable onlyValidGroup(groupId) {
        Group storage group = groups[groupId];

        uint256 ticketsLeft = group.totalTicketSupply - group.ticketsBought;
        require(
            ticketQuantity <= ticketsLeft,
            "Fewer tickets remaining than requested"
        );

        uint256 ethReceived = msg.value;
        uint256 ethRequired = group.unitTicketPrice * ticketQuantity;
        require(ethReceived == ethRequired, "Contribution must be exact");

        address contributor = msg.sender;
        group.totalContribution += ethReceived;
        group.ticketsBought += ticketQuantity;
        refundableTickets[groupId][contributor] += ticketQuantity;

        _mint(contributor, groupId, ticketQuantity, "");

        emit Contributed(contributor, groupId, ticketQuantity);
    }

    /**
     * @dev Can be tried as long as the group is OPEN
     */
    function buy(
        uint192 groupId
    ) external nonReentrant onlyValidGroup(groupId) {
        // Internal prerequisites
        require(
            address(mosaicRegistry) != address(0x0),
            "Exhibit registry must be set"
        );

        // Stakeholder and group status prerequisites
        Group storage group = groups[groupId];
        require(
            hasContribution(msg.sender, groupId),
            "Only ticket holders can initiate a buy"
        );
        uint256 punkId = group.targetPunkId;
        (, , , uint256 offeredPrice, ) = cryptoPunksMarket.punksOfferedForSale(
            punkId
        );
        require(group.ticketsBought == TICKET_SUPPLY_PER_GROUP, "Not sold out");
        require(
            group.totalContribution >= offeredPrice,
            "Offered price is greater than the current contribution"
        );

        // Purchase
        cryptoPunksMarket.buyPunk{value: offeredPrice}(punkId);
        require(
            cryptoPunksMarket.punkIndexToAddress(punkId) == address(this),
            "Unexpected ownership"
        );

        // TODO: Double-check the possibility of reentrancy attacks when the same punk ID is used again later
        cryptoPunksMarket.transferPunk(
            address(mosaicRegistry),
            group.targetPunkId
        );

        group.purchasePrice = offeredPrice;
        group.originalId = mosaicRegistry.create(
            group.targetPunkId,
            group.ticketsBought,
            group.purchasePrice,
            calculateMinReservePrice(group.purchasePrice),
            calculateMaxReservePrice(group.purchasePrice)
        );
        group.status = GroupStatus.Claimable;

        emit GroupWon(groupId);
    }

    // @dev Batch claim-refund as many Mosaic Monos as tickets held
    function claim(
        uint192 groupId
    )
        external
        nonReentrant
        onlyValidGroup(groupId)
        returns (uint256[] memory mosaicIds)
    {
        Group storage group = groups[groupId];
        require(
            group.status == GroupStatus.Claimable,
            "The group is not finalized"
        );
        uint256 ticketsHeld = getTickets(msg.sender, groupId);
        require(ticketsHeld > 0, "Only ticket holders can claim tokens");
        _burn(msg.sender, groupId, ticketsHeld);

        // Refund
        uint256 owed = getRefundPerTicket(group) * ticketsHeld;
        // TODO: Define a library for ETH sending with gas considerations
        (bool sent, ) = msg.sender.call{value: owed}("");
        require(sent, "Failed to refund");

        // Mint
        uint256[] memory mosaicIds = new uint256[](ticketsHeld);
        for (uint256 i = 0; i < ticketsHeld; i++) {
            uint256 mosaicId = mosaicRegistry.mint(
                msg.sender,
                group.originalId
            );
            mosaicIds[i] = mosaicId;
            emit Claimed(msg.sender, groupId, mosaicId);
        }

        return mosaicIds;
    }

    // @dev only for lost/expired groups to invoke explicitly
    function refundExpired(
        uint192 groupId
    ) public nonReentrant onlyValidGroup(groupId) {
        address payable contributor = payable(msg.sender);
        Group storage group = groups[groupId];
        // FIXME
        require(
            getGroupLifeCycle(groupId) == GroupLifeCycle.Expired,
            "The group must be expired"
        );
        uint256 ticketsHeld = getTickets(msg.sender, groupId);
        require(ticketsHeld > 0, "Only ticket holders can get refunds");

        _burn(msg.sender, groupId, ticketsHeld);

        uint256 owed = getRefundPerTicket(group) * ticketsHeld;
        (bool sent, ) = contributor.call{value: owed}("");
        require(sent, "Failed to refund");
    }

    function getRefundPerTicket(
        Group storage group
    ) private view returns (uint256 refundPerTicket) {
        if (group.totalContribution <= group.purchasePrice) {
            return 0;
        }
        uint256 surplus = group.totalContribution - group.purchasePrice;
        return surplus / group.ticketsBought;
    }

    //
    // Registry-related views
    //

    function uri(uint256 groupId) public view override returns (string memory) {
        Group storage group = groups[uint192(groupId)];
        return group.metadataUri;
    }

    //
    // Group-related views
    //

    function getGroup(
        uint192 groupId
    ) public view onlyValidGroup(groupId) returns (Group memory) {
        return groups[groupId];
    }

    function getGroupLifeCycle(
        uint192 groupId
    ) public view onlyValidGroup(groupId) returns (GroupLifeCycle) {
        Group storage group = groups[groupId];
        if (group.status == GroupStatus.Claimable) {
            return GroupLifeCycle.Won;
        }
        if (group.status == GroupStatus.Open) {
            if (group.expiry >= block.timestamp) {
                return GroupLifeCycle.Active;
            }
            return GroupLifeCycle.Expired;
        }
        return GroupLifeCycle.Nonexistent;
    }

    function getGroupTotalContribution(
        uint192 groupId
    ) public view onlyValidGroup(groupId) returns (uint256 totalContribution) {
        return groups[groupId].totalContribution;
    }

    //
    // Ticket
    //

    function getTickets(
        address inquired,
        uint192 groupId
    ) public view returns (uint256) {
        return balanceOf(inquired, uint256(groupId));
    }

    function isCreator(
        address inquired,
        uint192 groupId
    ) public view returns (bool) {
        return groups[groupId].creator == inquired;
    }

    function hasContribution(
        address inquired,
        uint192 groupId
    ) public view returns (bool) {
        return getTickets(inquired, groupId) > 0;
    }

    //
    // Constitution
    //

    function calculateMinReservePrice(
        uint256 purchasePrice
    ) public pure returns (uint256 minReservePrice) {
        return
            BasisPoint.calculateBasisPoint(
                purchasePrice,
                MIN_RESERVE_PRICE_BPS
            );
    }

    function calculateMaxReservePrice(
        uint256 purchasePrice
    ) public pure returns (uint256 maxReservePrice) {
        return
            BasisPoint.calculateBasisPoint(
                purchasePrice,
                MAX_RESERVE_PRICE_BPS
            );
    }

    //
    // Admin
    //

    function airdrop(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    //
    // Internals
    //
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // TODO: fallback
}
