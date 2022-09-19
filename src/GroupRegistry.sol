// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "openzepplin-contracts/contracts/utils/Strings.sol";
import {ERC1155} from "openzepplin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {IERC721} from "openzepplin-contracts/contracts/token/ERC721/IERC721.sol";
import {AccessControl} from "openzepplin-contracts/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "openzepplin-contracts/contracts/security/ReentrancyGuard.sol";

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
    bytes32 public constant ROLE_ADMIN = keccak256("ADMIN");

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
        _grantRole(ROLE_ADMIN, msg.sender);
        // TODO: code it up with config passing
        cryptoPunksMarket = CryptoPunksMarket(cryptoPunksMarketAddress);
        exhibitRegistry = IExhibitRegistry(exhibitRegistryAddress);
    }

    function create(uint256 targetPunkId, uint256 targetMaxPrice)
        external
        returns (uint192 groupId)
    {
        groupId = ++groupCount;
        uint64 totalTicketSupply = 100;
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

    function contribute(uint192 groupId, uint64 ticketQuantity)
        external
        payable
    {
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

    function buy(uint192 groupId) external nonReentrant {
        Group storage group = getValidGroup(groupId);
        require(
            hasShare(msg.sender, groupId),
            "Only ticket holders can initiate a buy"
        );
        // TODO: send only the necessary amount of ETH
        //  within available funds from the group
        // cf. Offer offer = punksOfferedForSale[punkIndex];
        uint256 punkId = group.targetPunkIndex;
        cryptoPunksMarket.buyPunk{value: group.totalContribution}(punkId);
        require(
            cryptoPunksMarket.punkIndexToAddress(punkId) == address(this),
            "Unexpected ownership"
        );
        group.status = GroupStatus.WON;
        emit GroupWon(groupId);
        finalizeWon(groupId);
    }

    // Also for retry
    function finalizeWon(uint192 groupId) public {
        Group storage group = getValidGroup(groupId);
        require(group.status == GroupStatus.WON, "The group has not won");
        require(
            address(exhibitRegistry) != address(0x0),
            "Exhibit registry must be set"
        );

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
        group.status = GroupStatus.FINALIZED;
    }

    function claim(uint192 groupId, string calldata metadataUri)
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
            "Only its stakeholders can claim tokens"
        );

        _burn(msg.sender, groupId, 1);
        IExhibitRegistry delegate = IExhibitRegistry(group.exhibit);
        uint256 tokenId = delegate.mint(
            msg.sender,
            group.exhibitId,
            metadataUri
        );
        // TODO: take metadata
        emit Claimed(msg.sender, groupId, group.exhibit, tokenId);
        return (delegate, tokenId);
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

    function getValidGroup(uint192 groupId)
        internal
        view
        returns (Group storage)
    {
        require(groupId <= groupCount, "Invalid groupId");
        return groups[groupId];
    }

    function getGroupCount() public view returns (uint192) {
        return groupCount;
    }

    // FIXME: not a good design
    function getGroupStatus(uint192 groupId) public view returns (GroupStatus) {
        Group storage group = groups[groupId];
        if (
            group.status == GroupStatus.OPEN && group.expiry >= block.timestamp
        ) {
            return GroupStatus.EXPIRED;
        }
        return group.status;
    }

    function getGroupInfo(uint192 groupId)
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

    //
    // Ticket
    //

    function getTickets(address inquired, uint192 groupId)
        public
        view
        returns (uint256)
    {
        return balanceOf(inquired, getTokenId(groupId));
    }

    function isCreator(address inquired, uint192 groupId)
        public
        view
        returns (bool)
    {
        return groups[groupId].creator == inquired;
    }

    function hasShare(address inquired, uint192 groupId)
        public
        view
        returns (bool)
    {
        return getTickets(inquired, groupId) > 0;
    }

    //
    // Admin
    //

    function airdrop(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyRole(ROLE_ADMIN) {
        _mintBatch(to, ids, amounts, "");
    }

    //
    // Internals
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // TODO: fallback
}
