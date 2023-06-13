import Image from "next/image";

type PhaseStatus = "Complete" | "Active" | "Failed";
type Phase = "Auction" | "Distribution" | "Reconstitution" | "Close";

function GroupContentPhastDataItem({
  index,
  step,
  status,
  endsOn,
}: {
  index: number;
  step: Phase;
  status?: PhaseStatus;
  endsOn?: Date;
}) {
  const statusBackground: {
    Active: { color: string; background: string };
    Complete: { color: string; backgroundColor: string };
    Failed: { color: string; backgroundColor: string };
  } = {
    Active: {
      color: "#1B1B1E",
      background: "linear-gradient(93.21deg, #FFFFFF 14.82%, #80B1FB 91.44%)",
    },
    Complete: {
      color: "#FFFFFF",
      backgroundColor: "#29304B",
    },
    Failed: {
      color: "#FFFFFF",
      backgroundColor: "#DF4343",
    },
  };

  const formatDate = (date: Date) => {
    const options: Intl.DateTimeFormatOptions = {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      hour12: true,
    };
    return date.toLocaleString("en-US", options);
  };

  return (
    <div
      className={`flex items-stretch text-white mt-4 ${
        !status && "opacity-50"
      }`}
    >
      <div
        style={{
          backgroundColor: "#292F46",
        }}
        className="flex flex-1 justify-center items-center w-100 py-6 text-xl font-medium pb-11"
      >
        {index}
      </div>
      <div
        style={{
          backgroundColor: "#1B1B1E",
          flex: 6,
        }}
        className="py-6 px-4"
      >
        <div className="flex justify-start items-center">
          <h2 className="text-xl font-medium">{step}</h2>
          {status && (
            <div
              style={statusBackground[status]}
              className="ml-1.5 rounded-2xl px-2 py-0.5 text-xs font-medium mt-0.5"
            >
              {status}
            </div>
          )}
        </div>
        <div
          style={{
            color: "#8B8F9F",
          }}
          className="flex justify-start items-center text-xs mt-1"
        >
          <Image
            className="mr-1"
            src={status ? `/time.svg` : `/upcoming.svg`}
            alt="time"
            width={10}
            height={10}
          />
          {endsOn ? `End on ${formatDate(endsOn)}` : "Upcoming"}
        </div>
      </div>
      <button
        style={{
          backgroundColor: "#1B1B1E",
        }}
        className="flex flex-1 justify-center items-center py-6 pr-2.5"
      >
        <Image src="/down.svg" alt="open" width={16} height={10} />
      </button>
    </div>
  );
}

export default function GroupContentPhaseData() {
  return (
    <div className="mt-7">
      <GroupContentPhastDataItem
        index={1}
        step={"Auction"}
        status={"Complete"}
        endsOn={new Date("2023/04/28")}
      />
      <GroupContentPhastDataItem
        index={2}
        step={"Distribution"}
        status={"Active"}
        endsOn={new Date("2023/05/02")}
      />
      <GroupContentPhastDataItem index={3} step={"Reconstitution"} />
      <GroupContentPhastDataItem index={4} step={"Close"} />
    </div>
  );
}
