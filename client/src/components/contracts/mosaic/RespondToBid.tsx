"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryRespondToBidBatch,
  usePrepareCryptoPunksMosaicRegistryRespondToBidBatch,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";
import { MonoBidResponse } from "./enums";

export default function RespondToBid() {
  const [originalId, setOriginalId] = useState(0);
  const [response, setResponse] = useState(0);

  const debouncedOriginalId = useDebounce(originalId, 500);
  const debouncedResponse = useDebounce(response, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryRespondToBidBatch({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedOriginalId), debouncedResponse],
  });
  const { write: respond } =
    useCryptoPunksMosaicRegistryRespondToBidBatch(config);

  return (
    <div>
      <h2>Respond to bid batch (Mosaic Owner)</h2>
      <div>
        <label>Original ID</label>
        <input
          type="number"
          value={originalId}
          onChange={(e) => setOriginalId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Response</label>
        <select
          onChange={(e) => setResponse(parseInt(e.target.value))}
          value={response}
        >
          {MonoBidResponse.map((response, index) => (
            <option key={index} value={index}>
              {response}
            </option>
          ))}
        </select>
      </div>
      <button disabled={!respond} onClick={() => respond?.()}>
        Respond to bid
      </button>
    </div>
  );
}
