// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoPunksMosaicRegistry.sol";

library CryptoPunksMosaicStorage {
    bytes32 constant POSITION = keccak256("CryptoPunksMosaicStorage");

    struct Storage {
        string invalidMetadataUri;

        //
        // Models
        //

        // @dev used as a `originalId`, starting from 1.
        // TODO: Consider changing to nextOriginalId to avoid more gas consumption for the first group
        uint192 latestOriginalId;

        mapping(uint192 => UsingCryptoPunksMosaicRegistryStructs.Original) originals;

        // @dev 0 represents the Original; each Mono is assigned an ID starting from 1.
        //  The value represents the next ID to assign for a new Mono.
        //  originalId => nextMonoId
        mapping(uint192 => uint64) nextMonoIds;

        // @dev mosaicId (originalId + monoId) => Mono
        mapping(uint256 => UsingCryptoPunksMosaicRegistryStructs.Mono) monos;

        //
        // Reconstitution
        //

        // @dev bidId => Bid
        mapping(uint256 => UsingCryptoPunksMosaicRegistryStructs.Bid) bids;
        mapping(uint256 => uint256) bidDeposits;

        // @dev originalId => value
        mapping(uint192 => uint256) resalePrices;
    }

    function get() internal pure returns (Storage storage data) {
        bytes32 position = POSITION;
        assembly {
            data.slot := position
        }
    }
}
