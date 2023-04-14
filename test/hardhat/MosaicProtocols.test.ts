import { CryptoPunksMarket } from "../../typechain-types";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { parseEther } from "ethers/lib/utils";
import { expect } from "chai";
import {
  claimMosaics,
  contributeBy,
  mosaicOwnerOfBy,
  newGroup,
  offerPunkForSale,
  ticketBalanceBy,
} from "./helpers";
import { afterDeploy } from "./fixture";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish, Contract } from "ethers";
import { ethers } from "hardhat";

/**
 * Common basis for GroupRegistry and MosaicRegistry
 */
const PUNK_ID = 1;
const TICKET_SUPPLY = 100;
// the fundraising target
const TARGET_PRICE_ETH = 100;
const TARGET_PRICE = parseEther(`${TARGET_PRICE_ETH}`);
// the actual price the punk is sold at
const OFFERED_PRICE_ETH = 60;
const OFFERED_PRICE = parseEther(`${OFFERED_PRICE_ETH}`);
// a minimum difference that passes or fails a given threshold
const ONE_WEI = 1;

const BOB_CONTRIBUTION = 33;
const CAROL_CONTRIBUTION = 51;
const DAVID_CONTRIBUTION = 16;

// TODO: Group Mosaic owners' information
interface Context {
  cryptoPunks: CryptoPunksMarket;
  groupRegistry: Contract;
  mosaicRegistry: Contract;
  admin: SignerWithAddress;
  punkOwner: SignerWithAddress;
  originalId: BigNumberish;
  bob: SignerWithAddress;
  bobMonoIdRange: List<BigNumber>;
  carol: SignerWithAddress;
  carolMonoIdRange: List<BigNumber>;
  david: SignerWithAddress;
  davidMonoIdRange: List<BigNumber>;
}

const groupWins = async (): Context => {
  // should sum up to TICKET_SUPPLY
  const CONTRIBUTION = { bob: BOB_CONTRIBUTION, carol: CAROL_CONTRIBUTION, david: DAVID_CONTRIBUTION };
  const ORIGINAL_MONO_ID = 0;

  const {
    cryptoPunks,
    groupRegistry,
    mosaicRegistry,
    owner,
    alice: punkOwner,
    bob,
    carol,
    david,
  } = await loadFixture(afterDeploy);

  await offerPunkForSale(cryptoPunks)(punkOwner, PUNK_ID, OFFERED_PRICE);

  /**
   * Create
   */

  const groupId = await newGroup(groupRegistry)(owner, PUNK_ID, TARGET_PRICE);
  await expect(groupRegistry.getGroup(groupId.add(1))).to.be.revertedWith(
    "Invalid groupId"
  );

  /**
   * Contribute
   */

  const price = TARGET_PRICE.div(TICKET_SUPPLY);
  const contribute = contributeBy(groupRegistry, groupId);

  await expect(contribute(bob, price, CONTRIBUTION.bob)).to.changeEtherBalances(
    [groupRegistry.address, await bob.getAddress()],
    [parseEther(`${CONTRIBUTION.bob}`), parseEther(`${-CONTRIBUTION.bob}`)]
  );
  await expect(
    contribute(carol, price, CONTRIBUTION.carol)
  ).to.changeEtherBalances(
    [groupRegistry.address, await carol.getAddress()],
    [parseEther(`${CONTRIBUTION.carol}`), parseEther(`${-CONTRIBUTION.carol}`)]
  );

  await expect(groupRegistry.connect(owner).buy(groupId)).to.be.revertedWith(
    "Not sold out"
  );

  await expect(
    contribute(david, price, CONTRIBUTION.david)
  ).to.changeEtherBalances(
    [groupRegistry.address, await david.getAddress()],
    [parseEther(`${CONTRIBUTION.david}`), parseEther(`${-CONTRIBUTION.david}`)]
  );
  await expect(contribute(david, price, 1)).to.be.revertedWith(
    "Fewer tickets remaining than requested"
  );

  /**
   * Buy & win
   */

  expect(await groupRegistry.getGroupLifeCycle(groupId)).to.equal(1); // Active

  await groupRegistry.connect(owner).buy(groupId);

  const ticketBalance = ticketBalanceBy(groupRegistry);
  expect(await ticketBalance(bob, groupId)).to.equal(CONTRIBUTION.bob);
  expect(await ticketBalance(carol, groupId)).to.equal(CONTRIBUTION.carol);
  expect(await ticketBalance(david, groupId)).to.equal(CONTRIBUTION.david);

  expect(await groupRegistry.getGroupLifeCycle(groupId)).to.equal(3); // Won

  /**
   * Claim & refund
   */

  // Claim and refund
  const originalId = await mosaicRegistry.getLatestOriginalId();
  const surplus = TARGET_PRICE_ETH - OFFERED_PRICE_ETH;

  expect(await mosaicRegistry.getDistributionStatus(originalId)).to.equal(0); // Active (to be claimed)

  // TODO: dedup
  await expect(
    claimMosaics(groupRegistry)(bob, groupId)
  ).to.changeEtherBalances(
    [groupRegistry.address, await bob.getAddress()],
    [
      parseEther(`${-(surplus * CONTRIBUTION.bob) / 100}`),
      parseEther(`${(surplus * CONTRIBUTION.bob) / 100}`),
    ]
  );
  await expect(
    claimMosaics(groupRegistry)(carol, groupId)
  ).to.changeEtherBalances(
    [groupRegistry.address, await carol.getAddress()],
    [
      parseEther(`${-(surplus * CONTRIBUTION.carol) / 100}`),
      parseEther(`${(surplus * CONTRIBUTION.carol) / 100}`),
    ]
  );
  await expect(
    claimMosaics(groupRegistry)(david, groupId)
  ).to.changeEtherBalances(
    [groupRegistry.address, await david.getAddress()],
    [
      parseEther(`${-(surplus * CONTRIBUTION.david) / 100}`),
      parseEther(`${(surplus * CONTRIBUTION.david) / 100}`),
    ]
  );

  expect(await mosaicRegistry.getDistributionStatus(originalId)).to.equal(1); // Claiming complete for all

  expect(await ticketBalance(bob, groupId)).to.equal(0);
  expect(await ticketBalance(carol, groupId)).to.equal(0);
  expect(await ticketBalance(david, groupId)).to.equal(0);

  // Mosaic ownership
  const mosaicOwnerOf = mosaicOwnerOfBy(mosaicRegistry, originalId);

  const [bobStart, bobEnd] = [ORIGINAL_MONO_ID + 1, CONTRIBUTION.bob];
  // TODO: Test non-ownership also
  expect(await mosaicOwnerOf(bobStart)).to.equal(await bob.getAddress());
  expect(await mosaicOwnerOf(bobEnd)).to.equal(await bob.getAddress());

  const [carolStart, carolEnd] = [
    bobEnd + 1,
    CONTRIBUTION.bob + CONTRIBUTION.carol,
  ];
  expect(await mosaicOwnerOf(carolStart)).to.equal(await carol.getAddress());
  expect(await mosaicOwnerOf(carolEnd)).to.equal(await carol.getAddress());

  const [davidStart, davidEnd] = [
    carolEnd + 1,
    CONTRIBUTION.bob + CONTRIBUTION.carol + CONTRIBUTION.david,
  ];
  expect(await mosaicOwnerOf(davidStart)).to.equal(await david.getAddress());
  expect(await mosaicOwnerOf(davidEnd)).to.equal(await david.getAddress());

  return {
    cryptoPunks,
    groupRegistry,
    mosaicRegistry,
    admin: owner,
    punkOwner,
    originalId,
    bob,
    bobMonoIdRange: [bobStart, bobEnd],
    carol,
    carolMonoIdRange: [carolStart, carolEnd],
    david,
    davidMonoIdRange: [davidStart, davidEnd],
  };
};

describe("MosaicProtocol", function () {
  describe("CryptoPunksMarket", function () {
    it("Everyone can own a punk", async function () {
      const { cryptoPunks, alice, bob } = await loadFixture(afterDeploy);
      const [aliceAddress, bobAddress] = await Promise.all(
        [alice, bob].map((it) => it.getAddress())
      );

      await cryptoPunks.connect(alice).getPunk(0);
      await cryptoPunks.connect(bob).getPunk(1);

      expect(await cryptoPunks.punkIndexToAddress(0)).to.equal(aliceAddress);
      expect(await cryptoPunks.punkIndexToAddress(1)).to.equal(bobAddress);
    });
  });

  describe("CryptoPunksGroupRegistry", function () {
    it("works for a winning group scenario", async () => {
      await groupWins();
    });

    it("works for an expired group scenario", async () => {
      const CONTRIBUTION = { bob: BOB_CONTRIBUTION };

      const {
        cryptoPunks,
        groupRegistry,
        owner,
        alice: punkOwner,
        bob,
        carol,
      } = await loadFixture(afterDeploy);

      await offerPunkForSale(cryptoPunks)(punkOwner, PUNK_ID, OFFERED_PRICE);

      /**
       * Create
       */

      const groupId = await newGroup(groupRegistry)(
        owner,
        PUNK_ID,
        TARGET_PRICE
      );
      await expect(groupRegistry.getGroup(groupId.add(1))).to.be.revertedWith(
        "Invalid groupId"
      );

      /**
       * Contribute
       */

      const price = TARGET_PRICE.div(TICKET_SUPPLY);
      const contribute = contributeBy(groupRegistry, groupId);

      await expect(
        contribute(bob, price, CONTRIBUTION.bob)
      ).to.changeEtherBalances(
        [groupRegistry.address, await bob.getAddress()],
        [parseEther(`${CONTRIBUTION.bob}`), parseEther(`${-CONTRIBUTION.bob}`)]
      );

      const ticketBalance = ticketBalanceBy(groupRegistry);
      expect(await ticketBalance(bob, groupId)).to.equal(CONTRIBUTION.bob);

      /**
       * Buy - fail
       */

      await expect(
        groupRegistry.connect(owner).buy(groupId)
      ).to.be.revertedWith("Not sold out");

      /**
       * Expiry
       */

      // TODO: Make it available as a global constant
      const expiry = 604800;

      await time.increase(expiry - 100);
      expect(await groupRegistry.getGroupLifeCycle(groupId)).to.equal(1); // Active
      await time.increase(100);
      expect(await groupRegistry.getGroupLifeCycle(groupId)).to.equal(2); // LOST

      /**
       * Refund
       */

      // Bob gets all his contribution back
      await expect(
        groupRegistry.connect(bob).refundExpired(groupId)
      ).to.changeEtherBalances(
        [groupRegistry.address, await bob.getAddress()],
        [parseEther(`-${CONTRIBUTION.bob}`), parseEther(`${CONTRIBUTION.bob}`)]
      );
      expect(await ticketBalance(bob, groupId)).to.equal(0);

      // Nonparticipants don't
      await expect(
        groupRegistry.connect(carol).refundExpired(groupId)
      ).to.revertedWith("Only ticket holders can get refunds");

      // No double refund for Bob
      await expect(
        groupRegistry.connect(bob).refundExpired(groupId)
      ).to.revertedWith("Only ticket holders can get refunds");
    });
  });

  describe("CryptoPunksMosaicRegistry", function () {
    let context: Context;
    /**
     * TODO: #4 Governance
     */
    beforeEach(async () => {
      context = await groupWins();
    });

    it("allows holders to update presets", async () => {
      // TODO: fill it out more about validation and URI
      const { mosaicRegistry, originalId, bob, bobMonoIdRange } = context;
      const PRESET_ID = 3;
      for (let id = bobMonoIdRange[0]; id <= bobMonoIdRange[1]; id++) {
        const mosaicId = await mosaicRegistry.toMosaicId(originalId, id);
        await mosaicRegistry.connect(bob).setPresetId(mosaicId, PRESET_ID);
        const [, presetId, _] = await mosaicRegistry.getMono(originalId, id);
        expect(presetId).to.equal(PRESET_ID);
      }
    });

    it("allows holders to propose reserve prices only within a set range", async () => {
      const { mosaicRegistry, originalId, bob, bobMonoIdRange } = context;

      const [, , , , , minReservePrice, maxReservePrice, ,] =
        await mosaicRegistry.getOriginal(originalId);

      const proposal: BigNumber = OFFERED_PRICE;
      const proposalTooLow: BigNumber = minReservePrice.sub(ONE_WEI);
      const proposalTooHigh: BigNumber = maxReservePrice.add(ONE_WEI);

      await mosaicRegistry
        .connect(bob)
        .proposeReservePriceBatch(originalId, proposal);
      for (let id = bobMonoIdRange[0]; id <= bobMonoIdRange[1]; id++) {
        let [, , governanceOptions] = await mosaicRegistry.getMono(
          originalId,
          id
        );
        let [proposedReservePrice] = governanceOptions;
        expect(proposedReservePrice).to.equal(proposal);
      }

      for (const unacceptableProposal of [proposalTooLow, proposalTooHigh]) {
        await expect(
          mosaicRegistry
            .connect(bob)
            .proposeReservePriceBatch(originalId, unacceptableProposal)
        ).to.revertedWith("Must be within the range");
      }
    });

    it("forbids bids when not enough holders have proposed reserve prices", async () => {
      const { mosaicRegistry, originalId, david } = context;
      const [, , , , , , maxReservePrice, ,] = await mosaicRegistry.getOriginal(
        originalId
      );

      const [, , , , bidder] = await ethers.getSigners();
      await expect(
        mosaicRegistry
          .connect(bidder)
          .bid(originalId, maxReservePrice, { value: maxReservePrice })
      ).to.revertedWith("Not enough reserve price proposals set");

      // David has only 16% shares, not enough to meet the min turnout condition
      const davidReservePrice = maxReservePrice.sub(ONE_WEI);
      await mosaicRegistry
        .connect(david)
        .proposeReservePriceBatch(originalId, davidReservePrice);

      await expect(
        mosaicRegistry
          .connect(bidder)
          .bid(originalId, maxReservePrice, { value: maxReservePrice })
      ).to.revertedWith("Not enough reserve price proposals set");
    });

    // Bid

    const createBid = async () => {
      const { mosaicRegistry, originalId, bob } = context;
      const [, , , , , , maxReservePrice, ,] = await mosaicRegistry.getOriginal(
        originalId
      );

      /**
       * allows bids only within average reserve price sum ranges proposed by holders
       */

      // In this scenario context, Bob's share of 33% exceeds the min turnout threshold requirement
      const bobReservePrice = maxReservePrice.sub(ONE_WEI);
      await mosaicRegistry
        .connect(bob)
        .proposeReservePriceBatch(originalId, bobReservePrice);

      const averageReservePriceProposal: BigNumber =
        await mosaicRegistry.getAverageReservePriceProposals(originalId);
      expect(averageReservePriceProposal).to.equal(bobReservePrice);

      // Bid
      const [, , , , bidder, nextBidder] = await ethers.getSigners();
      // fail: below the avg proposal
      const subParBidPrice = averageReservePriceProposal.sub(ONE_WEI);
      await expect(
        mosaicRegistry
          .connect(bidder)
          .bid(originalId, subParBidPrice, { value: subParBidPrice })
      ).to.revertedWith("Bid price must be within the reserve price range");

      // success
      const bidPrice = averageReservePriceProposal;
      await expect(
        mosaicRegistry
          .connect(bidder)
          .bid(originalId, bidPrice, { value: bidPrice })
      )
        .to.changeEtherBalances(
          [mosaicRegistry.address, await bidder.getAddress()],
          [bidPrice, bidPrice.mul(-1)]
        )
        .to.emit(mosaicRegistry, "BidProposed");
      const bidId: BigNumber = await mosaicRegistry.getOngoingBidId(originalId);

      /**
       * allows only one active bid per original
       */

      // the previous bid has not expired yet
      await expect(
        mosaicRegistry
          .connect(nextBidder)
          .bid(originalId, bidPrice, { value: bidPrice })
      ).to.revertedWith("Bid vote is ongoing");

      // TODO: Make it available as a global constant
      const expiry = 604800;
      await time.increase(expiry);

      await expect(
        mosaicRegistry
          .connect(nextBidder)
          .bid(originalId, bidPrice, { value: bidPrice })
      )
        .to.changeEtherBalances(
          [mosaicRegistry.address, await nextBidder.getAddress()],
          [bidPrice, bidPrice.mul(-1)]
        )
        .to.emit(mosaicRegistry, "BidProposed");

      // the previous bidder can get refunded
      await expect(mosaicRegistry.connect(bidder).refundBidDeposit(bidId))
        .to.changeEtherBalances(
          [mosaicRegistry.address, await bidder.getAddress()],
          [bidPrice.mul(-1), bidPrice]
        )
        .to.emit(mosaicRegistry, "BidRefunded");

      return { bidder: nextBidder, bidId };
    };

    it("allows bids only when requirements are met", async () => {
      await createBid();
    });

    it("allows holders to vote on ongoing bids", async () => {
      const { bidId } = await createBid();
      const { mosaicRegistry, originalId, bob, carol, david } = context;

      // Round 1 - initial condition
      expect(await mosaicRegistry.isBidAcceptable(originalId)).to.equal(false);

      // Round 2 - 84% yes, 16% no
      let voters = new Map([
        [bob, 1], // Yes 33%
        [carol, 1], // Yes 51%
        [david, 2] // No 16%
      ]);

      for (let [voter, vote] of voters) {
        await mosaicRegistry.connect(voter).respondToBidBatch(originalId, vote);
      }

      expect(await mosaicRegistry.isBidAcceptable(originalId)).to.equal(true);

      // Round 3 - 16% yes, 84% no
      voters = new Map([
        [bob, 2], // No 33%
        [carol, 2], // No 51%
        [david, 1] // Yes 16%
      ]);

      for (let [voter, vote] of voters) {
        await mosaicRegistry.connect(voter).respondToBidBatch(originalId, vote);
      }
      
      expect(await mosaicRegistry.isBidAcceptable(originalId)).to.equal(false);
    });

    /**
     * TODO: #5 Settlement
     */
    it("transfers the original to a winning bidder and burns all the holders' monos", async () => {
      // TODO: Fill it out
    });

    it("refunds the deposit to a bidder whose bid is rejected or expired", async () => {
      // TODO: Fill it out
    });

    it("disallows Mono configuration if the original is sold out already", async () => {
      // TODO: Fill it out
    });
  });
});
