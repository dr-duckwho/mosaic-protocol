import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  const { address: CryptoPunksMarketAddress } = await deploy(
    "TestCryptoPunksMarket",
    {
      contract: "CryptoPunksMarket",
      from: deployer,
      args: [],
      log: true,
    }
  );

  const { address: CryptoPunksMuseumAddress } = await deploy(
    "CryptoPunksMuseum",
    {
      from: deployer,
      args: [CryptoPunksMarketAddress],
      log: true,
    }
  );

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

  await deploy("CryptoPunksMosaicRegistry", {
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
func.tags = ["MosaicProtocol"];
