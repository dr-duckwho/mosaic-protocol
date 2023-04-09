"use client";

import {
  configureChains,
  createClient,
  goerli,
  mainnet,
  WagmiConfig,
} from "wagmi";
import { getDefaultWallets, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { publicProvider } from "wagmi/providers/public";
import ClientOnly from "@/components/utils/ClientOnly";

const { chains, provider, webSocketProvider } = configureChains(
  [
    ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === "true"
      ? [goerli]
      : [mainnet]),
  ],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: "RainbowKit App",
  chains,
});

const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
  webSocketProvider,
});

export default function WagmiWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <WagmiConfig client={wagmiClient}>
      <RainbowKitProvider chains={chains}>
        <ClientOnly>{children}</ClientOnly>
      </RainbowKitProvider>
    </WagmiConfig>
  );
}
