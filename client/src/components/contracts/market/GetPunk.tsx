"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMarketGetPunk,
  usePrepareCryptoPunksMarketGetPunk,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function GetPunk() {
  const [punkId, setPunkId] = useState(0);

  const debouncedPunkId = useDebounce(punkId, 500);

  const { config } = usePrepareCryptoPunksMarketGetPunk({
    address: testnet.contracts.TestCryptoPunksMarket.address as Address,
    args: [BigNumber.from(debouncedPunkId)],
  });
  const { write: contribute } = useCryptoPunksMarketGetPunk(config);

  return (
    <div>
      <h2>Get Punk (Punk Owner)</h2>
      <div>
        <label>Punk ID</label>
        <input
          type="number"
          value={punkId}
          onChange={(e) => setPunkId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!contribute} onClick={() => contribute?.()}>
        Get Punk
      </button>
    </div>
  );
}
