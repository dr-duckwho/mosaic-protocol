import * as dotenv from "dotenv";
import * as fs from "fs";

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-preprocessor";
import "hardhat-deploy";

dotenv.config();

const getRemappings = () =>
  fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.GOERLI_PRIVATE_KEY ?? ""],
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from)) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
};

export default config;
