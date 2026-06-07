// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/OutcomeTracker.sol";

contract OutcomeTrackerTest is Test {
    OutcomeTracker tracker;

    address attacker = address(999);

    function setUp() public {
        tracker = new OutcomeTracker();
    }

    function testOwnerSetCorrectly() public {
        assertEq(tracker.owner(), address(this));
    }

    function testRecordOutcome() public {
        tracker.recordOutcome(
            1,
            88,
            OutcomeTracker.ActionType.REPAY_DEBT,
            true,
            true,
            500e18,
            "Debt repaid before liquidation"
        );

        assertEq(tracker.totalOutcomes(), 1);
        assertEq(tracker.successfulOutcomes(), 1);
        assertEq(tracker.totalValueProtected(), 500e18);
        assertEq(tracker.getSuccessRateBps(), 10_000);
    }

    function testCannotRecordDuplicateOutcome() public {
        tracker.recordOutcome(1, 88, OutcomeTracker.ActionType.REPAY_DEBT, true, true, 500e18, "first");

        vm.expectRevert(bytes("Outcome already recorded"));

        tracker.recordOutcome(1, 90, OutcomeTracker.ActionType.EMERGENCY_PROTECT, true, true, 900e18, "duplicate");
    }

    function testCannotUseInvalidRiskScore() public {
        vm.expectRevert(bytes("Invalid risk score"));

        tracker.recordOutcome(1, 101, OutcomeTracker.ActionType.REPAY_DEBT, true, true, 500e18, "bad score");
    }

    function testOnlyOwnerCanRecordOutcome() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        tracker.recordOutcome(1, 88, OutcomeTracker.ActionType.REPAY_DEBT, true, true, 500e18, "attacker");
    }

    function testGetOutcome() public {
        tracker.recordOutcome(7, 75, OutcomeTracker.ActionType.REDUCE_LEVERAGE, true, false, -50e18, "Action failed");

        OutcomeTracker.Outcome memory outcome = tracker.getOutcome(7);

        assertEq(outcome.signalId, 7);
        assertEq(outcome.riskScore, 75);
        assertEq(uint256(outcome.actionTaken), uint256(OutcomeTracker.ActionType.REDUCE_LEVERAGE));
        assertEq(outcome.executed, true);
        assertEq(outcome.successful, false);
        assertEq(outcome.valueProtected, -50e18);
    }
}
