import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  await deploy("CryptoPunksMarket", {
    contract: "CryptoPunksMarket",
    from: deployer,
    args: [],
    log: true,
  });
};
export default func;
func.tags = ["TestCryptoPunksMarket"];
