import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { contracts } from "../deployments/testnet.json";

const CryptoPunksMarketAddress = contracts.CryptoPunksMarket.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  await deploy("CryptoPunksMosaicRegistry", {
    from: deployer,
    args: [deployer, CryptoPunksMarketAddress],
    log: true,
  });
};
export default func;
func.tags = ["CryptoPunksMosaicRegistry"];
