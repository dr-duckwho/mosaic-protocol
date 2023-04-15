import { Title } from "@/components/home/Title";
import { Feature } from "@/components/home/Feature";
import { CurrentAuction } from "@/components/home/CurrentAuction";
import { Button } from "@/components/home/Button";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Mosaic Protocol",
  description: "Fractionalizing and Recreating NFTS as a Team",
  openGraph: {
    title: "Mosaic Protocol",
    description: "Fractionalizing and Recreating NFTS as a Team",
    url: "https://mosaic-protocol.com/",
    locale: "en-US",
    type: "website",
    images: "/og.svg",
  },
};

export default function Home() {
  return (
    <>
      <Title title="Mosaic Protocol: Fractionalizing and Recreating NFTS as a Team" />
      <Feature
        title="Become a partial owner of iconic NFTs"
        description=" Buy piecewise, win together, and get your own share. Join purchase
        divides cost and increases accessibility."
      />
      <CurrentAuction punkId={3100} groupId={0} />
      <Feature title="Join our community" />
      <Button
        className="w-full px-5 mt-7"
        href={`https://telegram.org`}
        title="Open Telegram"
        icon="telegram"
      />
    </>
  );
}
