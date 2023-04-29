import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { contracts } from "../deployments/testnet.json";

const CryptoPunksMuseumAddress = contracts.CryptoPunksMuseum.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  await deploy("CryptoPunksGroupRegistry", {
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: "UUPS",
      proxyArgs: ["{implementation}", "{data}"],
      execute: {
        methodName: "initialize",
        args: [CryptoPunksMuseumAddress],
      },
    },
    log: true,
  });
};
export default func;
func.tags = ["CryptoPunksGroupRegistry"];
