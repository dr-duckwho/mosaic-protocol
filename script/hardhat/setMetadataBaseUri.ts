import { ethers } from "hardhat";
import { CryptoPunksMosaicRegistry__factory } from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const MosaicRegistryAddress = contracts.CryptoPunksMosaicRegistry.address;

const originalId = 1;
const METADATA_URI = "ipfs://QmSpoLgsWyKYf2HPttAGsMk4fVsnWEuYroN1ASnzbtrVLR";

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const mosaicRegistry = CryptoPunksMosaicRegistry__factory.connect(
    MosaicRegistryAddress,
    deployer
  );

  await mosaicRegistry
    .connect(deployer)
    .setMetadataBaseUri(originalId, METADATA_URI);

  console.log(
    `${MosaicRegistryAddress} original #${originalId} metadata uri set to ${METADATA_URI}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
