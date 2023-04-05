import "./globals.css";
import React from "react";
import WalletProvider from "@/components/WalletProvider";
import Web3Button from "@/components/Web3Button";

export const metadata = {
  title: "Mosaic Protocol",
  description: "Fractionalize and Recreate NFTs as a Team.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="mx-32 my-12">
        <header className="flex justify-between">
          <div>Mosaic Protocol</div>
          <Web3Button label="Connect Wallet" />
        </header>
        <WalletProvider>{children}</WalletProvider>
      </body>
    </html>
  );
}
