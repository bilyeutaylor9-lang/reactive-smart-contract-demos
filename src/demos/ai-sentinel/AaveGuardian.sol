// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title AaveGuardian
/// @notice Monitors Aave positions and produces AI Sentinel risk alerts.
contract AaveGuardian {
    enum PositionStatus {
        SAFE,
        WATCH,
        WARNING,
        CRITICAL
    }

    struct PositionAlert {
        address user;
        uint256 healthFactor;
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 riskScore;
        PositionStatus status;
        uint256 timestamp;
    }

    event PositionRiskDetected(
        uint256 indexed alertId,
        address indexed user,
        uint256 healthFactor,
        uint256 riskScore,
        PositionStatus status
    );

    address public owner;
    uint256 public totalAlerts;

    uint256 public watchHealthFactor = 2e18;
    uint256 public warningHealthFactor = 15e17;
    uint256 public criticalHealthFactor = 12e17;

    mapping(uint256 => PositionAlert) public alerts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function updateThresholds(
        uint256 _watch,
        uint256 _warning,
        uint256 _critical
    ) external onlyOwner {
        require(_watch > _warning, "Invalid watch");
        require(_warning > _critical, "Invalid warning");

        watchHealthFactor = _watch;
        warningHealthFactor = _warning;
        criticalHealthFactor = _critical;
    }

    function evaluatePosition(
        address user,
        uint256 healthFactor,
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase
    ) external onlyOwner returns (uint256 alertId) {
        require(user != address(0), "Invalid user");

        uint256 riskScore = _scoreHealthFactor(healthFactor);
        PositionStatus status = _classify(healthFactor);

        alertId = totalAlerts;

        alerts[alertId] = PositionAlert({
            user: user,
            healthFactor: healthFactor,
            totalCollateralBase: totalCollateralBase,
            totalDebtBase: totalDebtBase,
            availableBorrowsBase: availableBorrowsBase,
            riskScore: riskScore,
            status: status,
            timestamp: block.timestamp
        });

        totalAlerts++;

        emit PositionRiskDetected(
            alertId,
            user,
            healthFactor,
            riskScore,
            status
        );
    }

    function getAlert(
        uint256 alertId
    ) external view returns (PositionAlert memory) {
        require(alertId < totalAlerts, "Alert does not exist");
        return alerts[alertId];
    }

    function _scoreHealthFactor(
        uint256 healthFactor
    ) internal view returns (uint256) {
        if (healthFactor <= criticalHealthFactor) {
            return 95;
        }

        if (healthFactor <= warningHealthFactor) {
            return 75;
        }

        if (healthFactor <= watchHealthFactor) {
            return 50;
        }

        return 10;
    }

    function _classify(
        uint256 healthFactor
    ) internal view returns (PositionStatus) {
        if (healthFactor <= criticalHealthFactor) {
            return PositionStatus.CRITICAL;
        }

        if (healthFactor <= warningHealthFactor) {
            return PositionStatus.WARNING;
        }

        if (healthFactor <= watchHealthFactor) {
            return PositionStatus.WATCH;
        }

        return PositionStatus.SAFE;
    }
}
