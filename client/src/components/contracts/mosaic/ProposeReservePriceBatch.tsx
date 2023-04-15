"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryProposeReservePriceBatch,
  usePrepareCryptoPunksMosaicRegistryProposeReservePriceBatch,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function ProposeReservePriceBatch() {
  const [originalId, setOriginalId] = useState(0);
  const [price, setPrice] = useState(0);

  const debouncedTargetOriginalId = useDebounce(originalId, 500);
  const debouncedTargetPrice = useDebounce(price, 500);

  const { config } =
    usePrepareCryptoPunksMosaicRegistryProposeReservePriceBatch({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [
        BigNumber.from(debouncedTargetOriginalId),
        BigNumber.from(debouncedTargetPrice),
      ],
    });
  const { write: create } =
    useCryptoPunksMosaicRegistryProposeReservePriceBatch(config);

  return (
    <div>
      <h2>Propose reserve price batch (Mosaic Owner)</h2>
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
      <button disabled={!create} onClick={() => create?.()}>
        Propose reserve price batch
      </button>
    </div>
  );
}
