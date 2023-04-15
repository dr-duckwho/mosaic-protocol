"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksGroupRegistryClaim,
  useCryptoPunksGroupRegistryClaimedEvent,
  usePrepareCryptoPunksGroupRegistryClaim,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function Claim() {
  const [groupId, setGroupId] = useState(0);

  const debouncedGroupId = useDebounce(groupId, 500);

  const { config } = usePrepareCryptoPunksGroupRegistryClaim({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [BigNumber.from(debouncedGroupId)],
  });
  const { write: contribute } = useCryptoPunksGroupRegistryClaim(config);
  useCryptoPunksGroupRegistryClaimedEvent();

  return (
    <div>
      <h2>Claim (User)</h2>
      <div>
        <label>Group ID</label>
        <input
          type="number"
          value={groupId}
          onChange={(e) => setGroupId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!contribute} onClick={() => contribute?.()}>
        Claim
      </button>
    </div>
  );
}
