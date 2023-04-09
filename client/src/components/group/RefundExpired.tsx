"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksGroupRegistryRefundExpired,
  usePrepareCryptoPunksGroupRegistryRefundExpired,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";

export default function RefundExpired() {
  const [groupId, setGroupId] = useState(0);

  const debouncedGroupId = useDebounce(groupId, 500);

  const { config } = usePrepareCryptoPunksGroupRegistryRefundExpired({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [BigNumber.from(debouncedGroupId)],
  });
  const { write: refundExpired } =
    useCryptoPunksGroupRegistryRefundExpired(config);

  return (
    <div>
      <h2>Refund Expired (User)</h2>
      <div>
        <label>Group ID</label>
        <input
          type="number"
          value={groupId}
          onChange={(e) => setGroupId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!refundExpired} onClick={() => refundExpired?.()}>
        Refund Expired
      </button>
    </div>
  );
}
