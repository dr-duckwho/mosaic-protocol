import { ethers } from "hardhat";
import { CryptoPunksMuseum__factory } from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MuseumAddress = contracts.CryptoPunksMuseum.address;
const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;
const GroupRegistryAddress = contracts.CryptoPunksGroupRegistry.address;

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const museum = CryptoPunksMuseum__factory.connect(
    MuseumAddress,
    deployer
  );

  await museum
    .connect(deployer)
    .setGroupRegistry(GroupRegistryAddress);

  await museum
    .connect(deployer)
    .setMosaicRegistry(MosaicRegistryAddress);

  await museum
    .connect(deployer)
    .activate();

  console.log(
    `${MuseumAddress} activated: GroupRegistry ${GroupRegistryAddress} MosaicRegistry ${MosaicRegistryAddress}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
