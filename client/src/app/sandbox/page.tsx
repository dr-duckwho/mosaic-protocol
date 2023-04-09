import "./styles.module.css";
import { Inter } from "next/font/google";
import GetPunk from "@/components/market/GetPunk";
import OfferPunkForSale from "@/components/market/OfferPunkForSale";
import CreateGroup from "@/components/group/CreateGroup";
import GetGroup from "@/components/group/GetGroup";
import Contribute from "@/components/group/Contribute";
import Buy from "@/components/group/Buy";
import Claim from "@/components/group/Claim";
import RefundExpired from "@/components/group/RefundExpired";
import SetPresetId from "@/components/mosaic/SetPresetId";
import ProposeReservePrice from "@/components/mosaic/ProposeReservePrice";
import ProposeReservePriceBatch from "@/components/mosaic/ProposeReservePriceBatch";
import Bid from "@/components/mosaic/Bid";
import RefundBidDeposit from "@/components/mosaic/RefundBidDeposit";
import RespondToBid from "@/components/mosaic/RespondToBid";
import FinalizeProposedBid from "@/components/mosaic/FinalizeProposedBid";
import FinalizeAcceptedBid from "@/components/mosaic/FinalizeAcceptedBid";
import GetOriginal from "@/components/mosaic/GetOriginal";
import GetMono from "@/components/mosaic/GetMono";

const inter = Inter({ subsets: ["latin"] });

export default function Sandbox() {
  return (
    <main>
      <h1>CryptoPunksMarket</h1>
      <GetPunk />
      <OfferPunkForSale />
      <hr />

      <h1>CryptoPunksGroupRegistry</h1>
      <CreateGroup />
      <GetGroup />
      <Contribute />
      <Buy />
      <Claim />
      <RefundExpired />
      <hr />

      <h1>CryptoPunksMosaicRegistry</h1>
      <SetPresetId />
      <ProposeReservePrice />
      <ProposeReservePriceBatch />
      <Bid />
      <RefundBidDeposit />
      <RespondToBid />
      <FinalizeProposedBid />
      <FinalizeAcceptedBid />
      <GetOriginal />
      <GetMono />
    </main>
  );
}
