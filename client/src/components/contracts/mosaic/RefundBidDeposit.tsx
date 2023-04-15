"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryRefundBidDeposit,
  usePrepareCryptoPunksMosaicRegistryRefundBidDeposit,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function RefundBidDeposit() {
  const [bidId, setBidId] = useState(0);

  const debouncedBidId = useDebounce(bidId, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryRefundBidDeposit({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedBidId)],
  });
  const { write: refund } =
    useCryptoPunksMosaicRegistryRefundBidDeposit(config);

  return (
    <div>
      <h2>Refund bid (Original buyer)</h2>
      <div>
        <label>Bid ID</label>
        <input
          type="number"
          value={bidId}
          onChange={(e) => setBidId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!refund} onClick={() => refund?.()}>
        Refund bid
      </button>
    </div>
  );
}
