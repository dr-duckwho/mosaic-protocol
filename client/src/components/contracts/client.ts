import { createPublicClient, http } from "viem";
import { sepolia } from "viem/chains";
import { contracts } from "@/contracts/deployments/sepolia.json";
import { GroupRegistryAddr } from "@/contracts/address";

const client = createPublicClient({
  chain: sepolia,
  transport: http(),
});

/**
 *     event GroupCreated(
 *         uint192 indexed groupId,
 *         address indexed creator,
 *         uint256 targetMaxPrice,
 *         uint64 totalTicketSupply,
 *         uint256 unitTicketPrice
 *     );
 *
 *     event GroupWon(uint192 indexed groupId);
 *
 *     event Contributed(
 *         address indexed contributor,
 *         uint192 indexed groupId,
 *         uint96 indexed ticketQuantity
 *     );
 *
 *     event Claimed(
 *         address indexed claimer,
 *         uint192 indexed groupId,
 *         uint256 indexed mosaicId
 *     )
 */

export async function getGroupEvents(groupId: number, eventNames: string[]) {
  const filters = await Promise.all(
    eventNames.map((eventName) =>
      client.createContractEventFilter({
        abi: contracts.CryptoPunksGroupRegistry.abi,
        address: GroupRegistryAddr,
        fromBlock: "earliest",
        toBlock: "latest",
        eventName: eventName,
        // @ts-ignore
        args: { groupId },
      })
    )
  );
  const logs = await Promise.all(
    filters.map((filter) => client.getFilterLogs({ filter }))
  );
  return logs;
}

export default client;
