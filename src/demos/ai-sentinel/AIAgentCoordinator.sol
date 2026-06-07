// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title AIAgentCoordinator
/// @notice Coordinates AI Sentinel alerts from Aave, whale, and oracle modules into unified decisions.
contract AIAgentCoordinator {
    enum AlertSource {
        UNKNOWN,
        AAVE,
        WHALE,
        ORACLE,
        GOVERNANCE,
        PORTFOLIO
    }

    enum AgentDecision {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    enum DecisionStatus {
        PENDING,
        APPROVED,
        EXECUTED,
        FAILED
    }

    struct CoordinatedDecision {
        uint256 decisionId;
        AlertSource source;
        uint256 sourceAlertId;
        uint256 riskScore;
        AgentDecision decision;
        DecisionStatus status;
        address target;
        bytes payload;
        uint256 timestamp;
        string reason;
    }

    event DecisionCreated(
        uint256 indexed decisionId,
        AlertSource indexed source,
        uint256 indexed sourceAlertId,
        uint256 riskScore,
        AgentDecision decision,
        DecisionStatus status,
        address target,
        string reason
    );

    event DecisionStatusUpdated(uint256 indexed decisionId, DecisionStatus oldStatus, DecisionStatus newStatus);

    address public owner;
    uint256 public totalDecisions;

    mapping(uint256 => CoordinatedDecision) public decisions;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function coordinateAaveAlert(
        uint256 sourceAlertId,
        uint256 healthFactor,
        uint256 riskScore,
        address target,
        bytes calldata payload
    ) external onlyOwner returns (uint256 decisionId) {
        require(target != address(0), "Invalid target");
        require(riskScore <= 100, "Invalid risk score");

        AgentDecision decision = _decideAaveAction(healthFactor, riskScore);

        decisionId = _createDecision(
            AlertSource.AAVE,
            sourceAlertId,
            riskScore,
            decision,
            target,
            payload,
            "Aave health factor and liquidation-risk decision"
        );
    }

    function coordinateWhaleAlert(
        uint256 sourceAlertId,
        uint256 riskScore,
        address target,
        bytes calldata payload
    ) external onlyOwner returns (uint256 decisionId) {
        require(target != address(0), "Invalid target");
        require(riskScore <= 100, "Invalid risk score");

        AgentDecision decision = _decideWhaleAction(riskScore);

        decisionId =
            _createDecision(AlertSource.WHALE, sourceAlertId, riskScore, decision, target, payload, "Whale flow risk decision");
    }

    function coordinateOracleAlert(
        uint256 sourceAlertId,
        uint256 riskScore,
        address target,
        bytes calldata payload
    ) external onlyOwner returns (uint256 decisionId) {
        require(target != address(0), "Invalid target");
        require(riskScore <= 100, "Invalid risk score");

        AgentDecision decision = _decideOracleAction(riskScore);

        decisionId = _createDecision(
            AlertSource.ORACLE, sourceAlertId, riskScore, decision, target, payload, "Oracle deviation and stale-price decision"
        );
    }

    function approveDecision(uint256 decisionId) external onlyOwner {
        require(decisionId < totalDecisions, "Decision does not exist");

        DecisionStatus oldStatus = decisions[decisionId].status;
        require(oldStatus == DecisionStatus.PENDING, "Decision not pending");

        decisions[decisionId].status = DecisionStatus.APPROVED;

        emit DecisionStatusUpdated(decisionId, oldStatus, DecisionStatus.APPROVED);
    }

    function markExecuted(uint256 decisionId) external onlyOwner {
        require(decisionId < totalDecisions, "Decision does not exist");

        DecisionStatus oldStatus = decisions[decisionId].status;
        require(oldStatus == DecisionStatus.APPROVED, "Decision not approved");

        decisions[decisionId].status = DecisionStatus.EXECUTED;

        emit DecisionStatusUpdated(decisionId, oldStatus, DecisionStatus.EXECUTED);
    }

    function markFailed(uint256 decisionId) external onlyOwner {
        require(decisionId < totalDecisions, "Decision does not exist");

        DecisionStatus oldStatus = decisions[decisionId].status;
        require(oldStatus == DecisionStatus.APPROVED || oldStatus == DecisionStatus.PENDING, "Invalid status");

        decisions[decisionId].status = DecisionStatus.FAILED;

        emit DecisionStatusUpdated(decisionId, oldStatus, DecisionStatus.FAILED);
    }

    function getDecision(uint256 decisionId) external view returns (CoordinatedDecision memory) {
        require(decisionId < totalDecisions, "Decision does not exist");
        return decisions[decisionId];
    }

    function _createDecision(
        AlertSource source,
        uint256 sourceAlertId,
        uint256 riskScore,
        AgentDecision decision,
        address target,
        bytes calldata payload,
        string memory reason
    ) internal returns (uint256 decisionId) {
        decisionId = totalDecisions;

        decisions[decisionId] = CoordinatedDecision({
            decisionId: decisionId,
            source: source,
            sourceAlertId: sourceAlertId,
            riskScore: riskScore,
            decision: decision,
            status: DecisionStatus.PENDING,
            target: target,
            payload: payload,
            timestamp: block.timestamp,
            reason: reason
        });

        totalDecisions++;

        emit DecisionCreated(decisionId, source, sourceAlertId, riskScore, decision, DecisionStatus.PENDING, target, reason);
    }

    function _decideAaveAction(uint256 healthFactor, uint256 riskScore) internal pure returns (AgentDecision) {
        if (riskScore >= 95 || healthFactor <= 12e17) {
            return AgentDecision.EMERGENCY_PROTECT;
        }

        if (riskScore >= 80 || healthFactor <= 15e17) {
            return AgentDecision.REPAY_DEBT;
        }

        if (riskScore >= 60 || healthFactor <= 2e18) {
            return AgentDecision.REDUCE_LEVERAGE;
        }

        if (riskScore >= 30) {
            return AgentDecision.MONITOR;
        }

        return AgentDecision.NONE;
    }

    function _decideWhaleAction(uint256 riskScore) internal pure returns (AgentDecision) {
        if (riskScore >= 90) {
            return AgentDecision.EMERGENCY_PROTECT;
        }

        if (riskScore >= 75) {
            return AgentDecision.REDUCE_LEVERAGE;
        }

        if (riskScore >= 50) {
            return AgentDecision.MONITOR;
        }

        return AgentDecision.NONE;
    }

    function _decideOracleAction(uint256 riskScore) internal pure returns (AgentDecision) {
        if (riskScore >= 90) {
            return AgentDecision.EMERGENCY_PROTECT;
        }

        if (riskScore >= 70) {
            return AgentDecision.PAUSE_AUTOMATION;
        }

        if (riskScore >= 40) {
            return AgentDecision.MONITOR;
        }

        return AgentDecision.NONE;
    }
}
