# Architecture

## Core Flow

```text
Origin Chain Event
      ↓
Reactive Event Subscription
      ↓
AI Risk / Opportunity Scoring
      ↓
Reactive Contract Decision
      ↓
Callback Proxy / Message Relay
      ↓
Destination Contract Action
```

## Main Modules

### 1. Origin Event Layer
Detects events from contracts such as:

- Uniswap V2/V3 pairs
- Aave lending positions
- ERC20 transfers
- Governance contracts
- NFT contracts
- Whale wallets

### 2. AI Scoring Layer
Scores each event from 0-100 using:

- Volatility
- Price movement
- Liquidity movement
- Wallet behavior
- Health factor
- Time of event
- Chain conditions

### 3. Reactive Decision Layer
A Reactive-style contract determines whether the AI score passes the automation threshold.

### 4. Callback Execution Layer
Executes the target action:

- Stop-loss
- Take-profit
- Repay debt
- Add collateral
- Send alert
- Rebalance
- Execute governance action

## MVP Scope

The first version uses mock AI scoring and simplified callback logic. Future versions should integrate official Reactive Network contracts, callback proxy addresses, and real cross-chain execution.
