import Jazzicon from "react-jazzicon";
import Image from "next/image";

const secondary = {
  color: "#918090",
};

export default function GroupContentActivity() {
  return (
    <section className="mt-7">
      {Array.from({ length: 4 }).map((_, index) => (
        <GroupContentActivityItem key={index} />
      ))}
    </section>
  );
}

function GroupContentActivityItem() {
  return (
    <div
      style={{
        backgroundColor: "#320D33",
      }}
      className="flex justify-between items-center px-5 py-4 mb-4"
    >
      <div className="flex">
        <div className="flex pt-0.5 -ml-1">
          <Jazzicon diameter={18} seed={1} />
        </div>
        <div className="ml-2 flex-col justify-start">
          <div className="text-white text-sm font-medium">
            <span style={secondary}>0x1234</span> bought 2 Tickets
          </div>
          <div style={secondary} className="text-xs flex items-center">
            16 Dec 2022, 05:12 pm
            <Image
              className="ml-1.5"
              src="/link.svg"
              alt="link"
              width={9}
              height={9}
            />
          </div>
        </div>
      </div>
      <div className="flex-col justify-end">
        <div className="text-right text-white text-sm font-medium">1 ETH</div>
        <div style={secondary} className="text-right text-xs">
          $282
        </div>
      </div>
    </div>
  );
}
