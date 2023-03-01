// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../src/CryptoPunksMosaicRegistry.sol";
import "mockprovider/MockProvider.sol";

contract MockCryptoPunksMosaicRegistry is MockProvider, CryptoPunksMosaicRegistry {

    bool private mockingBidAcceptable;
    bool private isMockBidAcceptable;
    bool private mockingGetPerMonoResaleFund;
    uint256 private mockGetPerMonoResaleFund;

    constructor(address museumAddress) public CryptoPunksMosaicRegistry(museumAddress) {}

    function setLatestOriginalId(uint192 value) public {
        latestOriginalId = value;
    }

    function setOriginal(uint192 originalId, Original calldata original) public {
        originals[originalId] = original;
    }

    function setLatestMonoId(uint192 originalId, uint64 latestMonoId) public {
        latestMonoIds[originalId] = latestMonoId;
    }

    function setMono(uint256 mosaicId, Mono calldata mono) public {
        monos[mosaicId] = mono;
    }

    function setBid(uint256 bidId, Bid calldata bid) public {
        bids[bidId] = bid;
    }

    function setBidDeposits(uint256 bidId, uint256 bidDeposit) public {
        bidDeposits[bidId] = bidDeposit;
    }

    function setResalePrice(uint192 originalId, uint256 resalePrice) public {
        resalePrices[originalId] = resalePrice;
    }

    function mockMint(address to, uint256 mosaicId) public {
        _mint(to, mosaicId);
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
}