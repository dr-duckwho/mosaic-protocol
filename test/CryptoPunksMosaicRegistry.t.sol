// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TestUtils} from "./TestUtils.sol";

import {CryptoPunksMosaicRegistry} from "../src/CryptoPunksMosaicRegistry.sol";
import {MockCryptoPunksMarketProvider} from "./MockCryptoPunksMarketProvider.sol";
import "./MockCryptoPunksMosaicRegistry.sol";

contract CryptoPunksMosaicRegistryTest is Test, TestUtils {
    address public mintAuthority;
    CryptoPunksMosaicRegistry public mosaicRegistry;
    MockCryptoPunksMarketProvider public mockCryptoPunksMarket;

    function setUp() public {
        mintAuthority = _randomAddress();
        mockCryptoPunksMarket = new MockCryptoPunksMarketProvider();
        mosaicRegistry = new MockCryptoPunksMosaicRegistry(mintAuthority, address(mockCryptoPunksMarket));
    }

    // TODO(@jyterencekim): Write unit tests for the main functions
    function test_toMosaicId_fromMosaicId() public {
        // given
        uint192 expectedGroupId = 581019;
        uint64 expectedMonoId = 830404;

        // when
        uint256 mosaicId = mosaicRegistry.toMosaicId(expectedGroupId, expectedMonoId);
        (uint192 originalId, uint64 monoId) = mosaicRegistry.fromMosaicId(mosaicId);

        // then
        assertEq(originalId, expectedGroupId);
        assertEq(monoId, expectedMonoId);
    }
}
