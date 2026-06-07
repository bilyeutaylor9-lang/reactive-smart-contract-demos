// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IAISentinelRiskEngine {
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

    function evaluateGenericRisk(
        uint256 signalId,
        uint256 baseRisk,
        uint256 volatilityRisk,
        uint256 protocolRisk
    ) external returns (RiskResult memory result);
}

interface IHyperlaneCrossChainExecutor {
    enum ActionType {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    function requestCrossChainExecution(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 signalId,
        ActionType actionType,
        uint256 riskScore,
        address target,
        bytes calldata payload
    ) external payable returns (bytes32 messageId);
}

/// @title AISentinelHyperlaneOrigin
/// @notice Origin-side contract for AI Sentinel risk signals and cross-chain execution.
contract HyperlaneOrigin {
    enum SignalType {
        GENERIC,
        AAVE_RISK,
        UNISWAP_RISK,
        WHALE_ACTIVITY,
        ORACLE_RISK,
        GOVERNANCE_RISK,
        PORTFOLIO_REBALANCE,
        EMERGENCY_PROTECTION
    }

    enum Urgency {
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    struct IntelligenceSignal {
        SignalType signalType;
        Urgency urgency;
        uint256 riskScore;
        uint256 opportunityScore;
        uint256 timestamp;
        address source;
        bytes payload;
    }

    event Trigger(bytes message);

    event IntelligenceTriggered(
        SignalType indexed signalType,
        Urgency indexed urgency,
        uint256 riskScore,
        uint256 opportunityScore,
        address indexed source,
        bytes payload
    );

    event AiExecutionTriggered(
        uint256 indexed signalId,
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 riskScore,
        IHyperlaneCrossChainExecutor.ActionType actionType,
        address target
    );

    event Received(uint32 indexed chain_id, address indexed sender, bytes message);

    address public owner;
    address public mailbox;

    IAISentinelRiskEngine public riskEngine;
    IHyperlaneCrossChainExecutor public crossChainExecutor;

    uint256 public totalSignals;
    uint256 public criticalSignals;

    mapping(uint256 => IntelligenceSignal) public signals;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyMailbox() {
        require(msg.sender == mailbox, "Not authorized");
        _;
    }

    constructor(address _mailbox) {
        owner = msg.sender;
        mailbox = _mailbox;
    }

    function setRiskEngine(address _riskEngine) external onlyOwner {
        require(_riskEngine != address(0), "Invalid risk engine");
        riskEngine = IAISentinelRiskEngine(_riskEngine);
    }

    function setCrossChainExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Invalid executor");
        crossChainExecutor = IHyperlaneCrossChainExecutor(_executor);
    }

    function trigger(bytes calldata message) external onlyOwner {
        emit Trigger(message);
    }

    function triggerIntelligenceSignal(
        SignalType signalType,
        Urgency urgency,
        uint256 riskScore,
        uint256 opportunityScore,
        bytes memory payload
    ) public onlyOwner returns (uint256) {
        require(riskScore <= 100, "Invalid risk score");
        require(opportunityScore <= 100, "Invalid opportunity score");

        uint256 signalId = totalSignals;

        signals[signalId] = IntelligenceSignal({
            signalType: signalType,
            urgency: urgency,
            riskScore: riskScore,
            opportunityScore: opportunityScore,
            timestamp: block.timestamp,
            source: msg.sender,
            payload: payload
        });

        totalSignals++;

        if (urgency == Urgency.CRITICAL || riskScore >= 90) {
            criticalSignals++;
        }

        bytes memory encodedMessage =
            abi.encode(signalId, signalType, urgency, riskScore, opportunityScore, block.timestamp, msg.sender, payload);

        emit IntelligenceTriggered(signalType, urgency, riskScore, opportunityScore, msg.sender, payload);
        emit Trigger(encodedMessage);

        return signalId;
    }

    function triggerAiRecommendedExecution(
        SignalType signalType,
        uint256 baseRisk,
        uint256 volatilityRisk,
        uint256 protocolRisk,
        uint32 destinationDomain,
        bytes32 recipientAddress,
        address target,
        bytes calldata payload
    ) external payable onlyOwner returns (uint256 signalId, bytes32 messageId) {
        require(address(riskEngine) != address(0), "Risk engine not set");
        require(address(crossChainExecutor) != address(0), "Executor not set");

        IAISentinelRiskEngine.RiskResult memory result =
            riskEngine.evaluateGenericRisk(totalSignals, baseRisk, volatilityRisk, protocolRisk);

        Urgency urgency = _convertRegimeToUrgency(result.regime);

        signalId = triggerIntelligenceSignal(signalType, urgency, result.score, 0, payload);

        IHyperlaneCrossChainExecutor.ActionType actionType = _convertAction(result.action);

        messageId = crossChainExecutor.requestCrossChainExecution{value: msg.value}(
            destinationDomain,
            recipientAddress,
            signalId,
            actionType,
            result.score,
            target,
            payload
        );

        emit AiExecutionTriggered(signalId, messageId, destinationDomain, result.score, actionType, target);
    }

    function triggerAaveRiskSignal(uint256 healthFactor, uint256 riskScore, bytes calldata payload)
        external
        onlyOwner
        returns (uint256)
    {
        Urgency urgency = _classifyUrgency(riskScore);
        bytes memory enrichedPayload = abi.encode("AAVE_RISK", healthFactor, payload);

        return triggerIntelligenceSignal(SignalType.AAVE_RISK, urgency, riskScore, 0, enrichedPayload);
    }

    function triggerWhaleSignal(address whaleWallet, uint256 transferValue, uint256 riskScore, bytes calldata payload)
        external
        onlyOwner
        returns (uint256)
    {
        Urgency urgency = _classifyUrgency(riskScore);
        bytes memory enrichedPayload = abi.encode("WHALE_ACTIVITY", whaleWallet, transferValue, payload);

        return triggerIntelligenceSignal(SignalType.WHALE_ACTIVITY, urgency, riskScore, 0, enrichedPayload);
    }

    function triggerOracleRiskSignal(address oracle, uint256 deviationScore, bytes calldata payload)
        external
        onlyOwner
        returns (uint256)
    {
        Urgency urgency = _classifyUrgency(deviationScore);
        bytes memory enrichedPayload = abi.encode("ORACLE_RISK", oracle, deviationScore, payload);

        return triggerIntelligenceSignal(SignalType.ORACLE_RISK, urgency, deviationScore, 0, enrichedPayload);
    }

    function handle(uint32 chain_id, bytes32 sender, bytes calldata message) external payable onlyMailbox {
        emit Received(chain_id, address(uint160(uint256(sender))), message);
    }

    function getSignal(uint256 signalId) external view returns (IntelligenceSignal memory) {
        require(signalId < totalSignals, "Signal does not exist");
        return signals[signalId];
    }

    function _classifyUrgency(uint256 riskScore) internal pure returns (Urgency) {
        if (riskScore >= 90) return Urgency.CRITICAL;
        if (riskScore >= 75) return Urgency.HIGH;
        if (riskScore >= 50) return Urgency.MEDIUM;
        return Urgency.LOW;
    }

    function _convertRegimeToUrgency(IAISentinelRiskEngine.RiskRegime regime) internal pure returns (Urgency) {
        if (regime == IAISentinelRiskEngine.RiskRegime.CRITICAL) return Urgency.CRITICAL;
        if (regime == IAISentinelRiskEngine.RiskRegime.WARNING) return Urgency.HIGH;
        if (regime == IAISentinelRiskEngine.RiskRegime.WATCH) return Urgency.MEDIUM;
        return Urgency.LOW;
    }

    function _convertAction(IAISentinelRiskEngine.RecommendedAction action)
        internal
        pure
        returns (IHyperlaneCrossChainExecutor.ActionType)
    {
        if (action == IAISentinelRiskEngine.RecommendedAction.MONITOR) {
            return IHyperlaneCrossChainExecutor.ActionType.MONITOR;
        }

        if (action == IAISentinelRiskEngine.RecommendedAction.PAUSE_AUTOMATION) {
            return IHyperlaneCrossChainExecutor.ActionType.PAUSE_AUTOMATION;
        }

        if (action == IAISentinelRiskEngine.RecommendedAction.REDUCE_LEVERAGE) {
            return IHyperlaneCrossChainExecutor.ActionType.REDUCE_LEVERAGE;
        }

        if (action == IAISentinelRiskEngine.RecommendedAction.REPAY_DEBT) {
            return IHyperlaneCrossChainExecutor.ActionType.REPAY_DEBT;
        }

        if (action == IAISentinelRiskEngine.RecommendedAction.MOVE_COLLATERAL) {
            return IHyperlaneCrossChainExecutor.ActionType.MOVE_COLLATERAL;
        }

        if (action == IAISentinelRiskEngine.RecommendedAction.EMERGENCY_PROTECT) {
            return IHyperlaneCrossChainExecutor.ActionType.EMERGENCY_PROTECT;
        }

        return IHyperlaneCrossChainExecutor.ActionType.MONITOR;
    }

    receive() external payable {}
}
