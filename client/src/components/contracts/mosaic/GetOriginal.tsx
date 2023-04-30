"use client";

import { useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import {
  useCryptoPunksMosaicRegistryGetAverageReservePriceProposals,
  useCryptoPunksMosaicRegistryGetDistributionStatus,
  useCryptoPunksMosaicRegistryGetLatestOriginalId,
  useCryptoPunksMosaicRegistryGetOriginal,
  useCryptoPunksMosaicRegistryGetPerMonoResaleFund,
  useCryptoPunksMosaicRegistryGetReconstitutionStatus,
  useCryptoPunksMosaicRegistryHasVotableActiveBid,
  useCryptoPunksMosaicRegistryIsBidAcceptable,
  useCryptoPunksMosaicRegistrySumBidResponses,
  useCryptoPunksMosaicRegistrySumReservePriceProposals,
} from "@/contracts/generated";
import { Address } from "wagmi";
import testnet from "@/contracts/deployments/testnet.json";
import { BigNumber } from "ethers";
import {
  DistributionStatus,
  OriginalState,
  ReconstitutionStatus,
} from "./enums";

export default function GetOriginal() {
  const { data: latestOriginalId } =
    useCryptoPunksMosaicRegistryGetLatestOriginalId({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    });
  const [originalId, setOriginalId] = useState(
    latestOriginalId?.toNumber() ?? 0
  );
  const debouncedOriginalId = useDebounce(originalId, 500);

  const { data: original } = useCryptoPunksMosaicRegistryGetOriginal({
    address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
    args: [BigNumber.from(debouncedOriginalId)],
  });

  const { data: hasOngoingBid } =
    useCryptoPunksMosaicRegistryHasVotableActiveBid({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: distributionStatus } =
    useCryptoPunksMosaicRegistryGetDistributionStatus({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: reconstitutionStatus } =
    useCryptoPunksMosaicRegistryGetReconstitutionStatus({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: average } =
    useCryptoPunksMosaicRegistryGetAverageReservePriceProposals({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: summedReservePriceProposalsData } =
    useCryptoPunksMosaicRegistrySumReservePriceProposals({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: summedBidResponsesData } =
    useCryptoPunksMosaicRegistrySumBidResponses({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  const { data: isBidAcceptable } = useCryptoPunksMosaicRegistryIsBidAcceptable(
    {
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    }
  );

  const { data: perMonoResaleFund } =
    useCryptoPunksMosaicRegistryGetPerMonoResaleFund({
      address: testnet.contracts.CryptoPunksMosaicRegistry.address as Address,
      args: [BigNumber.from(debouncedOriginalId)],
    });

  return (
    <div>
      <h2>Get Original</h2>
      <div>
        <label>Original ID</label>
        <input
          type="number"
          value={originalId}
          onChange={(e) => setOriginalId(parseInt(e.target.value))}
        />
      </div>
      <div>
        <div>
          <div>ID: {original?.id.toString()}</div>
          <div>Punk ID: {original?.punkId.toString()}</div>
          <div>Total Mono Supply: {original?.totalMonoSupply.toString()}</div>
          <div>Claimed Mono Count: {original?.claimedMonoCount.toString()}</div>
          <div>Purchase Price: {original?.purchasePrice.toString()}</div>
          <div>Min Reserve Price: {original?.minReservePrice.toString()}</div>
          <div>Max Reserve Price: {original?.maxReservePrice.toString()}</div>
          <div>Metadata Base URI: {original?.metadataBaseUri}</div>
          <div>State: {OriginalState[original?.state ?? 0]}</div>
          <div>Active Bid ID: {original?.activeBidId.toString()}</div>

          <div>Has Ongoing Bid: {hasOngoingBid?.toString()}</div>
          <div>
            Distribution Status: {DistributionStatus[distributionStatus ?? 0]}
          </div>
          <div>
            Reconstitution Status:{" "}
            {ReconstitutionStatus[reconstitutionStatus ?? 0]}
          </div>

          <div>Average Reserve Price Proposal: {average?.toString()}</div>
          <div>
            Summed Reserve Price Proposals:
            <ul>
              <li>
                validProposalCount:{" "}
                {summedReservePriceProposalsData?.validProposalCount.toString()}
              </li>
              <li>
                priceSum: {summedReservePriceProposalsData?.priceSum.toString()}
              </li>
            </ul>
          </div>
          <div>
            Summed Bid Responses:
            <ul>
              <li>yes: {summedBidResponsesData?.yes.toString()}</li>
              <li>no: {summedBidResponsesData?.no.toString()}</li>
            </ul>
          </div>
          <div>Is Bid Acceptable: {isBidAcceptable?.toString()}</div>
          <div>Per Mono Resale Fund: {perMonoResaleFund?.toString()}</div>
        </div>
      </div>
    </div>
  );
}
