"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryRefundOnSold,
  usePrepareCryptoPunksMosaicRegistryRefundOnSold,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function RefundOnSold() {
  const [originalId, setOriginalId] = useState(0);

  const debouncedOriginalId = useDebounce(originalId, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryRefundOnSold({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedOriginalId)],
  });
  const { write: refund } = useCryptoPunksMosaicRegistryRefundOnSold(config);

  return (
    <div>
      <h2>Refund on sold (Sold mosaic owner)</h2>
      <div>
        <label>Original ID</label>
        <input
          type="number"
          value={originalId}
          onChange={(e) => setOriginalId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!refund} onClick={() => refund?.()}>
        Burn & Refund
      </button>
    </div>
  );
}
