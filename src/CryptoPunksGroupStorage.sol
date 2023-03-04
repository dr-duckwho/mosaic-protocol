// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoPunksGroupRegistry.sol";

library CryptoPunksGroupStorage {
    bytes32 constant POSITION = keccak256("CryptoPunksGroupStorage");

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
    }

    function get() internal pure returns (Storage storage data) {
        bytes32 position = POSITION;
        assembly {
            data.slot := position
        }
    }
}
