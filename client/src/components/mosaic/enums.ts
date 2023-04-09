export const OriginalState = ["Active", "Sold"];

export const MonoLifeCycle = [
  // @dev pre-design, just minted
  "Raw",
  // @dev post-design, valid
  "Active",
  // @dev belonging to invalid/reconstituted Original
  "Dead",
];

export const MonoBidResponse = ["None", "Yes", "No"];

export const BidState = [
  // Initial state, awaiting the result until the bidder explicitly reconstitutes the original or admits failure
  "Proposed",
  // Resulting states upon vote results
  "Accepted",
  "Rejected",
  // Final/terminal states after bidder's action
  "Won",
  "Refunded",
];

export const DistributionStatus = [
  // Mono distribution is active for a given Original
  "Active",
  // All Monos are minted for a given Original
  "Complete",
];

export const ReconstitutionStatus = [
  // No reconstitution attempt is currently in progress
  "None",
  // Some active Bid is ongoing with a governance vote session
  "Active",
  // Bid past its expiry is accepted but is not processed completely
  "Pending",
  // Bid is accepted
  "Complete",
];

export const FinalizationStatus = [
  // No process ongoing; not applicable
  "None",
  // Bid is finalized and the fund must be reclaimed pro rata
  "Active",
  // All remaining funds are reclaimed
  "Complete",
];
