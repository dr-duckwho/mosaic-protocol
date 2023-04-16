// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../src/CryptoPunksMosaicRegistry.sol";
import "../src/CryptoPunksMosaicStorage.sol";
import "mockprovider/MockProvider.sol";

contract MockCryptoPunksMosaicRegistry is MockProvider, CryptoPunksMosaicRegistry {

    bool private mockingBidAcceptable;
    bool private isMockBidAcceptable;

    bool private mockingGetPerMonoResaleFund;
    uint256 private mockGetPerMonoResaleFund;

    bool private mockingSumBidResponses;
    uint64 private mockBidResponseYes;
    uint64 private mockBidResponseNo;

    bool private mockingAverageReservePriceProposals;
    uint256 mockAverageReservePriceProposal;

    constructor() public CryptoPunksMosaicRegistry() {}

    function setLatestOriginalId(uint192 value) public {
        CryptoPunksMosaicStorage.get().latestOriginalId = value;
    }

    function setOriginal(uint192 originalId, Original calldata original) public {
        CryptoPunksMosaicStorage.get().originals[originalId] = original;
    }

    function setNextMonoId(uint192 originalId, uint64 nextMonoId) public {
        CryptoPunksMosaicStorage.get().nextMonoIds[originalId] = nextMonoId;
    }

    function setMono(uint256 mosaicId, Mono calldata mono) public {
        CryptoPunksMosaicStorage.get().monos[mosaicId] = mono;
    }

    function setBid(uint256 bidId, Bid calldata bid) public {
        CryptoPunksMosaicStorage.get().bids[bidId] = bid;
    }

    function setBidDeposits(uint256 bidId, uint256 bidDeposit) public {
        CryptoPunksMosaicStorage.get().bidDeposits[bidId] = bidDeposit;
    }

    function setResalePrice(uint192 originalId, uint256 resalePrice) public {
        CryptoPunksMosaicStorage.get().resalePrices[originalId] = resalePrice;
    }

    function getNextMonoId(uint192 originalId) public returns (uint64) {
        return CryptoPunksMosaicStorage.get().nextMonoIds[originalId];
    }

    function getMono(uint256 mosaicId) public returns (Mono memory) {
        return CryptoPunksMosaicStorage.get().monos[mosaicId];
    }

    function incrementNextMonoId(uint192 originalId) public {
        setNextMonoId(originalId, getNextMonoId(originalId) + 1);
    }

    function mockMint(address to, uint256 mosaicId) public {
        _mint(to, mosaicId);
        (uint192 originalId, ) = fromMosaicId(mosaicId);
        incrementNextMonoId(originalId);
    }

    function mockBidAcceptable(bool enabled, bool value) public {
        mockingBidAcceptable = enabled;
        isMockBidAcceptable = value;
    }

    // TODO: Use MockProvider if possible
    function isBidAcceptable(uint192 originalId) public override view returns (bool) {
        if (mockingBidAcceptable) {
            return isMockBidAcceptable;
        }
        return super.isBidAcceptable(originalId);
    }

    function mockPerMonoResaleFund(bool enabled, uint256 value) public {
        mockingGetPerMonoResaleFund = enabled;
        mockGetPerMonoResaleFund = value;
    }

    function getPerMonoResaleFund(uint192 originalId) public override view returns (uint256) {
        if (mockingGetPerMonoResaleFund) {
            return mockGetPerMonoResaleFund;
        }
        return super.getPerMonoResaleFund(originalId);
    }

    function mockSumBidResponses(bool enabled, uint64 yes, uint64 no) public {
        mockingSumBidResponses = enabled;
        mockBidResponseYes = yes;
        mockBidResponseNo = no;
    }

    function sumBidResponses(uint192 originalId) public override view returns (uint64, uint64) {
        if (mockingSumBidResponses) {
            return (mockBidResponseYes, mockBidResponseNo);
        }
        return super.sumBidResponses(originalId);
    }

    function mockAverageReservePriceProposals(bool enabled, uint256 value) public {
        mockingAverageReservePriceProposals =  enabled;
        mockAverageReservePriceProposal = value;
    }

    function getAverageReservePriceProposals(uint192 originalId) public override view returns (uint256) {
        if (mockingAverageReservePriceProposals) {
            return mockAverageReservePriceProposal;
        }
        return super.getAverageReservePriceProposals(originalId);
    }
}