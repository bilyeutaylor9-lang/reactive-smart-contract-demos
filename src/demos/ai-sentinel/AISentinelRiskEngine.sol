// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title AISentinelRiskEngine
/// @notice Scores AI Sentinel risk events and recommends protective actions.
contract AISentinelRiskEngine {
    enum RiskRegime {
        SAFE,
        WATCH,
        WARNING,
        CRITICAL
    }

    enum RecommendedAction {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    struct RiskResult {
        uint256 score;
        RiskRegime regime;
        RecommendedAction action;
        string reason;
    }

    event RiskEvaluated(
        uint256 indexed signalId,
        uint256 score,
        RiskRegime regime,
        RecommendedAction action,
        string reason
    );

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function evaluateAaveRisk(
        uint256 signalId,
        uint256 healthFactor,
        uint256 volatilityScore,
        uint256 liquidityRisk
    ) external onlyOwner returns (RiskResult memory result) {
        uint256 score = _clamp(
            _scoreHealthFactor(healthFactor) + volatilityScore + liquidityRisk
        );

        result = _classify(score, "AAVE liquidation and leverage risk");

        emit RiskEvaluated(signalId, result.score, result.regime, result.action, result.reason);
    }

    function evaluateOracleRisk(
        uint256 signalId,
        uint256 deviationScore,
        uint256 stalePriceScore,
        uint256 manipulationScore
    ) external onlyOwner returns (RiskResult memory result) {
        uint256 score = _clamp(deviationScore + stalePriceScore + manipulationScore);

        result = _classify(score, "Oracle deviation or manipulation risk");

        emit RiskEvaluated(signalId, result.score, result.regime, result.action, result.reason);
    }

    function evaluateWhaleRisk(
        uint256 signalId,
        uint256 transferSizeScore,
        uint256 exchangeInflowScore,
        uint256 concentrationScore
    ) external onlyOwner returns (RiskResult memory result) {
        uint256 score = _clamp(transferSizeScore + exchangeInflowScore + concentrationScore);

        result = _classify(score, "Whale activity and market pressure risk");

        emit RiskEvaluated(signalId, result.score, result.regime, result.action, result.reason);
    }

    function evaluateGenericRisk(
        uint256 signalId,
        uint256 baseRisk,
        uint256 volatilityRisk,
        uint256 protocolRisk
    ) external onlyOwner returns (RiskResult memory result) {
        uint256 score = _clamp(baseRisk + volatilityRisk + protocolRisk);

        result = _classify(score, "Generic AI Sentinel risk");

        emit RiskEvaluated(signalId, result.score, result.regime, result.action, result.reason);
    }

    function _classify(uint256 score, string memory reason) internal pure returns (RiskResult memory) {
        if (score >= 90) {
            return RiskResult(score, RiskRegime.CRITICAL, RecommendedAction.EMERGENCY_PROTECT, reason);
        }

        if (score >= 75) {
            return RiskResult(score, RiskRegime.WARNING, RecommendedAction.REPAY_DEBT, reason);
        }

        if (score >= 50) {
            return RiskResult(score, RiskRegime.WATCH, RecommendedAction.REDUCE_LEVERAGE, reason);
        }

        if (score >= 25) {
            return RiskResult(score, RiskRegime.WATCH, RecommendedAction.MONITOR, reason);
        }

        return RiskResult(score, RiskRegime.SAFE, RecommendedAction.NONE, reason);
    }

    function _scoreHealthFactor(uint256 healthFactor) internal pure returns (uint256) {
        if (healthFactor == type(uint256).max) return 0;
        if (healthFactor <= 1e18) return 70;
        if (healthFactor <= 12e17) return 55;
        if (healthFactor <= 15e17) return 35;
        if (healthFactor <= 2e18) return 20;
        return 5;
    }

    function _clamp(uint256 score) internal pure returns (uint256) {
        return score > 100 ? 100 : score;
    }
}
