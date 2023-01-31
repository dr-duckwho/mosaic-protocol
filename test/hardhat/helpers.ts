import {
  CryptoPunksGroupRegistry,
  CryptoPunksMarket,
  CryptoPunksMosaicRegistry,
} from "../../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish } from "ethers";

export const offerPunkForSale =
  (cryptoPunks: CryptoPunksMarket) =>
  async (
    punkOwner: SignerWithAddress,
    targetPunkIndex: BigNumberish,
    offeredPunkPrice: BigNumberish
  ) => {
    await cryptoPunks.connect(punkOwner).getPunk(targetPunkIndex);
    await cryptoPunks
      .connect(punkOwner)
      .offerPunkForSale(targetPunkIndex, offeredPunkPrice);
  };

export const newGroup =
  (groupContract: CryptoPunksGroupRegistry) =>
  async (
    creator: SignerWithAddress,
    targetPunkIndex: BigNumberish,
    targetPrice: BigNumberish
  ) => {
    await groupContract.connect(creator).create(targetPunkIndex, targetPrice);
    return await groupContract.latestGroupId();
  };

export const contributeBy = (
  groupContract: CryptoPunksGroupRegistry,
  groupId: BigNumber
) => {
  return (
    contributor: SignerWithAddress,
    pricePerTicket: BigNumber,
    ticketCount: number
  ) => {
    return groupContract.connect(contributor).contribute(groupId, ticketCount, {
      value: pricePerTicket.mul(ticketCount),
    });
  };
};

export const claimMosaics =
  (groupRegistry: CryptoPunksGroupRegistry) =>
  (
    contributor: SignerWithAddress,
    groupId: BigNumberish
  ) =>
    groupRegistry.connect(contributor).claim(groupId);

export const ticketBalanceBy =
  (groupRegistry: CryptoPunksGroupRegistry) =>
  async (contributor: SignerWithAddress, groupId: BigNumberish) => {
    return groupRegistry.balanceOf(await contributor.getAddress(), groupId);
  };

export const mosaicBalanceOfBy =
  (mosaicRegistry: CryptoPunksMosaicRegistry, originalId: BigNumberish) =>
  async (owner: SignerWithAddress, monoId: BigNumberish) => {
    return mosaicRegistry.balanceOf(
      await owner.getAddress(),
      await mosaicRegistry.toMosaicId(originalId, monoId)
    );
  };
