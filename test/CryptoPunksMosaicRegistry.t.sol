// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TestUtils} from "./TestUtils.sol";

import {CryptoPunksMosaicRegistry} from "../src/CryptoPunksMosaicRegistry.sol";
import {MockCryptoPunksMarketProvider} from "./MockCryptoPunksMarketProvider.sol";
import "./MockCryptoPunksMosaicRegistry.sol";
import "../src/UsingCryptoPunksMosaicRegistryStructs.sol";

contract CryptoPunksMosaicRegistryTest is Test, TestUtils, UsingCryptoPunksMosaicRegistryStructs {
    MockCryptoPunksMosaicRegistry public mosaicRegistry;
    MockCryptoPunksMarketProvider public mockCryptoPunksMarket;
    CryptoPunksMuseum public museum;
    address public mintAuthority;

    function setUp() public {
        mockCryptoPunksMarket = new MockCryptoPunksMarketProvider();
        museum = new CryptoPunksMuseum(address(mockCryptoPunksMarket));
        mosaicRegistry = new MockCryptoPunksMosaicRegistry(address(museum));

        mintAuthority = _randomAddress();
        museum.setGroupRegistry(mintAuthority);
        museum.setMosaicRegistry(address(mosaicRegistry));
        museum.activate();
    }

    function test_create() public {
        // given
        uint256 punkId = 1;
        uint64 totalClaimableCount = 100;
        uint256 purchasePrice = 100 ether;
        uint256 minReservePrice = 70 ether;
        uint256 maxReservePrice = 500 ether;

        mockCryptoPunksMarket.setPunkIndexToAddress(punkId, address(mosaicRegistry));

        // when
        vm.prank(mintAuthority);
        uint192 originalId = mosaicRegistry.create(punkId, totalClaimableCount, purchasePrice, minReservePrice, maxReservePrice);

        // then
        assertEq(originalId, 1);
        assertEq(mosaicRegistry.latestMonoIds(originalId), 1);
        CryptoPunksMosaicRegistry.Original memory original = mosaicRegistry.getOriginal(originalId);
        assertEq(original.id, originalId);
        assertEq(original.punkId, punkId);
        assertEq(original.totalMonoSupply, totalClaimableCount);
        assertEq(original.claimedMonoCount, 0);
        assertEq(original.purchasePrice, purchasePrice);
        assertEq(original.minReservePrice, minReservePrice);
        assertEq(original.maxReservePrice, maxReservePrice);
        assert(original.status == UsingCryptoPunksMosaicRegistryStructs.OriginalStatus.Active);
        assertEq(original.activeBidId, 0);
    }

    function test_create_mustOwnPunk() public {
        // when & then
        vm.prank(mintAuthority);
        vm.expectRevert("The contract must own the punk");
        uint192 originalId = mosaicRegistry.create(1, 100, 100 ether, 70 ether, 500 ether);
    }

    function test_mint() public {
        // given
        address alice = _randomAddress();
        assertEq(mosaicRegistry.balanceOf(alice), 0);

        // assume that the original is initialized
        uint192 originalId = 830404;
        mosaicRegistry.setLatestMonoId(originalId, 1);

        // when
        vm.prank(mintAuthority);
        uint256 mosaicId = mosaicRegistry.mint(alice, originalId);

        // then
        assertEq(mosaicRegistry.balanceOf(alice), 1);
        assertEq(mosaicRegistry.ownerOf(mosaicId), alice);

        (uint256 actualMosaicId, uint8 actualPresetId, ) = mosaicRegistry.monos(mosaicId);
        assertEq(actualMosaicId, mosaicId);
        assertEq(actualPresetId, 0);
        Original memory original = mosaicRegistry.getOriginal(originalId);
        assertEq(original.claimedMonoCount, 1);
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
