"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistrySetPresetId,
  usePrepareCryptoPunksMosaicRegistrySetPresetId,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";

export default function SetPresetId() {
  const [mosaicId, setMosaicId] = useState(0);
  const [presetId, setPresetId] = useState(0);

  const debouncedTargetMosaicId = useDebounce(mosaicId, 500);
  const debouncedTargetPresetId = useDebounce(presetId, 500);

  const { config } = usePrepareCryptoPunksMosaicRegistrySetPresetId({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedTargetMosaicId), debouncedTargetPresetId],
  });
  const { write: create } = useCryptoPunksMosaicRegistrySetPresetId(config);

  return (
    <div>
      <h2>Set Preset ID (Mosaic Owner)</h2>
      <div>
        <label>Mosaic ID</label>
        <input
          type="number"
          value={mosaicId}
          onChange={(e) => setMosaicId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Preset ID</label>
        <input
          type="number"
          min={0}
          value={presetId}
          onChange={(e) => setPresetId(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!create} onClick={() => create?.()}>
        Set Preset ID
      </button>
    </div>
  );
}
