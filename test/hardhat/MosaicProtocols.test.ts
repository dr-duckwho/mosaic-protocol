import { ethers } from "hardhat";
import {
  CryptoPunksGroupRegistry,
  CryptoPunksGroupRegistry__factory,
  CryptoPunksMarket,
  CryptoPunksMarket__factory,
  CryptoPunksMosaicRegistry,
  CryptoPunksMosaicRegistry__factory,
} from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("MosaicProtocol", function () {
  async function fullFixture() {
    const [owner, alice, bob, carol] = await ethers.getSigners();
    const ownerAddress = await owner.getAddress();

    const CryptoPunks: CryptoPunksMarket__factory =
      await ethers.getContractFactory("CryptoPunksMarket");
    const GroupContract: CryptoPunksGroupRegistry__factory =
      await ethers.getContractFactory("CryptoPunksGroupRegistry");
    const MosaicContract: CryptoPunksMosaicRegistry__factory =
      await ethers.getContractFactory("CryptoPunksMosaicRegistry");

    // deploy contracts
    const cryptoPunks: CryptoPunksMarket = await CryptoPunks.deploy();
    const mosaicContract: CryptoPunksMosaicRegistry =
      await MosaicContract.deploy(ownerAddress, cryptoPunks.address);
    const groupContract: CryptoPunksGroupRegistry = await GroupContract.deploy(
      cryptoPunks.address,
      mosaicContract.address
    );

    // enable cryptoPunks to be minted for everyone
    await cryptoPunks.connect(owner).allInitialOwnersAssigned();

    // grant mosaic minter role to group contract
    const minterRole = await mosaicContract.MINTER_ROLE();
    await mosaicContract
      .connect(owner)
      .grantRole(minterRole, groupContract.address);

    return {
      owner,
      alice,
      bob,
      carol,
      cryptoPunks,
      mosaicContract,
      groupContract,
    };
  }

  describe("Deployment", function () {
    it("Everyone can own a punk", async function () {
      const { cryptoPunks, alice, bob, carol } = await loadFixture(fullFixture);
      await cryptoPunks.connect(alice).getPunk(0);
      await cryptoPunks.connect(bob).getPunk(1);
      await cryptoPunks.connect(carol).getPunk(2);
    });
  });
});
