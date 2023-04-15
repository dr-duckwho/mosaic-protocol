"use client";

import { useState } from "react";
import {
  useCryptoPunksGroupRegistryBuy,
  usePrepareCryptoPunksGroupRegistryBuy,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";
import useDebounce from "@/hooks/useDebounce";

export default function Buy() {
  const [groupId, setGroupId] = useState(0);

  const debouncedGroupId = useDebounce(groupId, 500);

  const { config } = usePrepareCryptoPunksGroupRegistryBuy({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [BigNumber.from(debouncedGroupId)],
  });
  const { write: contribute } = useCryptoPunksGroupRegistryBuy(config);

  return (
    <div>
      <h2>Buy (Curator)</h2>
      <div>
        <label>Group ID</label>
        <input
          type="number"
          value={groupId}
          onChange={(e) => setGroupId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!contribute} onClick={() => contribute?.()}>
        Buy
      </button>
    </div>
  );
}
