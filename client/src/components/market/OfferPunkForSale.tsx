"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMarketOfferPunkForSale,
  usePrepareCryptoPunksMarketOfferPunkForSale,
} from "@/contracts/generated";
import { BigNumber } from "ethers";
import { Address } from "wagmi";
import testnet from "@/contracts/testnet.json";

export default function OfferPunkForSale() {
  const [punkId, setPunkId] = useState(0);
  const [minSalePriceInWei, setMinSalePriceInWei] = useState(1);

  const debouncedPunkId = useDebounce(punkId, 500);
  const debouncedMinSalePriceInWei = useDebounce(minSalePriceInWei, 500);

  const { config } = usePrepareCryptoPunksMarketOfferPunkForSale({
    address: testnet.contracts.TestCryptoPunksMarket.address as Address,
    args: [
      BigNumber.from(debouncedPunkId),
      BigNumber.from(debouncedMinSalePriceInWei),
    ],
  });
  const { write: offerPunkForSale } =
    useCryptoPunksMarketOfferPunkForSale(config);

  return (
    <div>
      <h2>Offer Punk for sale (Punk Owner)</h2>
      <div>
        <label>Punk ID</label>
        <input
          type="number"
          value={punkId}
          onChange={(e) => setPunkId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <label>Minimum sale price (wei)</label>
        <input
          type="number"
          min={1}
          max={100}
          value={minSalePriceInWei}
          onChange={(e) => setMinSalePriceInWei(parseInt(e.target.value))}
        />
      </div>
      <button disabled={!offerPunkForSale} onClick={() => offerPunkForSale?.()}>
        Offer Punk for sale
      </button>
    </div>
  );
}
