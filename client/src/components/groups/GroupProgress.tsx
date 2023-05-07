export function GroupProgress(props: {
  totalTicket: number;
  ticketSold: number;
}) {
  return (
    <div className="flex text-white">
      <div className="flex-1">
        <div className="text-sm">Ticket Supply</div>
        <div className="text-xl font-medium">
          {props.totalTicket - props.ticketSold} left
        </div>
        <div
          className="w-full h-1 mt-2"
          style={{
            backgroundColor: "#3E324B",
          }}
        >
          <div
            className="h-full"
            style={{
              width: `${(props.ticketSold / props.totalTicket) * 100}%`,
              backgroundColor: `#E2D770`,
            }}
          />
        </div>
        <div className="mt-3 flex justify-between text-xs">
          <div
            style={{
              color: "#E2D770",
            }}
          >
            {/* TODO: wei가 아닌 eth로 표기 */}
            {props.ticketSold} wei Funded
          </div>
          <div
            style={{
              color: "#918090",
            }}
          >
            / {props.totalTicket} Tickets (Total)
          </div>
        </div>
      </div>
    </div>
  );
}
