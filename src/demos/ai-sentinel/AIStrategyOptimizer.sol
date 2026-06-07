// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title AIStrategyOptimizer
/// @notice Learns from AI Sentinel outcomes and tracks action performance.
contract AIStrategyOptimizer {
    enum ActionType {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    struct ActionStats {
        uint256 totalAttempts;
        uint256 successfulAttempts;
        int256 netValueProtected;
        uint256 confidenceBps;
        uint256 lastUpdated;
    }

    struct LearningRecord {
        uint256 signalId;
        ActionType actionType;
        uint256 riskScore;
        bool successful;
        int256 valueProtected;
        uint256 timestamp;
    }

    event LearningRecorded(
        uint256 indexed recordId,
        uint256 indexed signalId,
        ActionType indexed actionType,
        uint256 riskScore,
        bool successful,
        int256 valueProtected,
        uint256 confidenceBps
    );

    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

    address public owner;
    uint256 public totalRecords;

    mapping(ActionType => ActionStats) public actionStats;
    mapping(uint256 => LearningRecord) public learningRecords;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function recordLearning(
        uint256 signalId,
        ActionType actionType,
        uint256 riskScore,
        bool successful,
        int256 valueProtected
    ) external onlyOwner returns (uint256 recordId) {
        require(actionType != ActionType.NONE, "Invalid action");
        require(riskScore <= 100, "Invalid risk score");

        recordId = totalRecords;

        learningRecords[recordId] = LearningRecord({
            signalId: signalId,
            actionType: actionType,
            riskScore: riskScore,
            successful: successful,
            valueProtected: valueProtected,
            timestamp: block.timestamp
        });

        totalRecords++;

        ActionStats storage stats = actionStats[actionType];

        stats.totalAttempts++;

        if (successful) {
            stats.successfulAttempts++;
        }

        stats.netValueProtected += valueProtected;
        stats.confidenceBps = _calculateConfidence(stats.successfulAttempts, stats.totalAttempts);
        stats.lastUpdated = block.timestamp;

        emit LearningRecorded(
            recordId,
            signalId,
            actionType,
            riskScore,
            successful,
            valueProtected,
            stats.confidenceBps
        );
    }

    function getActionConfidence(ActionType actionType) external view returns (uint256) {
        return actionStats[actionType].confidenceBps;
    }

    function getSuccessRateBps(ActionType actionType) external view returns (uint256) {
        ActionStats memory stats = actionStats[actionType];

        if (stats.totalAttempts == 0) {
            return 0;
        }

        return (stats.successfulAttempts * 10_000) / stats.totalAttempts;
    }

    function getBestAction(
        ActionType first,
        ActionType second
    ) external view returns (ActionType) {
        uint256 firstConfidence = actionStats[first].confidenceBps;
        uint256 secondConfidence = actionStats[second].confidenceBps;

        if (firstConfidence >= secondConfidence) {
            return first;
        }

        return second;
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnerUpdated(oldOwner, newOwner);
    }

    function _calculateConfidence(
        uint256 successfulAttempts,
        uint256 totalAttempts
    ) internal pure returns (uint256) {
        if (totalAttempts == 0) {
            return 0;
        }

        return (successfulAttempts * 10_000) / totalAttempts;
    }
}
