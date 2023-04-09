"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksGroupRegistryCreate,
  usePrepareCryptoPunksGroupRegistryCreate,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";

export default function CreateGroup() {
  const [targetPunkId, setTargetPunkId] = useState(0);
  const [targetMaxPrice, setTargetMaxPrice] = useState("0");

  const debouncedTargetPunkId = useDebounce(targetPunkId, 500);
  const debouncedTargetMaxPrice = useDebounce(targetMaxPrice, 500);

  const { config } = usePrepareCryptoPunksGroupRegistryCreate({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [
      BigNumber.from(debouncedTargetPunkId),
      BigNumber.from(debouncedTargetMaxPrice),
    ],
  });
  const { write: create } = useCryptoPunksGroupRegistryCreate(config);

  return (
    <div>
      <h2>Create Group (Curator)</h2>
      <div>
        <label>Target Punk ID</label>
        <input
          type="number"
          value={targetPunkId}
          onChange={(e) => setTargetPunkId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Target Max Price (wei)</label>
        <input
          type="number"
          min={0}
          value={targetMaxPrice}
          onChange={(e) => setTargetMaxPrice(e.target.value)}
        />
      </div>
      <button disabled={!create} onClick={() => create?.()}>
        Create Group
      </button>
    </div>
  );
}
