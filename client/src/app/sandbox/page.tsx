import "./styles.module.css";
import { Inter } from "next/font/google";
import GetPunk from "@/components/contracts/market/GetPunk";
import OfferPunkForSale from "@/components/contracts/market/OfferPunkForSale";
import CreateGroup from "@/components/contracts/group/CreateGroup";
import GetGroup from "@/components/contracts/group/GetGroup";
import Contribute from "@/components/contracts/group/Contribute";
import Buy from "@/components/contracts/group/Buy";
import Claim from "@/components/contracts/group/Claim";
import RefundExpired from "@/components/contracts/group/RefundExpired";
import SetPresetId from "@/components/contracts/mosaic/SetPresetId";
import ProposeReservePrice from "@/components/contracts/mosaic/ProposeReservePrice";
import ProposeReservePriceBatch from "@/components/contracts/mosaic/ProposeReservePriceBatch";
import Bid from "@/components/contracts/mosaic/Bid";
import RefundBidDeposit from "@/components/contracts/mosaic/RefundBidDeposit";
import RespondToBid from "@/components/contracts/mosaic/RespondToBid";
import FinalizeProposedBid from "@/components/contracts/mosaic/FinalizeProposedBid";
import FinalizeAcceptedBid from "@/components/contracts/mosaic/FinalizeAcceptedBid";
import GetOriginal from "@/components/contracts/mosaic/GetOriginal";
import GetMono from "@/components/contracts/mosaic/GetMono";

const inter = Inter({ subsets: ["latin"] });

export default function Sandbox() {
  return (
    <main className="p-2">
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
