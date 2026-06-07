// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title OracleGuardian
/// @notice Detects oracle deviation, stale price data, and manipulation risk.
contract OracleGuardian {
    enum OracleStatus {
        SAFE,
        WATCH,
        WARNING,
        CRITICAL
    }

    struct OracleAlert {
        address oracle;
        address asset;
        uint256 reportedPrice;
        uint256 referencePrice;
        uint256 deviationBps;
        uint256 staleSeconds;
        uint256 riskScore;
        OracleStatus status;
        uint256 timestamp;
    }

    event OracleAlertCreated(
        uint256 indexed alertId,
        address indexed oracle,
        address indexed asset,
        uint256 reportedPrice,
        uint256 referencePrice,
        uint256 deviationBps,
        uint256 staleSeconds,
        uint256 riskScore,
        OracleStatus status
    );

    address public owner;
    uint256 public totalAlerts;

    uint256 public warningDeviationBps = 500; // 5%
    uint256 public criticalDeviationBps = 1_500; // 15%
    uint256 public staleThresholdSeconds = 1 hours;
    uint256 public criticalStaleSeconds = 6 hours;

    mapping(uint256 => OracleAlert) public alerts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function updateThresholds(
        uint256 _warningDeviationBps,
        uint256 _criticalDeviationBps,
        uint256 _staleThresholdSeconds,
        uint256 _criticalStaleSeconds
    ) external onlyOwner {
        require(_warningDeviationBps < _criticalDeviationBps, "Invalid deviation thresholds");
        require(_staleThresholdSeconds < _criticalStaleSeconds, "Invalid stale thresholds");

        warningDeviationBps = _warningDeviationBps;
        criticalDeviationBps = _criticalDeviationBps;
        staleThresholdSeconds = _staleThresholdSeconds;
        criticalStaleSeconds = _criticalStaleSeconds;
    }

    function reportOracleData(
        address oracle,
        address asset,
        uint256 reportedPrice,
        uint256 referencePrice,
        uint256 lastUpdatedAt
    ) external onlyOwner returns (uint256 alertId) {
        require(oracle != address(0), "Invalid oracle");
        require(asset != address(0), "Invalid asset");
        require(reportedPrice > 0, "Invalid reported price");
        require(referencePrice > 0, "Invalid reference price");
        require(lastUpdatedAt <= block.timestamp, "Invalid update time");

        uint256 deviationBps = _calculateDeviationBps(reportedPrice, referencePrice);
        uint256 staleSeconds = block.timestamp - lastUpdatedAt;
        uint256 riskScore = _scoreOracleRisk(deviationBps, staleSeconds);
        OracleStatus status = _classifyStatus(riskScore);

        alertId = totalAlerts;

        alerts[alertId] = OracleAlert({
            oracle: oracle,
            asset: asset,
            reportedPrice: reportedPrice,
            referencePrice: referencePrice,
            deviationBps: deviationBps,
            staleSeconds: staleSeconds,
            riskScore: riskScore,
            status: status,
            timestamp: block.timestamp
        });

        totalAlerts++;

        emit OracleAlertCreated(
            alertId,
            oracle,
            asset,
            reportedPrice,
            referencePrice,
            deviationBps,
            staleSeconds,
            riskScore,
            status
        );
    }

    function getAlert(uint256 alertId) external view returns (OracleAlert memory) {
        require(alertId < totalAlerts, "Alert does not exist");
        return alerts[alertId];
    }

    function _calculateDeviationBps(uint256 reportedPrice, uint256 referencePrice) internal pure returns (uint256) {
        if (reportedPrice >= referencePrice) {
            return ((reportedPrice - referencePrice) * 10_000) / referencePrice;
        }

        return ((referencePrice - reportedPrice) * 10_000) / referencePrice;
    }

    function _scoreOracleRisk(uint256 deviationBps, uint256 staleSeconds) internal view returns (uint256) {
        uint256 score;

        if (deviationBps >= criticalDeviationBps) {
            score += 70;
        } else if (deviationBps >= warningDeviationBps) {
            score += 40;
        } else if (deviationBps > 0) {
            score += 10;
        }

        if (staleSeconds >= criticalStaleSeconds) {
            score += 30;
        } else if (staleSeconds >= staleThresholdSeconds) {
            score += 20;
        }

        return score > 100 ? 100 : score;
    }

    function _classifyStatus(uint256 riskScore) internal pure returns (OracleStatus) {
        if (riskScore >= 90) return OracleStatus.CRITICAL;
        if (riskScore >= 70) return OracleStatus.WARNING;
        if (riskScore >= 30) return OracleStatus.WATCH;
        return OracleStatus.SAFE;
    }
}
