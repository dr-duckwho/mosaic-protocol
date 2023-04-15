"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryGetLatestOriginalId,
  useCryptoPunksMosaicRegistryGetMono,
  useCryptoPunksMosaicRegistryGetMonoLifeCycle,
  useCryptoPunksMosaicRegistryToMosaicId,
} from "@/contracts/generated";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";
import { BigNumber } from "ethers";
import { MonoBidResponse } from "@/components/contracts/mosaic/enums";

export default function GetMono() {
  const { data: latestOriginalId } =
    useCryptoPunksMosaicRegistryGetLatestOriginalId({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    });
  const [originalId, setOriginalId] = useState(
    latestOriginalId?.toNumber() ?? 0
  );
  const debouncedOriginalId = useDebounce(originalId, 500);

  const [monoId, setMonoId] = useState(0);
  const debouncedMonoId = useDebounce(monoId, 500);

  const { data: mosaicIdFromOriginalAndMono } =
    useCryptoPunksMosaicRegistryToMosaicId({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [
        BigNumber.from(debouncedOriginalId),
        BigNumber.from(debouncedMonoId),
      ],
    });

  const [mosaicId, setMosaicId] = useState(
    mosaicIdFromOriginalAndMono ?? BigNumber.from(0)
  );
  const debouncedMosaicId = useDebounce(mosaicId, 500);

  const { data: mono } = useCryptoPunksMosaicRegistryGetMono({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [
      BigNumber.from(debouncedOriginalId),
      BigNumber.from(debouncedMonoId),
    ],
  });

  const { data: lifeCycle } = useCryptoPunksMosaicRegistryGetMonoLifeCycle({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedMosaicId)],
  });

  return (
    <div>
      <h2>Get Mono</h2>
      <div>
        <label>Original ID</label>
        <input
          type="number"
          value={originalId}
          onChange={(e) => setOriginalId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Mono ID</label>
        <input
          type="number"
          value={monoId}
          onChange={(e) => setMonoId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <div>Mosaic ID: {mono?.mosaicId.toString()}</div>
        <div>Preset ID: {mono?.presetId.toString()}</div>
        <div>
          Proposed Reserve Price:{" "}
          {mono?.governanceOptions.proposedReservePrice.toString()}
        </div>
        <div>
          Bid Response:{" "}
          {MonoBidResponse[mono?.governanceOptions.bidResponse ?? 0]}
        </div>
        <div>Bid ID: {mono?.governanceOptions.bidId.toString()}</div>
      </div>
    </div>
  );
}
