const formatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
});

export function GroupPrice(props: {
  ticketPrice: number;
  ethPrice: number;
  totalTicket: number;
}) {
  return (
    <div className="flex text-white mb-7">
      <div className="flex-1">
        <div className="text-sm">Ticket Price</div>
        <div className="text-xl font-medium">{props.ticketPrice} ETH</div>
        <div
          className="text-sm"
          style={{
            color: "#918090",
          }}
        >
          {formatter.format(props.ticketPrice * props.ethPrice)}
        </div>
      </div>
      <div className="flex-1 ml-5">
        <div className="text-sm">Auction Price</div>
        <div className="text-xl font-medium">
          {props.ticketPrice * props.totalTicket} ETH
        </div>
        <div
          className="text-sm"
          style={{
            color: "#918090",
          }}
        >
          {formatter.format(
            props.ticketPrice * props.ethPrice * props.totalTicket
          )}
        </div>
      </div>
    </div>
  );
}
