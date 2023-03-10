// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TestUtils} from "./TestUtils.sol";

import {ERC1967Proxy} from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

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

        MockCryptoPunksMosaicRegistry impl = new MockCryptoPunksMosaicRegistry();
        mosaicRegistry = MockCryptoPunksMosaicRegistry(payable(new ERC1967Proxy(address(impl), "")));
        mosaicRegistry.initialize(address(museum));

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
        assertEq(mosaicRegistry.getNextMonoId(originalId), 1);
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
        mosaicRegistry.setNextMonoId(originalId, 1);

        // when
        vm.prank(mintAuthority);
        uint256 mosaicId = mosaicRegistry.mint(alice, originalId);

        // then
        assertEq(mosaicRegistry.balanceOf(alice), 1);
        assertEq(mosaicRegistry.ownerOf(mosaicId), alice);

        Mono memory mono = mosaicRegistry.getMono(mosaicId);
        assertEq(mono.mosaicId, mosaicId);
        assertEq(mono.presetId, 0);
        Original memory original = mosaicRegistry.getOriginal(originalId);
        assertEq(original.claimedMonoCount, 1);
    }

    function test_proposeReservePrice() public {
        // given
        address alice = _randomAddress();
        uint192 originalId = 530923;
        uint64 monoId = 581019;
        uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
        uint256 price = 100 ether;

        Original memory original = Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 0,
            purchasePrice: 100 ether,
            minReservePrice: price / 2,
            maxReservePrice: price * 5,
            status: OriginalStatus.Active,
            activeBidId: 0,
            metadataBaseUri: ""
        });
        mosaicRegistry.setOriginal(originalId, original);

        // set up the ownership
        mosaicRegistry.mockMint(alice, mosaicId);

        // initial condition
        Mono memory mono = mosaicRegistry.getMono(originalId, monoId);
        assertEq(mono.governanceOptions.proposedReservePrice, 0);

        // when
        vm.prank(alice);
        mosaicRegistry.proposeReservePrice(mosaicId, price);

        // then
        mono = mosaicRegistry.getMono(originalId, monoId);
        assertEq(mono.governanceOptions.proposedReservePrice, price);
    }

    function test_refundBidDeposit() public {
        // given
        address bidder = _randomAddress();
        uint192 originalId = 810920;
        uint256 timestamp = 830404;
        uint256 bidId = mosaicRegistry.toBidId(originalId, bidder, timestamp);
        uint256 bidFund = 100 ether;
        uint256 registryFund = 150 ether;

        // a rejected fund
        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(bidder),
            createdAt: uint40(timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: bidFund,
            state: BidState.Rejected
        }));
        vm.deal(address(mosaicRegistry), registryFund);
        mosaicRegistry.setBidDeposits(bidId, bidFund);
        assertEq(bidder.balance, 0);

        // when
        vm.prank(bidder);
        mosaicRegistry.refundBidDeposit(bidId);

        // then
        assertEq(bidder.balance, bidFund);
        assertEq(address(mosaicRegistry).balance, registryFund - bidFund);
        Bid memory bid = mosaicRegistry.getBid(bidId);
        assert(bid.state == BidState.Refunded);
    }

    function test_respondToBid() public {
        // given
        address alice = _randomAddress();
        uint192 originalId = 530923;
        uint64 monoId = 581019;
        uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
        uint256 bidId = mosaicRegistry.toBidId(originalId, alice, block.timestamp);

        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(alice),
            createdAt: uint40(block.timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: 100 ether,
            state: BidState.Proposed
        }));
        Original memory original = Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: bidId,
            metadataBaseUri: ""
        });
        mosaicRegistry.setOriginal(originalId, original);

        // set up the ownership
        mosaicRegistry.mockMint(alice, mosaicId);

        // when
        vm.prank(alice);
        mosaicRegistry.respondToBid(mosaicId, MonoBidResponse.No);

        // then
        Mono memory mono = mosaicRegistry.getMono(originalId, monoId);
        MonoGovernanceOptions memory governanceOptions = mono.governanceOptions;
        assertEq(governanceOptions.bidId, bidId);
        assert(governanceOptions.bidResponse == MonoBidResponse.No);
    }

    function test_finalizeProposedBid() public {
        doTest_finalizeProposedBid(true);
        doTest_finalizeProposedBid(false);
    }

    function doTest_finalizeProposedBid(bool isBidAcceptable) private {
        // given
        address alice = _randomAddress();
        uint192 originalId = 530923;
        uint64 monoId = 581019;
        uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
        uint256 bidId = mosaicRegistry.toBidId(originalId, alice, block.timestamp);

        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(alice),
            createdAt: uint40(block.timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: 100 ether,
            state: BidState.Proposed
        }));

        // when
        mosaicRegistry.mockBidAcceptable(true, isBidAcceptable);
        vm.warp(block.timestamp + mosaicRegistry.BID_EXPIRY() + 1);

        vm.expectEmit(true, true, false, false);
        if (isBidAcceptable) {
            emit BidAccepted(bidId, originalId);
        } else {
            emit BidRejected(bidId, originalId);
        }

        vm.prank(alice);
        BidState result = mosaicRegistry.finalizeProposedBid(bidId);

        // then
        assert(result == (isBidAcceptable ? BidState.Accepted : BidState.Rejected));
    }

    function test_finalizeAcceptedBid() public {
        // given
        address bidder = _randomAddress();
        uint192 originalId = 530923;
        uint64 monoId = 581019;
        uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
        uint256 bidId = mosaicRegistry.toBidId(originalId, bidder, block.timestamp);

        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(bidder),
            createdAt: uint40(block.timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: 100 ether,
            state: BidState.Accepted
        }));
        Original memory original = Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: bidId,
            metadataBaseUri: ""
        });
        mosaicRegistry.setOriginal(originalId, original);

        // market
        mockCryptoPunksMarket.givenQueryReturn(
            abi.encodePacked(ICryptoPunksMarket.transferPunk.selector), abi.encodePacked(true)
        );

        // when
        vm.expectEmit(true, true, false, false);
        emit BidWon(bidId, originalId);

        address actor = _randomAddress();
        vm.prank(actor);
        mosaicRegistry.finalizeAcceptedBid(bidId);

        // then
        Bid memory bid = mosaicRegistry.getBid(bidId);
        assert(bid.state == BidState.Won);
        Original memory changedOriginal = mosaicRegistry.getOriginal(originalId);
        assert(changedOriginal.status == OriginalStatus.Sold);
    }

    function test_refundOnSold() public {
        // given
        uint192 originalId = 810920;
        uint64 totalMonoCount = 100;
        mosaicRegistry.setNextMonoId(originalId, totalMonoCount + 1);

        address alice = _randomAddress();
        uint64 ownedMonoCount = 30;

        // assume that Alice has [1,30] Monos
        for (uint64 monoId = 1; monoId <= ownedMonoCount; monoId++) {
            mosaicRegistry.mockMint(alice, mosaicRegistry.toMosaicId(originalId, monoId));
        }

        // given the fund status
        uint256 registryFund = 100 ether;
        vm.deal(address(mosaicRegistry), registryFund);
        assertEq(alice.balance, 0);

        // assuming 1 ETH refund per Mono
        uint256 refundPerMono = 1 ether;
        mosaicRegistry.mockPerMonoResaleFund(true, refundPerMono);

        // when
        vm.expectEmit(true, true, false, false);
        emit MonoRefunded(originalId, alice);

        vm.prank(alice);
        mosaicRegistry.refundOnSold(originalId);

        // then
        uint256 expectedRefundSum = refundPerMono * ownedMonoCount;
        assertEq(alice.balance, expectedRefundSum);
        assertEq(address(mosaicRegistry).balance, registryFund - expectedRefundSum);
    }

    function test_sumReservePriceProposals() public {
        // given
        uint192 originalId = 810920;
        uint64 totalMonoCount = 100;
        mosaicRegistry.setNextMonoId(originalId, totalMonoCount + 1);

        uint64 monosWithProposalCount = 30;
        uint256 proposedReservePriceAverage = 77 ether;

        // assume that [1,30] Monos have valid price proposals
        for (uint64 monoId = 1; monoId <= monosWithProposalCount; monoId++) {
            uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
            Mono memory mono = Mono({
                mosaicId: mosaicId,
                presetId: 0,
                governanceOptions: MonoGovernanceOptions({
                    proposedReservePrice: proposedReservePriceAverage,
                    bidResponse: MonoBidResponse.None,
                    bidId: 0
                })
            });
            mosaicRegistry.setMono(mosaicId, mono);
        }

        // then
        (uint64 validCount, uint256 priceSum) = mosaicRegistry.sumReservePriceProposals(originalId);
        assertEq(validCount, monosWithProposalCount);
        assertEq(priceSum, monosWithProposalCount * proposedReservePriceAverage);
    }

    function test_sumBidResponses() public {
        // given
        uint192 originalId = 810920;
        uint64 totalMonoCount = 100;
        mosaicRegistry.setNextMonoId(originalId, totalMonoCount + 1);

        address bidder = _randomAddress();
        uint256 bidId = mosaicRegistry.toBidId(originalId, bidder, block.timestamp);

        uint64 monosWithYesCount = 30;
        uint64 monosWithNoCount = 20;

        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(bidder),
            createdAt: uint40(block.timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: 100 ether,
            state: BidState.Proposed
        }));
        mosaicRegistry.setOriginal(originalId, Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: bidId,
            metadataBaseUri: ""
        }));

        for (uint64 monoId = 1; monoId <= totalMonoCount; monoId++) {
            uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
            // assuming yes for [1..yesCount], no for [yesCount + 1..yesCount + noCount]
            // and none for the rest
            MonoBidResponse response = MonoBidResponse.None;
            if (monoId <= monosWithYesCount) {
                response = MonoBidResponse.Yes;
            } else if (monoId <= monosWithYesCount + monosWithNoCount) {
                response = MonoBidResponse.No;
            }
            Mono memory mono = Mono({
                mosaicId: mosaicId,
                presetId: 0,
                governanceOptions: MonoGovernanceOptions({
                    proposedReservePrice: 60 ether,
                    bidResponse: response,
                    bidId: bidId
                })
            });
            mosaicRegistry.setMono(mosaicId, mono);
        }

        // then
        (uint64 yes, uint256 no) = mosaicRegistry.sumBidResponses(originalId);
        assertEq(yes, monosWithYesCount);
        assertEq(no, monosWithNoCount);
    }

    function test_sumBidResponses_noOngoingActiveBid() public {
        // given
        uint192 originalId = 810920;
        uint64 totalMonoCount = 100;
        mosaicRegistry.setNextMonoId(originalId, totalMonoCount + 1);

        address bidder = _randomAddress();
        uint256 bidId = mosaicRegistry.toBidId(originalId, bidder, block.timestamp);

        uint64 monosWithYesCount = 30;
        uint64 monosWithNoCount = 20;
        mosaicRegistry.setOriginal(originalId, Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: 0,
            metadataBaseUri: ""
        }));

        for (uint64 monoId = 1; monoId <= totalMonoCount; monoId++) {
            uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
            // assuming yes for [1..yesCount], no for [yesCount + 1..yesCount + noCount]
            // and none for the rest
            MonoBidResponse response = MonoBidResponse.None;
            if (monoId <= monosWithYesCount) {
                response = MonoBidResponse.Yes;
            } else if (monoId <= monosWithYesCount + monosWithNoCount) {
                response = MonoBidResponse.No;
            }
            Mono memory mono = Mono({
            mosaicId: mosaicId,
            presetId: 0,
            governanceOptions: MonoGovernanceOptions({
            proposedReservePrice: 60 ether,
            bidResponse: response,
            bidId: bidId
            })
            });
            mosaicRegistry.setMono(mosaicId, mono);
        }

        // then
        (uint64 yes, uint256 no) = mosaicRegistry.sumBidResponses(originalId);
        assertEq(yes, 0);
        assertEq(no, 0);
    }

    function test_sumBidResponses_halfValidResponses() public {
        // given
        uint192 originalId = 810920;
        uint64 totalMonoCount = 100;
        mosaicRegistry.setNextMonoId(originalId, totalMonoCount + 1);

        address bidder = _randomAddress();
        uint256 bidId = mosaicRegistry.toBidId(originalId, bidder, block.timestamp);

        uint64 monosWithYesCount = 30;
        uint64 monosWithNoCount = 20;
        mosaicRegistry.setBid(bidId, Bid({
            id: bidId,
            originalId: originalId,
            bidder: payable(bidder),
            createdAt: uint40(block.timestamp),
            expiry: mosaicRegistry.BID_EXPIRY(),
            price: 100 ether,
            state: BidState.Proposed
        }));
        mosaicRegistry.setOriginal(originalId, Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: bidId,
            metadataBaseUri: ""
        }));

        for (uint64 monoId = 1; monoId <= totalMonoCount; monoId++) {
            uint256 mosaicId = mosaicRegistry.toMosaicId(originalId, monoId);
            // assuming yes for [1..yesCount], no for [yesCount + 1..yesCount + noCount]
            // and none for the rest
            MonoBidResponse response = MonoBidResponse.None;
            if (monoId <= monosWithYesCount) {
                response = MonoBidResponse.Yes;
            } else if (monoId <= monosWithYesCount + monosWithNoCount) {
                response = MonoBidResponse.No;
            }
            Mono memory mono = Mono({
                mosaicId: mosaicId,
                presetId: 0,
                governanceOptions: MonoGovernanceOptions({
                    proposedReservePrice: 60 ether,
                    bidResponse: response,
                    // assumning odd-numbered responses are stale
                    bidId: bidId - (monoId % 2 == 0 ? 0 : 1)
                })
            });
            mosaicRegistry.setMono(mosaicId, mono);
        }

        // then
        (uint64 yes, uint256 no) = mosaicRegistry.sumBidResponses(originalId);
        assertEq(yes, monosWithYesCount / 2);
        assertEq(no, monosWithNoCount / 2);
    }

    function test_isBidAcceptable() public {
        doTest_isBidAcceptable(true);
        doTest_isBidAcceptable(false);
    }

    function doTest_isBidAcceptable(bool isAcceptable) private {
        // given
        uint192 originalId = 830404;
        uint64 yes = isAcceptable ? 51 : 49;
        uint64 no = 20;
        mosaicRegistry.mockSumBidResponses(true, yes, no);

        mosaicRegistry.setOriginal(originalId, Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: 100,
            claimedMonoCount: 100,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: 1234,
            metadataBaseUri: ""
        }));

        // then
        bool actual = mosaicRegistry.isBidAcceptable(originalId);
        assertEq(actual, isAcceptable);
    }

    function test_getPerMonoResaleFund() public {
        // given
        uint192 originalId = 530923;
        uint256 resalePrice = 183 ether;
        uint96 totalMonoSupply = 100;
        mosaicRegistry.setResalePrice(originalId, resalePrice);

        mosaicRegistry.setOriginal(originalId, Original({
            id: originalId,
            punkId: 1,
            totalMonoSupply: totalMonoSupply,
            claimedMonoCount: totalMonoSupply,
            purchasePrice: 100 ether,
            minReservePrice: 50 ether,
            maxReservePrice: 500 ether,
            status: OriginalStatus.Active,
            activeBidId: 1234,
            metadataBaseUri: ""
        }));

        // then
        uint256 actual = mosaicRegistry.getPerMonoResaleFund(originalId);
        assertEq(actual, 1.83 ether);
    }

    function test_toMosaicId_fromMosaicId() public {
        // given
        uint192 expectedOriginalId = 581019;
        uint64 expectedMonoId = 830404;

        // when
        uint256 mosaicId = mosaicRegistry.toMosaicId(expectedOriginalId, expectedMonoId);
        (uint192 originalId, uint64 monoId) = mosaicRegistry.fromMosaicId(mosaicId);

        // then
        assertEq(originalId, expectedOriginalId);
        assertEq(monoId, expectedMonoId);
    }
}
