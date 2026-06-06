// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AISentinelReactive {

    event RiskEvaluated(
        uint256 riskScore,
        string action
    );

    function evaluateRisk(
        uint256 riskScore
    ) external returns (string memory) {

        string memory action;

        if (riskScore >= 90) {
            action = "EMERGENCY_PROTECTION";
        }
        else if (riskScore >= 75) {
            action = "REPAY_DEBT";
        }
        else if (riskScore >= 60) {
            action = "ADD_COLLATERAL";
        }
        else if (riskScore >= 40) {
            action = "ALERT";
        }
        else {
            action = "NO_ACTION";
        }

        emit RiskEvaluated(
            riskScore,
            action
        );

        return action;
    }
}