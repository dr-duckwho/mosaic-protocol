import { ethers } from "hardhat";
import {
  CryptoPunksGroupRegistry,
  CryptoPunksGroupRegistry__factory,
  CryptoPunksMarket,
  CryptoPunksMarket__factory,
  CryptoPunksMosaicRegistry,
  CryptoPunksMosaicRegistry__factory,
} from "../../typechain-types";

export async function afterDeploy() {
  const [owner, alice, bob, carol, david] = await ethers.getSigners();
  const ownerAddress = await owner.getAddress();

  const CryptoPunks: CryptoPunksMarket__factory =
    await ethers.getContractFactory("CryptoPunksMarket");
  const GroupContract: CryptoPunksGroupRegistry__factory =
    await ethers.getContractFactory("CryptoPunksGroupRegistry");
  const MosaicContract: CryptoPunksMosaicRegistry__factory =
    await ethers.getContractFactory("CryptoPunksMosaicRegistry");

  // deploy contracts
  const cryptoPunks: CryptoPunksMarket = await CryptoPunks.deploy();
  const mosaicRegistry: CryptoPunksMosaicRegistry = await MosaicContract.deploy(
    ownerAddress,
    cryptoPunks.address
  );
  const groupRegistry: CryptoPunksGroupRegistry = await GroupContract.deploy(
    cryptoPunks.address,
    mosaicRegistry.address
  );

  // grant mosaic minter role to group contract
  const minterRole = await mosaicRegistry.MINTER_ROLE();
  await mosaicRegistry
    .connect(owner)
    .grantRole(minterRole, groupRegistry.address);

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
