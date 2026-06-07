// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/hyperlane/HyperlaneCrossChainExecutor.sol";
import "../src/demos/ai-sentinel/OutcomeTracker.sol";

contract MockHyperlaneMailbox {
    bytes32 public lastMessageId;
    uint32 public lastDestinationDomain;
    bytes32 public lastRecipient;
    bytes public lastMessageBody;

    function dispatch(uint32 destinationDomain, bytes32 recipientAddress, bytes calldata messageBody)
        external
        payable
        returns (bytes32)
    {
        lastDestinationDomain = destinationDomain;
        lastRecipient = recipientAddress;
        lastMessageBody = messageBody;
        lastMessageId = keccak256(abi.encode(destinationDomain, recipientAddress, messageBody, block.timestamp));
        return lastMessageId;
    }
}

contract HyperlaneCrossChainExecutorTest is Test {
    HyperlaneCrossChainExecutor executor;
    MockHyperlaneMailbox mailbox;
    OutcomeTracker tracker;

    address owner = address(this);
    address attacker = address(999);
    address target = address(123);

    function setUp() public {
        mailbox = new MockHyperlaneMailbox();
        tracker = new OutcomeTracker();
        executor = new HyperlaneCrossChainExecutor(address(mailbox));
        tracker = new OutcomeTracker();
    }

    function testOwnerSetCorrectly() public {
        assertEq(executor.owner(), owner);
    }

    function testMailboxSetCorrectly() public {
        assertEq(address(executor.mailbox()), address(mailbox));
    }

    function testRequestCrossChainExecution() public {
        bytes32 recipient = bytes32(uint256(uint160(address(456))));

        bytes32 messageId = executor.requestCrossChainExecution(
            8453,
            recipient,
            1,
            HyperlaneCrossChainExecutor.ActionType.REDUCE_LEVERAGE,
            88,
            target,
            abi.encode("reduce leverage")
        );

        assertEq(executor.totalExecutions(), 1);
        assertEq(mailbox.lastMessageId(), messageId);
        assertEq(mailbox.lastDestinationDomain(), 8453);
        assertEq(mailbox.lastRecipient(), recipient);
    }

    function testSetOutcomeTracker() public {
        executor.setOutcomeTracker(address(tracker));

        assertEq(address(executor.outcomeTracker()), address(tracker));
    }

    function testRecordExecutionOutcome() public {
        executor.setOutcomeTracker(address(tracker));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            7,
            HyperlaneCrossChainExecutor.ActionType.REPAY_DEBT,
            91,
            target,
            abi.encode("repay debt")
        );

        executor.recordExecutionOutcome(0, true, true, 1_000e18, "Debt repaid before liquidation");

        assertEq(tracker.totalOutcomes(), 1);
        assertEq(tracker.successfulOutcomes(), 1);
        assertEq(tracker.totalValueProtected(), 1_000e18);

        OutcomeTracker.Outcome memory outcome = tracker.getOutcome(7);

        assertEq(outcome.signalId, 7);
        assertEq(outcome.riskScore, 91);
        assertEq(uint256(outcome.actionTaken), uint256(OutcomeTracker.ActionType.REPAY_DEBT));
        assertEq(outcome.executed, true);
        assertEq(outcome.successful, true);
        assertEq(outcome.valueProtected, 1_000e18);
    }

    function testCannotRecordOutcomeWithoutTracker() public {
        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            7,
            HyperlaneCrossChainExecutor.ActionType.REPAY_DEBT,
            91,
            target,
            abi.encode("repay debt")
        );

        vm.expectRevert(bytes("Outcome tracker not set"));

        executor.recordExecutionOutcome(0, true, true, 1_000e18, "missing tracker");
    }

    function testCannotRecordDuplicateOutcome() public {
        executor.setOutcomeTracker(address(tracker));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            7,
            HyperlaneCrossChainExecutor.ActionType.REPAY_DEBT,
            91,
            target,
            abi.encode("repay debt")
        );

        executor.recordExecutionOutcome(0, true, true, 1_000e18, "first");

        vm.expectRevert(bytes("Outcome already recorded"));

        executor.recordExecutionOutcome(0, true, true, 1_000e18, "duplicate");
    }

    function testOnlyOwnerCanRecordOutcome() public {
        executor.setOutcomeTracker(address(tracker));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            7,
            HyperlaneCrossChainExecutor.ActionType.REPAY_DEBT,
            91,
            target,
            abi.encode("repay debt")
        );

        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        executor.recordExecutionOutcome(0, true, true, 1_000e18, "attacker");
    }

    function testOnlyOwnerCanRequestExecution() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            1,
            HyperlaneCrossChainExecutor.ActionType.REPAY_DEBT,
            90,
            target,
            abi.encode("repay debt")
        );
    }

    function testCannotUseInvalidRiskScore() public {
        vm.expectRevert(bytes("Invalid risk score"));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            1,
            HyperlaneCrossChainExecutor.ActionType.EMERGENCY_PROTECT,
            101,
            target,
            abi.encode("bad risk")
        );
    }

    function testCannotUseNoneAction() public {
        vm.expectRevert(bytes("Invalid action"));

        executor.requestCrossChainExecution(
            8453,
            bytes32(uint256(uint160(address(456)))),
            1,
            HyperlaneCrossChainExecutor.ActionType.NONE,
            50,
            target,
            abi.encode("none")
        );
    }
}
