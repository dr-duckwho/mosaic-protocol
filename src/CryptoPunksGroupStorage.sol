// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoPunksGroupRegistry.sol";

library CryptoPunksGroupStorage {
    bytes32 constant STORAGE_POSITION = keccak256("CryptoPunksGroupStorage");
    bytes32 constant ADMIN_GOVERNANCE_OPTIONS_POSITION =
        keccak256("CryptoPunksGroupAdminGovernanceOptions");

    struct Storage {
        /**
         * @dev Starts from 1.
         *  Must increment this first when creating a new group.
         */
        uint192 latestGroupId;
        mapping(uint192 => UsingCryptoPunksGroupRegistryStructs.Group) groups;
        /**
         * @dev groupId -> address -> shares (= the number of tickets bought)
         */
        mapping(uint192 => mapping(address => uint256)) refundableTickets;
        /**
         * @dev groupId -> bool, set true by {@code forceLose}
         */
        mapping(uint192 => bool) forceLost;
    }

    struct AdminGovernanceOptions {
        /**
         * @dev explicit flag for activation; may be useful in overriding the global options per original
         */
        bool isSet;
        // 7000 = 70%
        uint64 minReservePriceBps;
        // 500000 = 5000%
        uint64 maxReservePriceBps;
        /**
         * @dev Caution: DO NOT CHANGE if there is an active group with any contribution
         */
        uint64 ticketSupplyPerGroup;
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
}
