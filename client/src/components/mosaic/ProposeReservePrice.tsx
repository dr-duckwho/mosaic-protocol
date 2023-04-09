"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryProposeReservePrice,
  usePrepareCryptoPunksMosaicRegistryProposeReservePrice,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";

export default function ProposeReservePrice() {
  const [mosaicId, setMosaicId] = useState(0);
  const [price, setPrice] = useState(0);

  const debouncedTargetMosaicId = useDebounce(mosaicId, 500);
  const debouncedTargetPrice = useDebounce(price, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryProposeReservePrice({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [
      BigNumber.from(debouncedTargetMosaicId),
      BigNumber.from(debouncedTargetPrice),
    ],
  });
  const { write: create } =
    useCryptoPunksMosaicRegistryProposeReservePrice(config);

  return (
    <div>
      <h2>Propose reserve price (Mosaic Owner)</h2>
      <div>
        <label>Mosaic ID</label>
        <input
          type="number"
          value={mosaicId}
          onChange={(e) => setMosaicId(parseInt(e.target.value))}
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
        Propose reserve price
      </button>
    </div>
  );
}
