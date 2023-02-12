import { ethers } from "hardhat";
import { CryptoPunksGroupRegistry__factory } from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;
const GroupRegistryAddress = contracts.CryptoPunksGroupRegistry.address;

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const groupRegistry = CryptoPunksGroupRegistry__factory.connect(
    GroupRegistryAddress,
    deployer
  );

  console.log(
    await groupRegistry.queryFilter(
      await groupRegistry.filters.GroupCreated(null)
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
