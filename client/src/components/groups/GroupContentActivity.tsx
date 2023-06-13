"use client";

import Jazzicon from "react-jazzicon";
import Image from "next/image";
import { getGroupEvents } from "@/components/contracts/client";
import { useEffect, useState } from "react";
import { Log } from "viem";
import Link from "next/link";

const secondary = {
  color: "#7B8198",
};

export default function GroupContentActivity() {
  const [isLoaded, setIsLoaded] = useState(false);
  const [events, setEvents] = useState<Log[]>([]);

  useEffect(() => {
    if (isLoaded) return;

    const groupId = 1;
    getGroupEvents(groupId, [
      "Claimed",
      "GroupCreated",
      "GroupWon",
      "Contributed",
    ]).then((events) => {
      const result: Log[] = events.flatMap((event) => event);
      // @ts-ignore
      result.sort((a, b) => parseInt(b.blockNumber) - parseInt(a.blockNumber));
      setEvents(result);
      console.log(result);
      setIsLoaded(true);
    });
  }, [events]);

  return (
    <section className="mt-7">
      {events.map((event, index) => (
        <GroupContentActivityItem key={index} event={event} />
      ))}
    </section>
  );
}

function GroupContentActivityItem({ event }: { event: Log }) {
  return (
    <div
      style={{
        backgroundColor: "#1B1B1E",
      }}
      className="flex justify-between items-center px-5 py-4 mb-4"
    >
      <div className="flex">
        <div className="flex pt-0.5 -ml-1">
          <Jazzicon diameter={18} seed={1} />
        </div>
        <div className="ml-2 flex-col justify-start">
          <div className="text-white text-sm font-medium">
            <span style={secondary}>
              {event.address.substring(0, 5)}...{event.address.substring(39)}
            </span>{" "}
            {event.eventName}
          </div>
          <div style={secondary} className="text-xs flex items-center">
            #{parseInt(event.blockNumber)}
            <Link
              href={`https://sepolia.etherscan.io/block/${parseInt(
                event.blockNumber
              )}`}
              target="_blank"
            >
              <Image
                className="ml-1.5"
                src="/link.svg"
                alt="link"
                width={9}
                height={9}
              />
            </Link>
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
