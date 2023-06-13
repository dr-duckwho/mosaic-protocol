"use client";

import {
  configureChains,
  createClient,
  goerli,
  mainnet,
  sepolia,
  WagmiConfig,
} from "wagmi";
import {
  darkTheme,
  getDefaultWallets,
  RainbowKitProvider,
  Theme,
} from "@rainbow-me/rainbowkit";
import { publicProvider } from "wagmi/providers/public";
import ClientOnly from "@/components/utils/ClientOnly";

const { chains, provider, webSocketProvider } = configureChains(
  [
    ...(process.env.NEXT_PUBLIC_ENABLE_TESTNETS === "true"
      ? [sepolia, goerli]
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

const theme = {
  ...darkTheme(),
  colors: {
    ...darkTheme().colors,
    accentColorForeground: "#AAAFC5",
    accentColor: "#1E212E",
    connectButtonBackground: "#1E212E",
    connectButtonText: "#AAAFC5",
    modalBackground: "#1E212E",
    modalText: "#AAAFC5",
  },
} as Theme;

export default function WagmiWrapper({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <WagmiConfig client={wagmiClient}>
      <RainbowKitProvider theme={theme} chains={chains}>
        <ClientOnly>{children}</ClientOnly>
      </RainbowKitProvider>
    </WagmiConfig>
  );
}
