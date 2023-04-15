import { Title } from "@/components/home/Title";
import { Feature } from "@/components/home/Feature";

export default function Page() {
  return (
    <>
      <Title
        badge="About"
        title="Mosaic Protocol: Fractionalizing and Recreating NFTS as a Team"
      />
      <Feature
        title="Become a partial owner of iconic NFTs"
        description=" Buy piecewise, win together, and get your own share. Join purchase
        divides cost and increases accessibility."
      />
      <Feature
        title="Team up to Fund on a Target Original"
        description="Choose any NFT on OpenSea to start or join a team. Buy tickets to fund your team’s collective purchase. Your funds are kept and tracked in your team’s vault, secured by Mosaic’s transparent smart contract."
      />
      <Feature
        title="Win and Claim The Original Together."
        description="Place bids in auctions or make a buy-now call, once your team reach its target fund. The original NFT won by your team is fractionalized and distributed pro rata: You get a new fractional NFT per ticket you have bought."
      />
      <Feature
        title="Transform and Recreate Your Pieces."
        description="Recreate the original and use it wherever you like. Turn your NFT into a new artwork of its own. Mosaic protocol gives you unique presets to begin with, if you want. Twist and tweak it. Show it off. Fractionalization never diminishes the utility that you sought in the original - its fun."
      />
    </>
  );
}
