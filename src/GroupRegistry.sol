// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/utils/Strings.sol";
import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";

import {CryptoPunksMarket} from "./external/CryptoPunksMarket.sol";

import {IGroupRegistry} from "./IGroupRegistry.sol";
import {IExhibitRegistry} from "./IExhibitRegistry.sol";

// TODO: Wire with Museum
contract GroupRegistry is
    IGroupRegistry,
    ERC1155,
    AccessControl,
    ReentrancyGuard
{
    // TODO: Introduce a global explicit storage contract
    uint64 public constant TICKET_SUPPLY_PER_GROUP = 100;

    CryptoPunksMarket public cryptoPunksMarket;
    IExhibitRegistry private exhibitRegistry;

    /**
     * @dev also used as a `groupId`, starting from 1.
     */
    uint192 public groupCount;
    mapping(uint192 => Group) private groups;

    constructor(
        address cryptoPunksMarketAddress,
        address exhibitRegistryAddress
    ) ERC1155("TICKET_V1") {
        // TODO: Inherit a configuration storage from a Museum
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // TODO: code it up with config passing
        cryptoPunksMarket = CryptoPunksMarket(cryptoPunksMarketAddress);
        exhibitRegistry = IExhibitRegistry(exhibitRegistryAddress);
    }

    function create(
        uint256 targetPunkId,
        uint256 targetMaxPrice
    ) external returns (uint192 groupId) {
        groupId = ++groupCount;
        uint64 totalTicketSupply = TICKET_SUPPLY_PER_GROUP;
        uint256 unitTicketPrice = targetMaxPrice / totalTicketSupply;

        Group storage newGroup = groups[groupId];
        newGroup.id = groupId;
        newGroup.creator = msg.sender;
        newGroup.targetPunkIndex = targetPunkId;
        newGroup.targetMaxPrice = targetMaxPrice;
        newGroup.totalTicketSupply = totalTicketSupply;
        newGroup.unitTicketPrice = unitTicketPrice;
        newGroup.status = GroupStatus.OPEN;
        // TODO: Make it configurable
        newGroup.expiry = uint40(block.timestamp + 604800);

        emit GroupCreated(
            groupId,
            msg.sender,
            targetMaxPrice,
            totalTicketSupply,
            unitTicketPrice
        );
        return groupId;
    }

    function contribute(
        uint192 groupId,
        uint64 ticketQuantity
    ) external payable {
        Group storage group = getValidGroup(groupId);

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

        _mint(contributor, groupId, ticketQuantity, "");

        emit Contributed(contributor, groupId, ticketQuantity);
    }

    /**
     * @dev Can be tried as long as the group is OPEN
     */
    function buy(uint192 groupId) external nonReentrant {
        Group storage group = getValidGroup(groupId);
        require(
            hasShare(msg.sender, groupId),
            "Only ticket holders can initiate a buy"
        );
        uint256 punkId = group.targetPunkIndex;
        (, , , uint256 offeredPrice, ) = cryptoPunksMarket.punksOfferedForSale(
            punkId
        );
        // TODO: Require all 100 tickets bought already
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
        group.status = GroupStatus.WON;
        emit GroupWon(groupId);
        finalizeOnWon(groupId);
    }

    // Separated for retry after any partial failure
    function finalizeOnWon(uint192 groupId) public {
        // TODO: Consider removing `getValidGroup` invocation if it costs too much gas
        Group storage group = getValidGroup(groupId);
        require(group.status == GroupStatus.WON, "The group has not won");
        require(
            address(exhibitRegistry) != address(0x0),
            "Exhibit registry must be set"
        );

        // FIXME: Defend against reentrancy attacks in edge cases where the same cryptopunk ID is used later
        cryptoPunksMarket.transferPunk(
            address(exhibitRegistry),
            group.targetPunkIndex
        );
        group.exhibitId = exhibitRegistry.create(
            address(cryptoPunksMarket),
            group.targetPunkIndex,
            group.ticketsBought
        );
        group.exhibit = address(exhibitRegistry);
        // TODO: Consider whether to explicitly mark other competing groups as LOST
        group.status = GroupStatus.FINALIZED;
    }

    function claim(
        uint192 groupId,
        string calldata metadataUri
    )
        external
        nonReentrant
        returns (IExhibitRegistry registry, uint256 tokenId)
    {
        Group storage group = getValidGroup(groupId);
        require(
            group.status == GroupStatus.FINALIZED,
            "The group is not finalized"
        );
        require(
            hasShare(msg.sender, groupId) || msg.sender == group.creator,
            "Only ticket holders can claim tokens"
        );
        // TODO: Check whether payable casting is safe here
        _refundAndBurnTickets(payable(msg.sender), groupId, 1);

        IExhibitRegistry delegate = IExhibitRegistry(group.exhibit);
        tokenId = delegate.mint(msg.sender, group.exhibitId, metadataUri);
        // TODO: take metadata
        emit Claimed(msg.sender, groupId, group.exhibit, tokenId);
        return (delegate, tokenId);
    }

    function finalizeOnLost(uint192 groupId) public {
        // TODO: Refund the remaining contributions pro rata when won/lost/expired
    }

    function getRefundableContributionPerTicket(
        uint192 groupId
    ) public view returns (uint256 refundPerTicket) {
        Group storage group = getValidGroup(groupId);
        require(
            group.status == GroupStatus.FINALIZED,
            "The group is not finalized"
        );
        uint256 surplus = group.totalContribution - group.purchasePrice;
        return surplus / TICKET_SUPPLY_PER_GROUP;
    }

    function _refundAndBurnTickets(
        address payable contributor,
        uint192 groupId,
        uint64 ticketCount
    ) internal {
        uint256 refund = getRefundableContributionPerTicket(groupId) *
            ticketCount;

        if (refund > 0) {
            (bool sent, ) = contributor.call{value: msg.value}("");
            require(sent, "Failed to refund");
        }
        _burn(msg.sender, groupId, ticketCount);
    }

    //
    // Group-Token Relationship
    //

    /**
     * @dev Group ID is simply used as its corresponding ERC1155 token (ticket) ID
     */
    function getTokenId(uint192 groupId) internal pure returns (uint256) {
        return groupId;
    }

    //
    // Registry-related views
    //

    function uri(uint256 id) public view override returns (string memory) {
        // TODO: Implement this
        return Strings.toString(id);
    }

    //
    // Group-related views
    //

    function getValidGroup(
        uint192 groupId
    ) internal view returns (Group storage) {
        require(groupId <= groupCount, "Invalid groupId");
        return groups[groupId];
    }

    function getGroupCount() public view returns (uint192) {
        return groupCount;
    }

    function getGroupInfo(
        uint192 groupId
    )
        public
        view
        returns (
            address creator,
            uint256 targetMaxPrice,
            uint96 ticketsBought,
            GroupStatus status
        )
    {
        Group storage group = getValidGroup(groupId);
        return (
            group.creator,
            group.targetMaxPrice,
            group.ticketsBought,
            group.status
        );
    }

    function getGroupTotalContribution(
        uint192 groupId
    ) public view returns (uint256 totalContribution) {
        return getValidGroup(groupId).totalContribution;
    }

    //
    // Ticket
    //

    function getTickets(
        address inquired,
        uint192 groupId
    ) public view returns (uint256) {
        return balanceOf(inquired, getTokenId(groupId));
    }

    function isCreator(
        address inquired,
        uint192 groupId
    ) public view returns (bool) {
        return groups[groupId].creator == inquired;
    }

    function hasShare(
        address inquired,
        uint192 groupId
    ) public view returns (bool) {
        return getTickets(inquired, groupId) > 0;
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
