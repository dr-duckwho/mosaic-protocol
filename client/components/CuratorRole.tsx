"use client";

import { Address } from "wagmi";
import contractMetadata from "../contract/deployments/testnet.json";
import { useCryptoPunksGroupRegistryCuratorRole } from "@/contract/generated";

export default function CuratorRole() {
  const { data: curatorRole } = useCryptoPunksGroupRegistryCuratorRole({
    address: contractMetadata.contracts.CryptoPunksGroupRegistry
      .address as Address,
  });

  return <p>CURATOR_ROLE: {curatorRole}</p>;
}
