import { ethers } from "hardhat";
import {
  CryptoPunksMarket__factory,
} from "../../typechain-types";
import { contracts } from "../../deployments/testnet.json";

const CryptoPunksMarket = contracts.TestCryptoPunksMarket.address;

async function main() {
  const { deployer } = await ethers.getNamedSigners();

  const market = CryptoPunksMarket__factory.connect(CryptoPunksMarket, deployer);

  await market.connect(deployer).allInitialOwnersAssigned();

  console.log(
    `${CryptoPunksMarket} activated`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
