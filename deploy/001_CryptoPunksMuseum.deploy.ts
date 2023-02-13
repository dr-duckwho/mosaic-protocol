import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { contracts } from "../deployments/testnet.json";

const CryptoPunksMarketAddress = contracts.TestCryptoPunksMarket.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  await deploy("CryptoPunksMuseum", {
    from: deployer,
    args: [CryptoPunksMarketAddress],
    log: true,
  });
};
export default func;
func.tags = ["CryptoPunksMuseum"];
