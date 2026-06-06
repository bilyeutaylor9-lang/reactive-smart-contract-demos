// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AISentinelOrigin {

    event IntelligenceSignal(
        uint256 signalId,
        uint256 riskScore,
        uint256 opportunityScore,
        string action
    );

    uint256 public nextSignalId;

    function submitSignal(
        uint256 riskScore,
        uint256 opportunityScore,
        string calldata action
    ) external {

        emit IntelligenceSignal(
            nextSignalId,
            riskScore,
            opportunityScore,
            action
        );

        nextSignalId++;
    }
}