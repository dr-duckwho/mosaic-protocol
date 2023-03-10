import { ethers } from "hardhat";
import {
  CryptoPunksMosaicRegistry__factory,
  CryptoPunksMuseum__factory,
} from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MuseumAddress = contracts.CryptoPunksMuseum.address;
const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;
const GroupRegistryAddress = contracts.CryptoPunksGroupRegistry.address;

const INVALID_METADATA_URI =
  "ipfs://QmTcoMx3RiyBZoS9UEb2qCt9iWDEiStF9Ft5HMPqLp4ktP";

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const museum = CryptoPunksMuseum__factory.connect(MuseumAddress, deployer);

  // TODO: Use proxies
  const mosaicRegistry = CryptoPunksMosaicRegistry__factory.connect(
    MosaicRegistryAddress,
    deployer
  );

  await museum.connect(deployer).setGroupRegistry(GroupRegistryAddress);
  await museum.connect(deployer).setMosaicRegistry(MosaicRegistryAddress);
  await museum.connect(deployer).activate();

  console.log(
    `${MuseumAddress} activated: GroupRegistry ${GroupRegistryAddress} MosaicRegistry ${MosaicRegistryAddress}`
  );

  const minterRole = await mosaicRegistry.MINTER_ROLE();
  await mosaicRegistry
    .connect(deployer)
    .grantRole(minterRole, GroupRegistryAddress);

  console.log(
    `${MosaicRegistryAddress} minter role granted to ${GroupRegistryAddress}`
  );

  await mosaicRegistry
    .connect(deployer)
    .setInvalidMetadataUri(INVALID_METADATA_URI);

  console.log(
    `${MosaicRegistryAddress} invalid metadata uri set to ${INVALID_METADATA_URI}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
