// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title OutcomeTracker
/// @notice Tracks AI Sentinel actions and whether protective actions succeeded.
contract OutcomeTracker {
    enum ActionType {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    struct Outcome {
        uint256 signalId;
        uint256 riskScore;
        ActionType actionTaken;
        bool executed;
        bool successful;
        int256 valueProtected;
        uint256 timestamp;
        string notes;
    }

    event OutcomeRecorded(
        uint256 indexed signalId,
        uint256 riskScore,
        ActionType actionTaken,
        bool executed,
        bool successful,
        int256 valueProtected,
        string notes
    );

    address public owner;
    uint256 public totalOutcomes;
    uint256 public successfulOutcomes;
    int256 public totalValueProtected;

    mapping(uint256 => Outcome) public outcomes;
    mapping(uint256 => bool) public hasOutcome;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function recordOutcome(
        uint256 signalId,
        uint256 riskScore,
        ActionType actionTaken,
        bool executed,
        bool successful,
        int256 valueProtected,
        string calldata notes
    ) external onlyOwner {
        require(!hasOutcome[signalId], "Outcome already recorded");
        require(riskScore <= 100, "Invalid risk score");

        outcomes[signalId] = Outcome({
            signalId: signalId,
            riskScore: riskScore,
            actionTaken: actionTaken,
            executed: executed,
            successful: successful,
            valueProtected: valueProtected,
            timestamp: block.timestamp,
            notes: notes
        });

        hasOutcome[signalId] = true;
        totalOutcomes++;

        if (successful) {
            successfulOutcomes++;
        }

        totalValueProtected += valueProtected;

        emit OutcomeRecorded(signalId, riskScore, actionTaken, executed, successful, valueProtected, notes);
    }

    function getSuccessRateBps() external view returns (uint256) {
        if (totalOutcomes == 0) return 0;
        return (successfulOutcomes * 10_000) / totalOutcomes;
    }

    function getOutcome(uint256 signalId) external view returns (Outcome memory) {
        require(hasOutcome[signalId], "Outcome does not exist");
        return outcomes[signalId];
    }
}
