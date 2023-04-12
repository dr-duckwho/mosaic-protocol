import {
  CryptoPunksGroupRegistry,
  CryptoPunksMarket,
  UsingCryptoPunksGroupRegistryStructs__factory,
} from "../../typechain-types";
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
    const PUNK_ID = 1;
    const TICKET_SUPPLY = 100;
    // the fundraising target
    const TARGET_PRICE_ETH = 100;
    const TARGET_PRICE = parseEther(`${TARGET_PRICE_ETH}`);
    // the actual price the punk is sold at
    const OFFERED_PRICE_ETH = 60;
    const OFFERED_PRICE = parseEther(`${OFFERED_PRICE_ETH}`);
    it("works for a winning group", async () => {
      // should sum up to TICKET_SUPPLY
      const CONTRIBUTION = { bob: 33, carol: 51, david: 16 };
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
      await expect(
        contribute(carol, price, CONTRIBUTION.carol)
      ).to.changeEtherBalances(
        [groupRegistry.address, await carol.getAddress()],
        [
          parseEther(`${CONTRIBUTION.carol}`),
          parseEther(`${-CONTRIBUTION.carol}`),
        ]
      );

      await expect(
        groupRegistry.connect(owner).buy(groupId)
      ).to.be.revertedWith("Not sold out");

      await expect(
        contribute(david, price, CONTRIBUTION.david)
      ).to.changeEtherBalances(
        [groupRegistry.address, await david.getAddress()],
        [
          parseEther(`${CONTRIBUTION.david}`),
          parseEther(`${-CONTRIBUTION.david}`),
        ]
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

      // TODO: dedup
      const surplus = TARGET_PRICE_ETH - OFFERED_PRICE_ETH;
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

      expect(await ticketBalance(bob, groupId)).to.equal(0);
      expect(await ticketBalance(carol, groupId)).to.equal(0);
      expect(await ticketBalance(david, groupId)).to.equal(0);

      const originalId = await mosaicRegistry.getLatestOriginalId();

      const mosaicOwnerOf = mosaicOwnerOfBy(mosaicRegistry, originalId);

      const [bobStart, bobEnd] = [ORIGINAL_MONO_ID + 1, CONTRIBUTION.bob];
      // TODO: Test non-ownership also
      expect(await mosaicOwnerOf(bobStart)).to.equal(await bob.getAddress());
      expect(await mosaicOwnerOf(bobEnd)).to.equal(await bob.getAddress());

      const [carolStart, carolEnd] = [
        bobEnd + 1,
        CONTRIBUTION.bob + CONTRIBUTION.carol,
      ];
      expect(await mosaicOwnerOf(carolStart)).to.equal(
        await carol.getAddress()
      );
      expect(await mosaicOwnerOf(carolEnd)).to.equal(await carol.getAddress());

      const [davidStart, davidEnd] = [
        carolEnd + 1,
        CONTRIBUTION.bob + CONTRIBUTION.carol + CONTRIBUTION.david,
      ];
      expect(await mosaicOwnerOf(davidStart)).to.equal(
        await david.getAddress()
      );
      expect(await mosaicOwnerOf(davidEnd)).to.equal(await david.getAddress());
    });

    it("works for an expired group", async () => {
      const CONTRIBUTION = { bob: 33 };

      const {
        cryptoPunks,
        groupRegistry,
        mosaicRegistry,
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

    /**
     * TODO: #4 Governance
     */

    /**
     * TODO: #5 Settlement
     */
  });
});
