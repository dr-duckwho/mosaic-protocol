import {
  CryptoPunksGroupRegistry,
  CryptoPunksMarket,
} from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { parseEther } from "ethers/lib/utils";
import { expect } from "chai";
import {
  claimMosaics,
  contributeBy,
  mosaicBalanceOfBy,
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
    it("Integration Test", async () => {
      const PUNK_ID = 1;
      const TICKET_SUPPLY = 100;
      const OFFERED_PRICE = parseEther("60");
      const TARGET_PRICE = parseEther("100");
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

      // TODO: #6 Access role constraint with create group
      const groupId = await newGroup(groupRegistry)(
        owner,
        PUNK_ID,
        TARGET_PRICE
      );
      await expect(groupRegistry.getGroup(groupId.add(1))).to.be.revertedWith(
        "Invalid groupId"
      );

      /**
       * Contribute & Buy
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

      await expect(groupRegistry.connect(bob).buy(groupId)).to.be.revertedWith(
        "Not sold out"
      );

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

      await groupRegistry.connect(bob).buy(groupId);

      // TODO: #0 View function for owned Ticket / Mosaic NFT ids
      const ticketBalance = ticketBalanceBy(groupRegistry);
      expect(await ticketBalance(bob, groupId)).to.equal(CONTRIBUTION.bob);
      expect(await ticketBalance(carol, groupId)).to.equal(CONTRIBUTION.carol);
      expect(await ticketBalance(david, groupId)).to.equal(CONTRIBUTION.david);

      /**
       * Claim
       */

      // TODO: #1 Claim all mosaic NFT at once
      //  Why not just give a single ERC721 regardless of contribution?
      // TODO: #2 Handle NFT Metadata
      await Promise.all([
        claimMosaics(groupRegistry)(bob, groupId),
        claimMosaics(groupRegistry)(carol, groupId),
        claimMosaics(groupRegistry)(david, groupId),
      ]);

      expect(await ticketBalance(bob, groupId)).to.equal(0);
      expect(await ticketBalance(carol, groupId)).to.equal(0);
      expect(await ticketBalance(david, groupId)).to.equal(0);

      const originalId = await mosaicRegistry.latestOriginalId();

      // TODO: #3 This test supposes bob, carol and david claimed all mosaic NFTs in sequential order.
      //  Might need a enumerable balance view function...
      //  but gas cost will end up to high for other tx
      const mosaicBalanceOf = mosaicBalanceOfBy(mosaicRegistry, originalId);

      const [bobStart, bobEnd] = [ORIGINAL_MONO_ID + 1, CONTRIBUTION.bob];
      expect(await mosaicBalanceOf(bob, ORIGINAL_MONO_ID)).to.equal(0);
      expect(await mosaicBalanceOf(bob, bobStart)).to.equal(1);
      expect(await mosaicBalanceOf(bob, bobEnd)).to.equal(1);

      const [carolStart, carolEnd] = [
        bobEnd + 1,
        CONTRIBUTION.bob + CONTRIBUTION.carol,
      ];
      expect(await mosaicBalanceOf(carol, bobEnd)).to.equal(0);
      expect(await mosaicBalanceOf(carol, carolStart)).to.equal(1);
      expect(await mosaicBalanceOf(carol, carolEnd)).to.equal(1);

      const [davidStart, davidEnd] = [
        carolEnd + 1,
        CONTRIBUTION.bob + CONTRIBUTION.carol + CONTRIBUTION.david,
      ];
      expect(await mosaicBalanceOf(david, davidStart)).to.equal(1);
      expect(await mosaicBalanceOf(david, davidEnd)).to.equal(1);
      expect(await mosaicBalanceOf(david, davidEnd + 1)).to.equal(0);

      /**
       * Refund
       * TODO: Check the after-refund-mint balances
       */
    });

    /**
     * TODO: #4 Governance
     */

    /**
     * TODO: #5 Settlement
     */
  });
});
