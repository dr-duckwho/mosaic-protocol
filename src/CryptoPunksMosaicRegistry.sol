// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {SafeCast} from "@openzeppelin/utils/math/SafeCast.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

import "./external/ICryptoPunksMarket.sol";
import "./ICryptoPunksMosaicRegistry.sol";
import "./CryptoPunksGroupRegistry.sol";

// TODO: Wire with Museum
// TODO: Generalize for token contracts other than CryptoPunksMarket
// TODO: Introduce `reconstitute` with claimed token tracking/oracle floor price retrieval
// TODO: Reconsider the ID scheme so that the same origin contract's same groups map to the same ID (contract, group) => (internal id)
contract CryptoPunksMosaicRegistry is
    ICryptoPunksMosaicRegistry,
    ERC1155,
    AccessControl
{
    using SafeCast for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant MONO_ID_BITS = 64;
    uint256 private constant MONO_ID_BITMASK = (1 << (MONO_ID_BITS + 1)) - 1; // lower 64 bits

    ICryptoPunksMarket public immutable cryptoPunksMarket;

    string public invalidMetadataUri;

    /**
     * @dev used as a `originalId`, starting from 1.
     */
    uint192 public latestOriginalId;

    mapping(uint192 => Original) private originals;

    /**
     * @dev 0 represents the Original; each Mono is assigned an ID starting from 1.
     *      originalId => latestMonoId
     */
    mapping(uint192 => uint64) public latestMonoIds;

    /**
     * @dev mosaicId (originalId + monoId) => Mono
     */
    mapping(uint256 => Mono) private monos;

    constructor(
        address _mintAuthority,
        address cryptoPunksMarketAddress
    ) ERC1155("CryptoPunks Mosaic") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, _mintAuthority);
        cryptoPunksMarket = ICryptoPunksMarket(cryptoPunksMarketAddress);
    }

    //
    // For mint authority
    //
    function create(
        uint256 punkId,
        uint64 totalClaimableCount,
        uint256 purchasePrice,
        uint256 minReservePrice,
        uint256 maxReservePrice
    ) external override onlyRole(MINTER_ROLE) returns (uint192 originalId) {
        require(
            cryptoPunksMarket.punkIndexToAddress(punkId) == address(this),
            "The contract must own the punk"
        );
        originalId = ++latestOriginalId;
        ++latestMonoIds[originalId];
        originals[originalId] = Original({
            id: originalId,
            punkId: punkId,
            totalMonoCount: totalClaimableCount,
            claimedMonoCount: 0,
            purchasePrice: purchasePrice,
            minReservePrice: minReservePrice,
            maxReservePrice: maxReservePrice,
            status: OriginalStatus.Active,
            // TODO(@kimhodol): Change expiry and price value
            bid: Bid({bidder: address(0x0), expiry: 0, price: 0})
        });
        return originalId;
    }

    function mint(
        address contributor,
        uint192 originalId
    ) external override onlyRole(MINTER_ROLE) returns (uint256 mosaicId) {
        require(
            latestMonoIds[originalId] > 0,
            "Original must be initialized first"
        );
        uint64 monoId = latestMonoIds[originalId]++;
        mosaicId = toMosaicId(originalId, monoId);
        // TODO(@jyterencekim): Take proposedReservePrice
        // TODO: Handle metadataUri
        monos[mosaicId] = Mono({
            mosaicId: mosaicId,
            metadataUri: "",
            governanceOptions: MonoGovernanceOptions({
                proposedReservePrice: 0,
                bidResponse: MonoBidResponse.None
            })
        });
        originals[originalId].claimedMonoCount++;
        _mint(contributor, mosaicId, 1, "");

        return mosaicId;
    }

    function bid(uint192 originalId, uint256 price) external {
        // TODO: Implement this
    }

    //
    // Views
    //
    function getMono(
        uint192 originalId,
        uint64 monoId
    ) external view returns (Mono memory) {
        return monos[toMosaicId(originalId, monoId)];
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

    function getMonoLifeCycle(
        uint256 mosaicId
    ) public view returns (MonoLifeCycle) {
        // TODO: Check valid mosaicId
        Mono storage mono = monos[mosaicId];
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        Original storage original = originals[originalId];
        if (original.status == OriginalStatus.Sold) {
            return MonoLifeCycle.Dead;
        }
        if (bytes(mono.metadataUri).length == 0) {
            return MonoLifeCycle.Raw;
        }
        return MonoLifeCycle.Active;
    }

    function setInvalidMetadataUri(
        string calldata _uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        invalidMetadataUri = _uri;
    }

    //
    // ERC1155
    //
    function uri(
        uint256 mosaicId
    ) public view override returns (string memory) {
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        if (originals[originalId].status == OriginalStatus.Sold) {
            return invalidMetadataUri;
        }
        return monos[mosaicId].metadataUri;
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
}
