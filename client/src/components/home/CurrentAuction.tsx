"use client";

import { Button } from "@/components/home/Button";
import { CryptoPunkImage } from "@/components/groups/CryptoPunkImage";
import {
  useCryptoPunksGroupRegistryGetGroup,
  useCryptoPunksGroupRegistryGetLatestGroupId,
} from "@/contracts/generated";
import { GroupRegistryAddr } from "@/contracts/address";
import { BigNumber } from "ethers";
import { LiveGroupDecorator } from "@/components/home/LiveGroupDecorator";

export function CurrentAuction() {
  const { data: latestGroupId } = useCryptoPunksGroupRegistryGetLatestGroupId({
    address: GroupRegistryAddr,
  });
  const { data: group } = useCryptoPunksGroupRegistryGetGroup({
    address: GroupRegistryAddr,
    args: [BigNumber.from(latestGroupId || 0)],
  });
  const punkId = group?.targetPunkId.toNumber() || 0;
  return (
    <div className="mt-24 mb-20">
      <h2 className="text-subtitle font-medium text-3xl text-center mb-7 px-6">
        Current Auction
      </h2>
      <CryptoPunkImage punkId={punkId}>
        <LiveGroupDecorator punkId={punkId} />
      </CryptoPunkImage>
      <Button
        className="w-full px-5 mt-7"
        light
        href={`/groups/${latestGroupId}`}
        title="Jump to Group"
      />
    </div>
  );
}
