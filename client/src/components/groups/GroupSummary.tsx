"use client";

import { CryptoPunkImage } from "@/components/groups/CryptoPunkImage";
import { Button } from "@/components/home/Button";
import { GroupProgress } from "@/components/groups/GroupProgress";
import { GroupHeader } from "@/components/groups/GroupHeader";
import { GroupPrice } from "@/components/groups/GroupPrice";

export default function GroupSummary({
  ethPrice,
  punkId,
  ticketPrice,
  ticketSold,
  totalTicket,
  expiresAt,
}: {
  punkId: number;
  ticketPrice: number;
  ethPrice: number;
  totalTicket: number;
  ticketSold: number;
  expiresAt: Date;
}) {
  const now = new Date();
  const diff = expiresAt.getTime() - now.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const formattedDate = expiresAt.toLocaleDateString("en-US", {
    year: "2-digit",
    month: "2-digit",
    day: "2-digit",
  });
  return (
    <>
      <CryptoPunkImage punkId={punkId}></CryptoPunkImage>
      <div className="px-5">
        <GroupHeader punkId={punkId} />
        <GroupPrice
          ticketPrice={ticketPrice}
          ethPrice={ethPrice}
          totalTicket={totalTicket}
        />
        <GroupProgress totalTicket={totalTicket} ticketSold={ticketSold} />
        <div className="mt-9">
          <div className="text-center text-sm text-primary">
            Expires in {days} Days ({formattedDate})
          </div>
          <Button className="w-full mt-4" light title="Buy Tickets" href="#" />
        </div>
      </div>
    </>
  );
}
