export const RPC_URL = "https://sepolia.infura.io/v3/YOUR_KEY";

export const CONTRACTS = {
  hyperlaneOrigin: "0x0000000000000000000000000000000000000000",
  outcomeTracker: "0x0000000000000000000000000000000000000000",
  strategyOptimizer: "0x0000000000000000000000000000000000000000",
};

export const hyperlaneOriginAbi = [
  {
    inputs: [],
    name: "totalSignals",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "criticalSignals",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];

export const outcomeTrackerAbi = [
  {
    inputs: [],
    name: "totalOutcomes",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "successfulOutcomes",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalValueProtected",
    outputs: [{ type: "int256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getSuccessRateBps",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];

export const strategyOptimizerAbi = [
  {
    inputs: [{ type: "uint8" }],
    name: "getActionConfidence",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];
