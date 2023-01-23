// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {TestUtils} from "./TestUtils.sol";
import {MockProvider} from "mockprovider/MockProvider.sol";

import {CryptoPunksGroupRegistry} from "../src/CryptoPunksGroupRegistry.sol";
import {UsingCryptoPunksGroupRegistryStructs} from "../src/UsingCryptoPunksGroupRegistryStructs.sol";
import {ICryptoPunksMosaicRegistry} from "../src/ICryptoPunksMosaicRegistry.sol";
import {MockCryptoPunksMarketProvider} from "./MockCryptoPunksMarketProvider.sol";
import {ICryptoPunksMarket} from "../src/external/ICryptoPunksMarket.sol";

contract CryptoPunksGroupRegistryTest is Test, TestUtils, UsingCryptoPunksGroupRegistryStructs {
    MockCryptoPunksMarketProvider public mockCryptoPunksMarket;
    MockProvider public mockMosaicRegistry;
    CryptoPunksGroupRegistry public groupRegistry;
    uint256 targetPunkId;

    address public originalOwner;

    function setUp() public {
        mockCryptoPunksMarket = new MockCryptoPunksMarketProvider();
        mockMosaicRegistry = new MockProvider();

        originalOwner = _randomAddress();
        targetPunkId = 1;

        groupRegistry = new CryptoPunksGroupRegistry(
            address(mockCryptoPunksMarket),
            address(mockMosaicRegistry)
        );
    }

    function test_create() public {
        // given
        uint256 targetMaxPrice = 10 ether;

        address payable creator = _randomAddress();
        groupRegistry.grantCuratorRole(creator);
        vm.deal(creator, 100 ether);

        // when
        vm.expectEmit(true, true, false, false);
        emit GroupCreated(1, creator, 10 ether, 100, 1 ether);
        vm.prank(creator);
        uint192 groupId = groupRegistry.create(targetPunkId, targetMaxPrice);

        // then
        (
            address _creator,
            uint256 _targetMaxPrice,
            uint96 _ticketsBought,
            GroupStatus _status
        ) = groupRegistry.getGroupInfo(groupId);
        assertEq(_creator, creator);
        assertEq(_targetMaxPrice, targetMaxPrice);
        assertEq(_ticketsBought, 0);
        assert(_status == GroupStatus.Open);
    }

    function test_buy() public {
        // given & when
        address payable creator = _randomAddress();
        groupRegistry.grantCuratorRole(creator);
        uint192 groupId = _createAndBuy(creator, targetPunkId);

        // then
        (
            address _creator,
            uint256 _targetMaxPrice,
            uint96 _ticketsBought,
            GroupStatus _status
        ) = groupRegistry.getGroupInfo(groupId);
        assertEq(_ticketsBought, 100);
        assert(_status == GroupStatus.Claimable);
    }

    function test_claim() public {
        // given
        address payable creator = _randomAddress();
        uint192 groupId = _createAndBuy(creator, targetPunkId);
        assertEq(groupRegistry.balanceOf(creator, groupId), 100);

        string memory metadataUri = "uri";
        uint256 expectedMosaicId = 581019;

        mockMosaicRegistry.givenSelectorReturnResponse(
            ICryptoPunksMosaicRegistry.mint.selector,
            MockProvider.ReturnData({success: true, data: abi.encode(expectedMosaicId)}),
            true
        );

        // when
        vm.expectEmit(true, true, false, false);
        emit Claimed(creator, groupId, expectedMosaicId);

        vm.prank(creator);
        uint256 mosaicId = groupRegistry.claim(groupId, metadataUri);

        // then
        assertEq(mosaicId, expectedMosaicId);
        assertEq(groupRegistry.balanceOf(creator, groupId), 99);
    }

    function test_refund() public {
        // given conditions
        address payable alice = _randomAddress();
        address payable bob = _randomAddress();
        address payable carol = _randomAddress();
        vm.deal(alice, 40 ether);
        vm.deal(bob, 30 ether);
        vm.deal(carol, 30 ether);

        // purchase conditions
        uint256 targetMaxPrice = 100 ether; // resulting in 1 ticket = 1 ether
        uint256 purchasePrice = 75 ether; // resulting in surplus of 25 ether

        // create
        groupRegistry.grantCuratorRole(alice);
        vm.prank(alice);
        uint192 groupId = _create(targetPunkId, targetMaxPrice);

        // contribute
        vm.prank(alice);
        groupRegistry.contribute{value: 40 ether}(groupId, 40);
        assertEq(groupRegistry.getGroupTotalContribution(groupId), 40 ether);
        vm.prank(bob);
        groupRegistry.contribute{value: 30 ether}(groupId, 30);
        assertEq(groupRegistry.getGroupTotalContribution(groupId), 70 ether);
        vm.prank(carol);
        groupRegistry.contribute{value: 30 ether}(groupId, 30);
        assertEq(groupRegistry.getGroupTotalContribution(groupId), 100 ether);

        // given the market
        mockCryptoPunksMarket.givenQueryReturn(
            abi.encodePacked(ICryptoPunksMarket.buyPunk.selector), abi.encodePacked(uint256(1))
        );
        mockCryptoPunksMarket.givenQueryReturn(
            abi.encodePacked(ICryptoPunksMarket.transferPunk.selector), abi.encodePacked(true)
        );
        mockCryptoPunksMarket.setPunksOfferedForSale(
            1, MockCryptoPunksMarketProvider.Offer(true, 1, address(0x1), purchasePrice, address(0x0))
        );
        mockCryptoPunksMarket.setPunkIndexToAddress(1, address(groupRegistry));
        mockMosaicRegistry.givenSelectorReturnResponse(
            ICryptoPunksMosaicRegistry.create.selector,
            MockProvider.ReturnData({success: true, data: abi.encode(uint192(1))}),
            true
        );

        // buy
        assertEq(address(groupRegistry).balance, 100 ether);
        vm.prank(alice);
        groupRegistry.buy(groupId);
        assertEq(address(groupRegistry).balance, 25 ether);

        // when
        vm.prank(alice);
        groupRegistry.refund(groupId);
        vm.prank(bob);
        groupRegistry.refund(groupId);
        vm.prank(carol);
        groupRegistry.refund(groupId);

        // then
        assertEq(alice.balance, 10 ether);
        assertEq(bob.balance, 7.5 ether);
        assertEq(carol.balance, 7.5 ether);

        // when tried once again illegally
        vm.prank(carol);
        vm.expectRevert("Only refundable ticket holders can get refunds");
        groupRegistry.refund(groupId);
    }

    // Test helpers

    function _create(uint256 _targetPunkId, uint256 _targetMaxPrice) internal returns (uint192) {
        return groupRegistry.create(_targetPunkId, _targetMaxPrice);
    }

    // TODO: Refactor the test helpers
    function _createAndBuy(address payable creator, uint256 targetPunkId) internal returns (uint192 groupId) {
        // given conditions
        uint256 targetMaxPrice = 10 ether;
        vm.deal(creator, 100 ether);

        // create
        groupRegistry.grantCuratorRole(creator);
        vm.prank(creator);
        uint192 groupId = _create(targetPunkId, targetMaxPrice);

        // contribute
        vm.prank(creator);
        groupRegistry.contribute{value: targetMaxPrice}(groupId, 100);
        assertEq(groupRegistry.getGroupTotalContribution(groupId), 10 ether);

        // given mocks
        mockCryptoPunksMarket.givenQueryReturn(
            abi.encodePacked(ICryptoPunksMarket.buyPunk.selector), abi.encodePacked(uint256(1))
        );
        mockCryptoPunksMarket.givenQueryReturn(
            abi.encodePacked(ICryptoPunksMarket.transferPunk.selector), abi.encodePacked(true)
        );
        mockCryptoPunksMarket.setPunksOfferedForSale(
            1, MockCryptoPunksMarketProvider.Offer(true, 1, address(0x1), 1 ether, address(0x0))
        );
        mockCryptoPunksMarket.setPunkIndexToAddress(1, address(groupRegistry));
        mockMosaicRegistry.givenSelectorReturnResponse(
            ICryptoPunksMosaicRegistry.create.selector,
            MockProvider.ReturnData({success: true, data: abi.encode(uint192(1))}),
            true
        );

        // buy
        vm.prank(creator);
        groupRegistry.buy(groupId);

        return groupId;
    }
}
