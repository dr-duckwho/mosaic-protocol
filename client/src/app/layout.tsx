import "./globals.css";
import "@rainbow-me/rainbowkit/styles.css";
import WagmiWrapper from "@/components/contracts/wrapped/WagmiWrapper";
import { Navigation } from "@/components/layout/Navigation";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>
        <WagmiWrapper>
          <Navigation />
          <main className="overflow-hidden mb-20">{children}</main>
        </WagmiWrapper>
      </body>
    </html>
  );
}
