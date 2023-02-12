import { ethers } from "hardhat";
import {
  CryptoPunksGroupRegistry,
  CryptoPunksGroupRegistry__factory,
  CryptoPunksMarket,
  CryptoPunksMarket__factory,
  CryptoPunksMosaicRegistry,
  CryptoPunksMosaicRegistry__factory,
  CryptoPunksMuseum,
  CryptoPunksMuseum__factory
} from "../../typechain-types";

export async function afterDeploy() {
  const [owner, alice, bob, carol, david] = await ethers.getSigners();
  const ownerAddress = await owner.getAddress();

  const CryptoPunks: CryptoPunksMarket__factory =
    await ethers.getContractFactory("CryptoPunksMarket");
  const CryptoPunksMuseum: CryptoPunksMuseum__factory =
    await ethers.getContractFactory("CryptoPunksMuseum");
  const GroupContract: CryptoPunksGroupRegistry__factory =
    await ethers.getContractFactory("CryptoPunksGroupRegistry");
  const MosaicContract: CryptoPunksMosaicRegistry__factory =
    await ethers.getContractFactory("CryptoPunksMosaicRegistry");

  // deploy contracts
  const cryptoPunks: CryptoPunksMarket = await CryptoPunks.deploy();
  const museum: CryptoPunksMuseum = await CryptoPunksMuseum.deploy(cryptoPunks.address);
  const mosaicRegistry: CryptoPunksMosaicRegistry = await MosaicContract.deploy(museum.address);
  const groupRegistry: CryptoPunksGroupRegistry = await GroupContract.deploy(museum.address);

  // set up Museum and activate
  await museum.connect(owner).setMosaicRegistry(mosaicRegistry.address);
  await museum.connect(owner).setGroupRegistry(groupRegistry.address);
  await museum.connect(owner).activate();

  // enable cryptoPunks to be minted for everyone
  await cryptoPunks.connect(owner).allInitialOwnersAssigned();

  return {
    owner,
    alice,
    bob,
    carol,
    david,
    cryptoPunks,
    mosaicRegistry,
    groupRegistry,
  };
}
