// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UsingCryptoPunksMosaicRegistryStructs {
    struct Original {
        uint192 id;
        uint256 punkId;
        /**
         * @dev To calculate governance quorum and token circulation.
         *      Corresponds to total ticket circulation per group.
         */
        uint128 totalMonoCount;
        uint128 claimedMonoCount;
    }
}
