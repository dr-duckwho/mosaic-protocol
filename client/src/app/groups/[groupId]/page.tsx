import GroupSummary from "@/components/groups/GroupSummary";
import GroupContent from "@/components/groups/GroupContent";

export default function Page({
  params: { groupId },
}: {
  params: { groupId: string };
}) {
  const punkId = 3100;
  const totalTicket = 100;
  const ethPrice = 282;
  const ticketPrice = 1;
  const ticketSold = 51;

  return (
    <>
      <GroupSummary
        punkId={punkId}
        ticketPrice={ticketPrice}
        ethPrice={ethPrice}
        totalTicket={totalTicket}
        ticketSold={ticketSold}
      />
      <GroupContent />
    </>
  );
}
