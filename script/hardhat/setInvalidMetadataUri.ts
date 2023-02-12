import { ethers } from "hardhat";
import { CryptoPunksMosaicRegistry__factory } from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;

const INVALID_METADATA_URI =
  "ipfs://QmTcoMx3RiyBZoS9UEb2qCt9iWDEiStF9Ft5HMPqLp4ktP";

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const mosaicRegistry = CryptoPunksMosaicRegistry__factory.connect(
    MosaicRegistryAddress,
    deployer
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
