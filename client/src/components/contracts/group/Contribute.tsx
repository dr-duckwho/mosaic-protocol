"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksGroupRegistryContribute,
  usePrepareCryptoPunksGroupRegistryContribute,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address, useAccount } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function Contribute() {
  const { address } = useAccount();
  const [groupId, setGroupId] = useState(0);
  const [ticketQuantity, setTicketQuantity] = useState(1);
  const [ticketPriceInWei, setTicketPriceInWei] = useState("0");

  const debouncedGroupId = useDebounce(groupId, 500);
  const debouncedTicketQuantity = useDebounce(ticketQuantity, 500);

  const { config } = usePrepareCryptoPunksGroupRegistryContribute({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [
      BigNumber.from(debouncedGroupId),
      BigNumber.from(debouncedTicketQuantity),
    ],
    overrides: {
      from: address,
      value: BigNumber.from(ticketPriceInWei),
    },
  });
  const { write: contribute } = useCryptoPunksGroupRegistryContribute(config);
  return (
    <div>
      <h2>Contribute (User)</h2>
      <div>
        <label>Group ID</label>
        <input
          type="number"
          value={groupId}
          onChange={(e) => setGroupId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Ticket Quantity</label>
        <input
          type="number"
          min={1}
          max={100}
          value={ticketQuantity}
          onChange={(e) => setTicketQuantity(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Ticket Price (wei)</label>
        <input
          type="number"
          value={ticketPriceInWei}
          onChange={(e) => setTicketPriceInWei(e.target.value)}
        />
        <code> === group.unitTicketPrice * ticketQuantity</code>
      </div>
      <button disabled={!contribute} onClick={() => contribute?.()}>
        Contribute
      </button>
    </div>
  );
}
