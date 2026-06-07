const signals = [
  {
    id: 1,
    source: "AaveGuardian",
    type: "AAVE_RISK",
    risk: 95,
    status: "CRITICAL",
    action: "EMERGENCY_PROTECT",
  },
  {
    id: 2,
    source: "OracleGuardian",
    type: "ORACLE_RISK",
    risk: 88,
    status: "WARNING",
    action: "PAUSE_AUTOMATION",
  },
  {
    id: 3,
    source: "WhaleDetector",
    type: "WHALE_ACTIVITY",
    risk: 82,
    status: "WARNING",
    action: "REDUCE_LEVERAGE",
  },
];

const executions = [
  {
    id: 1,
    chain: "Base Sepolia",
    action: "REPAY_DEBT",
    status: "Executed",
    message: "0x7a91...e22f",
  },
  {
    id: 2,
    chain: "Sepolia",
    action: "PAUSE_AUTOMATION",
    status: "Pending",
    message: "0x31bc...8a10",
  },
];

const outcomes = [
  {
    signalId: 1,
    action: "REPAY_DEBT",
    success: true,
    value: "$125,000",
  },
  {
    signalId: 2,
    action: "PAUSE_AUTOMATION",
    success: true,
    value: "$72,500",
  },
];

const learning = [
  {
    action: "REPAY_DEBT",
    confidence: 92,
  },
  {
    action: "EMERGENCY_PROTECT",
    confidence: 89,
  },
  {
    action: "REDUCE_LEVERAGE",
    confidence: 76,
  },
];

document.getElementById("totalSignals").textContent = signals.length;
document.getElementById("criticalAlerts").textContent = signals.filter(
  (s) => s.status === "CRITICAL"
).length;
document.getElementById("executions").textContent = executions.length;
document.getElementById("successRate").textContent = "100%";
document.getElementById("valueProtected").textContent = "$197,500";

function badge(status) {
  const css =
    status === "CRITICAL"
      ? "critical"
      : status === "WARNING"
      ? "warning"
      : "safe";

  return `<span class="badge ${css}">${status}</span>`;
}

document.getElementById("signalsTable").innerHTML = `
<table class="table">
  <thead>
    <tr>
      <th>ID</th>
      <th>Source</th>
      <th>Type</th>
      <th>Risk</th>
      <th>Status</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    ${signals
      .map(
        (s) => `
      <tr>
        <td>${s.id}</td>
        <td>${s.source}</td>
        <td>${s.type}</td>
        <td>${s.risk}</td>
        <td>${badge(s.status)}</td>
        <td>${s.action}</td>
      </tr>
    `
      )
      .join("")}
  </tbody>
</table>
`;

document.getElementById("executionsTable").innerHTML = `
<table class="table">
  <thead>
    <tr>
      <th>ID</th>
      <th>Chain</th>
      <th>Action</th>
      <th>Status</th>
      <th>Message</th>
    </tr>
  </thead>
  <tbody>
    ${executions
      .map(
        (e) => `
      <tr>
        <td>${e.id}</td>
        <td>${e.chain}</td>
        <td>${e.action}</td>
        <td>${e.status}</td>
        <td>${e.message}</td>
      </tr>
    `
      )
      .join("")}
  </tbody>
</table>
`;

document.getElementById("outcomesTable").innerHTML = `
<table class="table">
  <thead>
    <tr>
      <th>Signal</th>
      <th>Action</th>
      <th>Success</th>
      <th>Value Protected</th>
    </tr>
  </thead>
  <tbody>
    ${outcomes
      .map(
        (o) => `
      <tr>
        <td>${o.signalId}</td>
        <td>${o.action}</td>
        <td>${o.success ? "Yes" : "No"}</td>
        <td>${o.value}</td>
      </tr>
    `
      )
      .join("")}
  </tbody>
</table>
`;

document.getElementById("learningGrid").innerHTML = learning
  .map(
    (l) => `
  <div class="learning-card">
    <h4>${l.action}</h4>
    <p>Confidence: ${l.confidence}%</p>
    <div class="progress">
      <div style="width:${l.confidence}%"></div>
    </div>
  </div>
`
  )
  .join("");
