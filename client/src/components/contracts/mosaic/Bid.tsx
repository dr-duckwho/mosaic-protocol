"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryBid,
  usePrepareCryptoPunksMosaicRegistryBid,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address, useAccount } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function Bid() {
  const { address } = useAccount();
  const [originalId, setOriginalId] = useState(0);
  const [price, setPrice] = useState(0);

  const debouncedOriginalId = useDebounce(originalId, 500);
  const debouncedPrice = useDebounce(price, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryBid({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedOriginalId), BigNumber.from(debouncedPrice)],
    overrides: {
      from: address,
      value: BigNumber.from(price),
    },
  });
  const { write: bid } = useCryptoPunksMosaicRegistryBid(config);

  return (
    <div>
      <h2>Bid (Original buyer)</h2>
      <div>
        <label>Original ID</label>
        <input
          type="number"
          value={originalId}
          onChange={(e) => setOriginalId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Price (wei)</label>
        <input
          type="number"
          min={0}
          value={price}
          onChange={(e) => setPrice(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!bid} onClick={() => bid?.()}>
        Bid
      </button>
    </div>
  );
}
