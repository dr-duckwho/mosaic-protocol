"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksGroupRegistryGetGroup,
  useCryptoPunksGroupRegistryGetGroupLifeCycle,
  useCryptoPunksGroupRegistryGetLatestGroupId,
} from "@/contracts/generated";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";
import { BigNumber } from "ethers";
import { GroupLifeCycle, GroupStatus } from "./enums";

export default function GetGroup() {
  const { data: latestGroupId } = useCryptoPunksGroupRegistryGetLatestGroupId({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
  });
  const [groupId, setGroupId] = useState(latestGroupId?.toNumber() ?? 0);
  const debouncedGroupId = useDebounce(groupId, 500);

  const { data: latestGroup } = useCryptoPunksGroupRegistryGetGroup({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [BigNumber.from(debouncedGroupId)],
  });

  const { data: lifeCycle } = useCryptoPunksGroupRegistryGetGroupLifeCycle({
    address: testnet.contracts.CryptoPunksGroupRegistry.address as Address,
    args: [BigNumber.from(debouncedGroupId)],
  });

  return (
    <div>
      <h2>Get Group</h2>
      <div>
        <label>Group ID</label>
        <input
          type="number"
          value={groupId}
          onChange={(e) => setGroupId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <div>LifeCycle: {GroupLifeCycle[lifeCycle ?? 0]}</div>
        <div>
          <div>ID: {latestGroup?.id.toString()}</div>
          <div>Creator: {latestGroup?.creator}</div>
          <div>Target Punk ID: {latestGroup?.targetPunkId.toString()}</div>
          <div>Target Max Price: {latestGroup?.targetMaxPrice.toString()}</div>
          <div>
            Total Ticket Supply: {latestGroup?.totalTicketSupply.toString()}
          </div>
          <div>
            Unit Ticket Price: {latestGroup?.unitTicketPrice.toString()}
          </div>
          <div>
            Total Contribution: {latestGroup?.totalContribution.toString()}
          </div>
          <div>Tickets Bought: {latestGroup?.ticketsBought.toString()}</div>
          <div>Expires At: {latestGroup?.expiresAt.toString()}</div>
          <div>Status: {GroupStatus[latestGroup?.status ?? 0]}</div>
          <div>Purchase Price: {latestGroup?.purchasePrice.toString()}</div>
          <div>Original ID: {latestGroup?.originalId.toString()}</div>
          <div>Metadata URI: {latestGroup?.metadataUri}</div>
        </div>
      </div>
    </div>
  );
}
