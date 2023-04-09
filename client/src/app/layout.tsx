import "./globals.css";
import "@rainbow-me/rainbowkit/styles.css";

import ConnectButton from "@/components/wrapped/ConnectButton";
import WagmiWrapper from "@/components/wrapped/WagmiWrapper";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>
        <WagmiWrapper>
          <ConnectButton />
          {children}
        </WagmiWrapper>
      </body>
    </html>
  );
}
