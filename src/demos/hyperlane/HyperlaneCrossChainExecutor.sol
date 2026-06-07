// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IHyperlaneMailbox {
    function dispatch(uint32 destinationDomain, bytes32 recipientAddress, bytes calldata messageBody)
        external
        payable
        returns (bytes32);
}

interface IOutcomeTracker {
    enum ActionType {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    function recordOutcome(
        uint256 signalId,
        uint256 riskScore,
        ActionType actionTaken,
        bool executed,
        bool successful,
        int256 valueProtected,
        string calldata notes
    ) external;
}

/// @title HyperlaneCrossChainExecutor
/// @notice Sends AI Sentinel execution messages across chains and optionally records outcomes.
contract HyperlaneCrossChainExecutor {
    enum ActionType {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    struct CrossChainAction {
        uint256 signalId;
        ActionType actionType;
        uint256 riskScore;
        address target;
        bytes payload;
        uint256 timestamp;
        bytes32 messageId;
        bool outcomeRecorded;
    }

    event CrossChainExecutionRequested(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        bytes32 indexed recipient,
        uint256 signalId,
        ActionType actionType,
        uint256 riskScore,
        address target,
        bytes payload
    );

    event OutcomeTrackerUpdated(address indexed oldTracker, address indexed newTracker);

    event ExecutionOutcomeRecorded(
        uint256 indexed executionId,
        uint256 indexed signalId,
        ActionType actionType,
        uint256 riskScore,
        bool executed,
        bool successful,
        int256 valueProtected,
        string notes
    );

    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event MailboxUpdated(address indexed oldMailbox, address indexed newMailbox);

    address public owner;
    IHyperlaneMailbox public mailbox;
    IOutcomeTracker public outcomeTracker;

    uint256 public totalExecutions;

    mapping(uint256 => CrossChainAction) public executions;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _mailbox) {
        require(_mailbox != address(0), "Invalid mailbox");
        owner = msg.sender;
        mailbox = IHyperlaneMailbox(_mailbox);
    }

    function requestCrossChainExecution(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        uint256 signalId,
        ActionType actionType,
        uint256 riskScore,
        address target,
        bytes calldata payload
    ) external payable onlyOwner returns (bytes32 messageId) {
        require(destinationDomain != 0, "Invalid destination");
        require(recipientAddress != bytes32(0), "Invalid recipient");
        require(target != address(0), "Invalid target");
        require(riskScore <= 100, "Invalid risk score");
        require(actionType != ActionType.NONE, "Invalid action");

        uint256 executionId = totalExecutions;

        bytes memory messageBody = abi.encode(signalId, actionType, riskScore, target, payload, block.timestamp, block.chainid);

        messageId = mailbox.dispatch{value: msg.value}(destinationDomain, recipientAddress, messageBody);

        executions[executionId] = CrossChainAction({
            signalId: signalId,
            actionType: actionType,
            riskScore: riskScore,
            target: target,
            payload: payload,
            timestamp: block.timestamp,
            messageId: messageId,
            outcomeRecorded: false
        });

        totalExecutions++;

        emit CrossChainExecutionRequested(
            messageId, destinationDomain, recipientAddress, signalId, actionType, riskScore, target, payload
        );
    }

    function setOutcomeTracker(address tracker) external onlyOwner {
        address oldTracker = address(outcomeTracker);
        outcomeTracker = IOutcomeTracker(tracker);

        emit OutcomeTrackerUpdated(oldTracker, tracker);
    }

    function recordExecutionOutcome(
        uint256 executionId,
        bool executed,
        bool successful,
        int256 valueProtected,
        string calldata notes
    ) external onlyOwner {
        require(executionId < totalExecutions, "Execution does not exist");
        require(!executions[executionId].outcomeRecorded, "Outcome already recorded");
        require(address(outcomeTracker) != address(0), "Outcome tracker not set");

        CrossChainAction storage action = executions[executionId];
        action.outcomeRecorded = true;

        outcomeTracker.recordOutcome(
            action.signalId,
            action.riskScore,
            _convertAction(action.actionType),
            executed,
            successful,
            valueProtected,
            notes
        );

        emit ExecutionOutcomeRecorded(
            executionId, action.signalId, action.actionType, action.riskScore, executed, successful, valueProtected, notes
        );
    }

    function updateMailbox(address newMailbox) external onlyOwner {
        require(newMailbox != address(0), "Invalid mailbox");

        address oldMailbox = address(mailbox);
        mailbox = IHyperlaneMailbox(newMailbox);

        emit MailboxUpdated(oldMailbox, newMailbox);
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnerUpdated(oldOwner, newOwner);
    }

    function _convertAction(ActionType actionType) internal pure returns (IOutcomeTracker.ActionType) {
        if (actionType == ActionType.MONITOR) return IOutcomeTracker.ActionType.MONITOR;
        if (actionType == ActionType.PAUSE_AUTOMATION) return IOutcomeTracker.ActionType.PAUSE_AUTOMATION;
        if (actionType == ActionType.REDUCE_LEVERAGE) return IOutcomeTracker.ActionType.REDUCE_LEVERAGE;
        if (actionType == ActionType.REPAY_DEBT) return IOutcomeTracker.ActionType.REPAY_DEBT;
        if (actionType == ActionType.MOVE_COLLATERAL) return IOutcomeTracker.ActionType.MOVE_COLLATERAL;
        if (actionType == ActionType.EMERGENCY_PROTECT) return IOutcomeTracker.ActionType.EMERGENCY_PROTECT;

        return IOutcomeTracker.ActionType.NONE;
    }

    receive() external payable {}
}
