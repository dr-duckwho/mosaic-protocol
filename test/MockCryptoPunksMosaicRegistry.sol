// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../src/CryptoPunksMosaicRegistry.sol";

contract MockCryptoPunksMosaicRegistry is CryptoPunksMosaicRegistry {
    constructor(address _mintAuthority,
        address cryptoPunksMarketAddress) public CryptoPunksMosaicRegistry(_mintAuthority, cryptoPunksMarketAddress) {}

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
}