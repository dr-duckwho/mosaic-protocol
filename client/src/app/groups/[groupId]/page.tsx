"use client";

import GroupSummary from "@/components/groups/GroupSummary";
import GroupContent from "@/components/groups/GroupContent";
import { useCryptoPunksGroupRegistryGetGroup } from "@/contracts/generated";
import { BigNumber } from "ethers";
import Error from "next/error";
import { GroupRegistryAddr } from "@/contracts/address";
import { useEffect, useState } from "react";

export default function Page({
  params: { groupId },
}: {
  params: { groupId: string };
}) {
  const { data: group } = useCryptoPunksGroupRegistryGetGroup({
    address: GroupRegistryAddr,
    args: [BigNumber.from(groupId)],
  });

  const [punkId] = useState(group?.targetPunkId.toNumber() || 0);
  const [totalTicket] = useState(group?.totalTicketSupply.toNumber() || 100);

  // TODO: wei가 아닌 ether로 표시하기
  const [ticketPrice] = useState(group?.unitTicketPrice.toNumber() || 0);

  const [ticketSold] = useState(group?.ticketsBought.toNumber() || 0);
  const [ethPrice, setEthPrice] = useState(0);
  const [expiresAt] = useState(new Date((group?.expiresAt || 0) * 1e3));

  useEffect(() => {
    fetch("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD")
      .then((res) => res.json())
      .then((data) => {
        setEthPrice(data.USD);
      });
  }, [group]);

  if (group?.status === 0) {
    return <Error statusCode={404} />;
  }

  return (
    <>
      {group && (
        <GroupSummary
          punkId={punkId}
          ticketPrice={ticketPrice}
          ethPrice={ethPrice}
          totalTicket={totalTicket}
          ticketSold={ticketSold}
          expiresAt={expiresAt}
        />
      )}
      <GroupContent />
    </>
  );
}
