import { ethers } from "hardhat";
import { CryptoPunksMosaicRegistry__factory } from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;
const GroupRegistryAddress = contracts.CryptoPunksGroupRegistry.address;

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const mosaicRegistry = CryptoPunksMosaicRegistry__factory.connect(
    MosaicRegistryAddress,
    deployer
  );

  const minterRole = await mosaicRegistry.MINTER_ROLE();
  await mosaicRegistry
    .connect(deployer)
    .grantRole(minterRole, GroupRegistryAddress);

  console.log(
    `${MosaicRegistryAddress} minter role granted to ${GroupRegistryAddress}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
