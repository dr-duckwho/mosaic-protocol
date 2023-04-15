"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryFinalizeProposedBid,
  usePrepareCryptoPunksMosaicRegistryFinalizeProposedBid,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function FinalizeProposedBid() {
  const [bidId, setBidId] = useState(0);

  const debouncedBidId = useDebounce(bidId, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryFinalizeProposedBid({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedBidId)],
  });
  const { write: finalize } =
    useCryptoPunksMosaicRegistryFinalizeProposedBid(config);

  return (
    <div>
      <h2>Finalize proposed bid</h2>
      <div>
        <label>Bid ID</label>
        <input
          type="number"
          value={bidId}
          onChange={(e) => setBidId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!finalize} onClick={() => finalize?.()}>
        Finalize proposed
      </button>
    </div>
  );
}
