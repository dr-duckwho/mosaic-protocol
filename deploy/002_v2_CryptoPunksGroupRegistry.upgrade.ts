import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

/**
 * Sample code for upgrading a contract
 */

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  await deploy("CryptoPunksGroupRegistry", {
    contract: "CryptoPunksGroupRegistryV2",
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: "ERC1967Proxy",
      proxyArgs: ["{implementation}", "{data}"],
    },
    log: true,
  });
};

export default func;
func.tags = ["CryptoPunksGroupRegistry"];
