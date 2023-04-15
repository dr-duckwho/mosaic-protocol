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
}: {
  punkId: number;
  ticketPrice: number;
  ethPrice: number;
  totalTicket: number;
  ticketSold: number;
}) {
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
            Expires in 3 Days (23.04.08)
          </div>
          <Button className="w-full mt-4" light title="Buy Tickets" href="#" />
        </div>
      </div>
    </>
  );
}
