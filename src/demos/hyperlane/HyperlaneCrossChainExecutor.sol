// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @notice Minimal Hyperlane mailbox interface for demo cross-chain dispatch.
interface IHyperlaneMailbox {
    function dispatch(uint32 destinationDomain, bytes32 recipientAddress, bytes calldata messageBody)
        external
        payable
        returns (bytes32);
}

/// @title HyperlaneCrossChainExecutor
/// @notice Demo contract that sends AI Sentinel execution messages across chains through Hyperlane-style dispatch.
contract HyperlaneCrossChainExecutor {
    enum ActionType {
        NONE,
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

    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event MailboxUpdated(address indexed oldMailbox, address indexed newMailbox);

    address public owner;
    IHyperlaneMailbox public mailbox;

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

        executions[executionId] = CrossChainAction({
            signalId: signalId,
            actionType: actionType,
            riskScore: riskScore,
            target: target,
            payload: payload,
            timestamp: block.timestamp
        });

        totalExecutions++;

        bytes memory messageBody =
            abi.encode(signalId, actionType, riskScore, target, payload, block.timestamp, block.chainid);

        messageId = mailbox.dispatch{value: msg.value}(destinationDomain, recipientAddress, messageBody);

        emit CrossChainExecutionRequested(
            messageId,
            destinationDomain,
            recipientAddress,
            signalId,
            actionType,
            riskScore,
            target,
            payload
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

    receive() external payable {}
}
