// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

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
    uint64 public constant MIN_RESERVE_PRICE_BASIS_POINT = 7000; // 70%
    uint64 public constant MAX_RESERVE_PRICE_BASIS_POINT = 50000; // 500%
    uint64 public constant BASIS_POINT_DENOMINATOR = 10000;

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
     * @dev also used as a `groupId`, starting from 1.
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
            groups[latestGroupId].status != GroupStatus.Open,
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
        cryptoPunksMarket.buyPunk{value: offeredPrice}(punkId);
        require(
            cryptoPunksMarket.punkIndexToAddress(punkId) == address(this),
            "Unexpected ownership"
        );
        group.purchasePrice = offeredPrice;
        group.status = GroupStatus.Won;
        emit GroupWon(groupId);
        finalizeOnWon(groupId);
    }

    function finalizeOnWon(uint192 groupId) public onlyValidGroup(groupId) {
        // TODO: Consider removing `getValidGroup` invocation if it costs too much gas
        Group storage group = groups[groupId];
        require(group.status == GroupStatus.Won, "The group has not won");
        require(
            address(mosaicRegistry) != address(0x0),
            "Exhibit registry must be set"
        );

        // FIXME: Defend against reentrancy attacks in edge cases where the same cryptopunk ID is used later
        cryptoPunksMarket.transferPunk(
            address(mosaicRegistry),
            group.targetPunkId
        );
        group.originalId = mosaicRegistry.create(
            group.targetPunkId,
            group.ticketsBought,
            group.purchasePrice,
            calculateMinReservePrice(group.purchasePrice),
            calculateMaxReservePrice(group.purchasePrice)
        );
        // TODO: Consider whether to explicitly mark other competing groups as LOST
        group.status = GroupStatus.Claimable;
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
    function refund(
        uint192 groupId
    ) public nonReentrant onlyValidGroup(groupId) {
        address payable contributor = payable(msg.sender);
        Group storage group = groups[groupId];
        require(
            group.status != GroupStatus.Claimable &&
                group.status != GroupStatus.Won &&
                group.expiry < block.timestamp,
            "The group is not expired yet"
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
            calculateBasisPoint(purchasePrice, MIN_RESERVE_PRICE_BASIS_POINT);
    }

    function calculateMaxReservePrice(
        uint256 purchasePrice
    ) public pure returns (uint256 maxReservePrice) {
        return
            calculateBasisPoint(purchasePrice, MAX_RESERVE_PRICE_BASIS_POINT);
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

    // Basis point calculation
    // TODO: Move this to a common library
    function calculateBasisPoint(
        uint256 amount,
        uint256 basisPoints
    ) public pure returns (uint256) {
        require((amount * basisPoints) >= 10_000);
        return (amount * basisPoints) / 10_000;
    }

    // TODO: fallback
}
