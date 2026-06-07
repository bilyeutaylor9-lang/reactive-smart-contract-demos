// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title WhaleDetector
/// @notice Detects large wallet movements and emits AI Sentinel whale-risk alerts.
contract WhaleDetector {
    enum WhaleDirection {
        UNKNOWN,
        INFLOW,
        OUTFLOW,
        WALLET_TO_WALLET
    }

    struct WhaleAlert {
        address token;
        address from;
        address to;
        uint256 amount;
        uint256 usdValue;
        uint256 riskScore;
        WhaleDirection direction;
        uint256 timestamp;
    }

    event WhaleAlertCreated(
        uint256 indexed alertId,
        address indexed token,
        address indexed from,
        address to,
        uint256 amount,
        uint256 usdValue,
        uint256 riskScore,
        WhaleDirection direction
    );

    address public owner;
    uint256 public totalAlerts;
    uint256 public whaleThresholdUsd = 1_000_000e18;

    mapping(uint256 => WhaleAlert) public alerts;
    mapping(address => bool) public knownExchangeWallet;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setWhaleThresholdUsd(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Invalid threshold");
        whaleThresholdUsd = newThreshold;
    }

    function setExchangeWallet(address wallet, bool isExchange) external onlyOwner {
        require(wallet != address(0), "Invalid wallet");
        knownExchangeWallet[wallet] = isExchange;
    }

    function reportTransfer(address token, address from, address to, uint256 amount, uint256 usdValue)
        external
        onlyOwner
        returns (uint256 alertId)
    {
        require(token != address(0), "Invalid token");
        require(from != address(0), "Invalid from");
        require(to != address(0), "Invalid to");

        if (usdValue < whaleThresholdUsd) {
            return type(uint256).max;
        }

        WhaleDirection direction = _classifyDirection(from, to);
        uint256 riskScore = _scoreWhaleRisk(usdValue, direction);

        alertId = totalAlerts;

        alerts[alertId] = WhaleAlert({
            token: token,
            from: from,
            to: to,
            amount: amount,
            usdValue: usdValue,
            riskScore: riskScore,
            direction: direction,
            timestamp: block.timestamp
        });

        totalAlerts++;

        emit WhaleAlertCreated(alertId, token, from, to, amount, usdValue, riskScore, direction);
    }

    function getAlert(uint256 alertId) external view returns (WhaleAlert memory) {
        require(alertId < totalAlerts, "Alert does not exist");
        return alerts[alertId];
    }

    function _classifyDirection(address from, address to) internal view returns (WhaleDirection) {
        if (knownExchangeWallet[to]) {
            return WhaleDirection.INFLOW;
        }

        if (knownExchangeWallet[from]) {
            return WhaleDirection.OUTFLOW;
        }

        return WhaleDirection.WALLET_TO_WALLET;
    }

    function _scoreWhaleRisk(uint256 usdValue, WhaleDirection direction) internal pure returns (uint256) {
        uint256 score;

        if (usdValue >= 25_000_000e18) {
            score = 90;
        } else if (usdValue >= 10_000_000e18) {
            score = 80;
        } else if (usdValue >= 5_000_000e18) {
            score = 70;
        } else if (usdValue >= 1_000_000e18) {
            score = 55;
        }

        if (direction == WhaleDirection.INFLOW) {
            score += 10;
        }

        return score > 100 ? 100 : score;
    }
}
