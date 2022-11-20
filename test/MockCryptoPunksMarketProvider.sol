// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {MockProvider} from "mockprovider/MockProvider.sol";

import {CryptoPunksMarket} from "../src/external/CryptoPunksMarket.sol";

/**
 * @dev A wrapper to mock staticcall return values for public fields
 */
contract MockCryptoPunksMarketProvider is MockProvider, CryptoPunksMarket {
    /**
     * @dev fields copied from larvalabs/cryptopunks
     */ 
    // You can use this hash to verify the image file containing all the punks
    string public imageHash =
        "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint256 public punksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint256 => Bid) public punkBids;

    mapping(address => uint256) public pendingWithdrawals;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() payable {
        punkIndexToAddress[1] = address(0x0);
    }

    function setInitialOwner(address to, uint256 punkIndex) public {}

    function setInitialOwners(
        address[] calldata addresses,
        uint256[] calldata indices
    ) public {}

    function allInitialOwnersAssigned() public {}

    function getPunk(uint256 punkIndex) public {}

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) public {}

    function punkNoLongerForSale(uint256 punkIndex) public {}

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei)
        public
    {}

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public {}

    function buyPunk(uint256 punkIndex) public payable {}

    function withdraw() public {}

    function enterBidForPunk(uint256 punkIndex) public payable {}

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) public {}

    function withdrawBidForPunk(uint256 punkIndex) public {}

    /**
     * @dev for mocking
     */ 
    function setPunkIndexToAddress(uint256 punkIndex, address addr) public {
        punkIndexToAddress[punkIndex] = addr;
    }

    function setBalanceOf(address addr, uint256 balance) public {
        balanceOf[addr] = balance;
    }

    function setPunksOfferedForSale(uint256 punkIndex, Offer calldata offer) public {
        punksOfferedForSale[punkIndex] = offer;
    }
}
