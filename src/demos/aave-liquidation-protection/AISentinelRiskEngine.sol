// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AISentinelRiskEngine {
    function calculateRiskScore(
        uint256 healthFactor,
        uint256 volatilityScore,
        uint256 debtRatio,
        uint256 liquidityScore
    ) public pure returns (uint256) {
        uint256 score = 0;

        if (healthFactor < 1100000000000000000) score += 50;
        else if (healthFactor < 1250000000000000000) score += 35;
        else if (healthFactor < 1500000000000000000) score += 20;

        score += volatilityScore;
        score += debtRatio;
        score += liquidityScore;

        if (score > 100) return 100;
        return score;
    }

    function getRecommendedAction(uint256 riskScore) public pure returns (string memory) {
        if (riskScore >= 90) return "EMERGENCY_BOTH";
        if (riskScore >= 75) return "REPAY_DEBT";
        if (riskScore >= 60) return "ADD_COLLATERAL";
        if (riskScore >= 40) return "ALERT_ONLY";
        return "NO_ACTION";
    }
}