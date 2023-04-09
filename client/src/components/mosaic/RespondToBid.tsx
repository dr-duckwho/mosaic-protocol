"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryRespondToBid,
  usePrepareCryptoPunksMosaicRegistryRespondToBid,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";
import { MonoBidResponse } from "./enums";

export default function RespondToBid() {
  const [mosaicId, setMosaicId] = useState(0);
  const [response, setResponse] = useState(0);

  const debouncedMosaicId = useDebounce(mosaicId, 500);
  const debouncedResponse = useDebounce(response, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistryRespondToBid({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedMosaicId), debouncedResponse],
  });
  const { write: respond } = useCryptoPunksMosaicRegistryRespondToBid(config);

  return (
    <div>
      <h2>Respond to bid (Mosaic Owner)</h2>
      <div>
        <label>Mosaic ID</label>
        <input
          type="number"
          value={mosaicId}
          onChange={(e) => setMosaicId(parseInt(e.target.value))}
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
