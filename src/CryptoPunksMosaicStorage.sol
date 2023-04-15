// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoPunksMosaicRegistry.sol";

library CryptoPunksMosaicStorage {
    bytes32 constant STORAGE_POSITION = keccak256("CryptoPunksMosaicStorage");
    bytes32 constant ADMIN_GOVERNANCE_OPTIONS_POSITION =
        keccak256("CryptoPunksMosaicAdminGovernanceOptions");

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

    struct AdminGovernanceOptions {
        /**
         * @dev explicit flag for activation; may be useful in overriding the global options per original
         */
        bool isSet;
        /**
         * @dev reserve price weighted sums are valid only if more holders than this threshold have set their
         *  reserve price proposals
         */
        // default 3000 = 30%
        uint256 reservePriceProposalTurnoutThresholdBps;
        // default 604800 = 1 week
        uint40 bidExpiryBlockSeconds;
        // default 3000 = 30%
        uint256 bidAcceptanceThresholdBps;
    }

    function get() internal pure returns (Storage storage data) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            data.slot := position
        }
    }

    function getAdminGovernanceOptions()
        internal
        pure
        returns (AdminGovernanceOptions storage data)
    {
        bytes32 position = ADMIN_GOVERNANCE_OPTIONS_POSITION;
        assembly {
            data.slot := position
        }
    }

    function isSetAdminGovernanceOptions() internal view returns (bool) {
        AdminGovernanceOptions storage data = getAdminGovernanceOptions();
        return
            data.isSet &&
            data.reservePriceProposalTurnoutThresholdBps > 0 &&
            data.bidExpiryBlockSeconds > 0 &&
            data.bidAcceptanceThresholdBps > 0;
    }
}
