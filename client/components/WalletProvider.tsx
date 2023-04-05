"use client";

import {
  EthereumClient,
  w3mConnectors,
  w3mProvider,
} from "@web3modal/ethereum";
import { configureChains, createClient, WagmiConfig } from "wagmi";
import { goerli } from "wagmi/chains";
import { Web3Modal } from "@web3modal/react";
import React from "react";
import { alchemyProvider } from "wagmi/providers/alchemy";

const chains = [goerli];

if (!process.env.NEXT_PUBLIC_PROJECT_ID) {
  throw new Error("NEXT_PUBLIC_PROJECT_ID env variable not found");
}
const projectId = process.env.NEXT_PUBLIC_PROJECT_ID;

if (!process.env.NEXT_PUBLIC_ALCHEMY_API_KEY) {
  throw new Error("NEXT_PUBLIC_ALCHEMY_API_KEY env variable not found");
}
const alchemyApiKey = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

const { provider } = configureChains(chains, [
  w3mProvider({ projectId }),
  alchemyProvider({
    apiKey: alchemyApiKey,
  }),
]);
const wagmiClient = createClient({
  autoConnect: true,
  connectors: w3mConnectors({ projectId, version: 1, chains }),
  provider,
});
const ethereumClient = new EthereumClient(wagmiClient, chains);

export default function WalletProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  // https://wagmi.sh/react/hooks/useAccount
  // const { address, isConnected } = useAccount();
  // const { data: signer, isError, isLoading } = useSigner();
  // const { data, isError, isLoading } = useContractRead({
  //   address: testnetJson.contracts.CryptoPunksGroupRegistry.address as Address,
  //   abi: testnetJson.contracts.CryptoPunksGroupRegistry.abi,
  //   functionName: "CURATOR_ROLE",
  // });
  return (
    <>
      <WagmiConfig client={wagmiClient}>{children}</WagmiConfig>
      <Web3Modal projectId={projectId} ethereumClient={ethereumClient} />
    </>
  );
}
