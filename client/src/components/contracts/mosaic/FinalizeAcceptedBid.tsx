"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryFinalizeAcceptedBid,
  usePrepareCryptoPunksMosaicRegistryFinalizeAcceptedBid,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function FinalizeAcceptedBid() {
  const [bidId, setBidId] = useState(0);

  const debouncedBidId = useDebounce(bidId, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryFinalizeAcceptedBid({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedBidId)],
  });
  const { write: finalize } =
    useCryptoPunksMosaicRegistryFinalizeAcceptedBid(config);

  return (
    <div>
      <h2>Finalize accepted bid</h2>
      <div>
        <label>Bid ID</label>
        <input
          type="number"
          value={bidId}
          onChange={(e) => setBidId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!finalize} onClick={() => finalize?.()}>
        Finalize accepted
      </button>
    </div>
  );
}
