import { createPublicClient, http, formatEther } from "viem";
import { sepolia } from "viem/chains";
import {
  RPC_URL,
  CONTRACTS,
  hyperlaneOriginAbi,
  outcomeTrackerAbi,
  strategyOptimizerAbi,
} from "./contracts.js";

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(RPC_URL),
});

async function readDashboardData() {
  const totalSignals = await publicClient.readContract({
    address: CONTRACTS.hyperlaneOrigin,
    abi: hyperlaneOriginAbi,
    functionName: "totalSignals",
  });

  const criticalSignals = await publicClient.readContract({
    address: CONTRACTS.hyperlaneOrigin,
    abi: hyperlaneOriginAbi,
    functionName: "criticalSignals",
  });

  const totalOutcomes = await publicClient.readContract({
    address: CONTRACTS.outcomeTracker,
    abi: outcomeTrackerAbi,
    functionName: "totalOutcomes",
  });

  const successfulOutcomes = await publicClient.readContract({
    address: CONTRACTS.outcomeTracker,
    abi: outcomeTrackerAbi,
    functionName: "successfulOutcomes",
  });

  const totalValueProtected = await publicClient.readContract({
    address: CONTRACTS.outcomeTracker,
    abi: outcomeTrackerAbi,
    functionName: "totalValueProtected",
  });

  const successRateBps = await publicClient.readContract({
    address: CONTRACTS.outcomeTracker,
    abi: outcomeTrackerAbi,
    functionName: "getSuccessRateBps",
  });

  document.getElementById("totalSignals").textContent = totalSignals.toString();
  document.getElementById("criticalAlerts").textContent = criticalSignals.toString();
  document.getElementById("executions").textContent = totalOutcomes.toString();
  document.getElementById("successRate").textContent = `${Number(successRateBps) / 100}%`;
  document.getElementById("valueProtected").textContent = `$${formatEther(totalValueProtected)}`;
}

readDashboardData().catch((error) => {
  console.error(error);
});
