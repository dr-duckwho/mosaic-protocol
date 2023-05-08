import sepolia from "@/contracts/deployments/sepolia.json";
import { Address } from "wagmi";

export const MuseumAddr = sepolia.contracts.CryptoPunksMuseum
  .address as Address;
export const GroupRegistryAddr = sepolia.contracts.CryptoPunksGroupRegistry
  .address as Address;
export const MosaicRegistryAddr = sepolia.contracts.CryptoPunksMosaicRegistry
  .address as Address;
export const CryptoPunksMarketAddr = sepolia.contracts.TestCryptoPunksMarket
  .address as Address;
