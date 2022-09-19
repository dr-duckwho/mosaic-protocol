// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "openzepplin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {SafeCast} from "openzepplin-contracts/contracts/utils/math/SafeCast.sol";
import {AccessControl} from "openzepplin-contracts/contracts/access/AccessControl.sol";

import {CryptoPunksMarket} from "./external/CryptoPunksMarket.sol";

import {IExhibitRegistry} from "./IExhibitRegistry.sol";
import {GroupRegistry} from "./GroupRegistry.sol";

// TODO: Wire with Museum
// TODO: Generalize for token contracts other than CryptoPunksMarket
// TODO: Introduce `reconstitute` with claimed token tracking/oracle floor price retrieval
// TODO: Reconsider the ID scheme so that the same origin contract's same groups map to the same ID (contract, group) => (internal id)
contract ExhibitRegistry is IExhibitRegistry, ERC1155, AccessControl {
    using SafeCast for uint256;

    bytes32 public constant ROLE_ADMIN = keccak256("ADMIN");
    bytes32 public constant ROLE_MINT_AUTHORITY = keccak256("MINT_AUTHORITY");

    uint256 public constant MONO_ID_BITS = 64;
    uint256 constant MONO_ID_BITMASK = (1 << (MONO_ID_BITS + 1)) - 1; // lower 64 bits

    struct Oeuvre {
        address tokenContract;
        uint256 tokenId;
    }

    /**
     * @dev used as a `exhibitId`, starting from 1.
     */
    uint192 public exhibitCount;

    mapping(uint192 => Oeuvre) private oeuvreByExhibit;

    /**
     * @dev 0 represents the original; each mono is assigned an ID starting from 1.
     */
    mapping(uint192 => uint64) private monoIdByExhibit;

    /**
     * @dev tokenId (exhibitId + monoId) => uri
     */
    mapping(uint256 => string) private metadata;

    /**
     * @dev to calculate governance quorum and token circulation
     */
    mapping(uint192 => uint64) private claimableCount;
    mapping(uint192 => uint64) private claimedCount;

    address public mintAuthority;
    CryptoPunksMarket public cryptoPunksMarket;

    constructor(address _mintAuthority, address cryptoPunksMarketAddress)
        ERC1155("MOSAIC")
    {
        _grantRole(ROLE_ADMIN, msg.sender);
        setMintAuthority(_mintAuthority);
        cryptoPunksMarket = CryptoPunksMarket(cryptoPunksMarketAddress);
    }

    function setMintAuthority(address _mintAuthority)
        public
        onlyRole(ROLE_ADMIN)
    {
        mintAuthority = _mintAuthority;
    }

    //
    // For mint authority
    //
    function create(
        address originalTokenContract,
        uint256 originalTokenId,
        uint64 totalClaimableCount
    )
        external
        override
        onlyRole(ROLE_MINT_AUTHORITY)
        returns (uint192 exhibitId)
    {
        require(
            originalTokenContract == address(cryptoPunksMarket),
            "Must be CryptoPunks"
        );
        require(
            cryptoPunksMarket.punkIndexToAddress(originalTokenId) ==
                address(this),
            "This must own the punk now"
        );
        ++exhibitCount;
        ++monoIdByExhibit[exhibitCount];
        oeuvreByExhibit[exhibitCount] = Oeuvre(
            originalTokenContract,
            originalTokenId
        );
        claimableCount[exhibitCount] = totalClaimableCount;
        return exhibitCount;
    }

    function mint(
        address contributor,
        uint192 exhibitId,
        string calldata metadataUri
    )
        external
        override
        onlyRole(ROLE_MINT_AUTHORITY)
        returns (uint256 erc1155TokenId)
    {
        require(
            monoIdByExhibit[exhibitId] > 0,
            "Group must be initialized first"
        );
        uint64 monoId = monoIdByExhibit[exhibitId]++;
        metadata[exhibitId] = metadataUri;
        _mint(contributor, toErc1155Id(exhibitId, monoId), 1, "");
        claimedCount[exhibitId]++;

        // TODO: handle metadataUri

        return toErc1155Id(exhibitId, monoId);
    }

    //
    // Helpers
    //
    function toErc1155Id(uint192 exhibitId, uint64 monoId)
        public
        pure
        returns (uint256)
    {
        return (uint256(exhibitId) << MONO_ID_BITS) | uint256(monoId);
    }

    function toGroupMonoIds(uint256 erc1155Id)
        public
        pure
        returns (uint192 exhibitId, uint64 monoId)
    {
        return (
            uint192(erc1155Id >> MONO_ID_BITS),
            uint64(erc1155Id & MONO_ID_BITMASK)
        );
    }

    //
    // ERC1155
    //
    function uri(uint256 id) public view override returns (string memory) {
        return metadata[id];
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
}
