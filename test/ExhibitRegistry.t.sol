// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TestUtils} from "./TestUtils.sol";

import {ExhibitRegistry} from "../src/ExhibitRegistry.sol";
import {MockCryptoPunksMarketProvider} from "./MockCryptoPunksMarketProvider.sol";

contract ExhibitRegistryTest is Test, TestUtils {
    address public mintAuthority;
    ExhibitRegistry public exhibitRegistry;
    MockCryptoPunksMarketProvider public mockCryptoPunksMarket;

    function setUp() public {
        mintAuthority = _randomAddress();
        mockCryptoPunksMarket = new MockCryptoPunksMarketProvider();
        exhibitRegistry = new ExhibitRegistry(mintAuthority, address(mockCryptoPunksMarket));
    }

    function test_id() public {
        // given
        uint192 groupId = 581019;
        uint64 monoId = 830404;

        // when
        uint256 erc1155Id = exhibitRegistry.toErc1155Id(groupId, monoId);
        (uint192 convertedGroupId, uint64 convertedMonoId) = exhibitRegistry.toGroupMonoIds(erc1155Id);

        // then
        assertEq(convertedGroupId, groupId);
        assertEq(convertedMonoId, monoId);
    }
}
