// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/AIStrategyOptimizer.sol";

contract AIStrategyOptimizerTest is Test {
    AIStrategyOptimizer optimizer;

    address attacker = address(999);

    function setUp() public {
        optimizer = new AIStrategyOptimizer();
    }

    function testOwnerSetCorrectly() public {
        assertEq(optimizer.owner(), address(this));
    }

    function testRecordSuccessfulLearning() public {
        uint256 recordId = optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            90,
            true,
            1_000e18
        );

        assertEq(recordId, 0);
        assertEq(optimizer.totalRecords(), 1);

        (
            uint256 totalAttempts,
            uint256 successfulAttempts,
            int256 netValueProtected,
            uint256 confidenceBps,
            uint256 lastUpdated
        ) = optimizer.actionStats(AIStrategyOptimizer.ActionType.REPAY_DEBT);

        assertEq(totalAttempts, 1);
        assertEq(successfulAttempts, 1);
        assertEq(netValueProtected, 1_000e18);
        assertEq(confidenceBps, 10_000);
        assertGt(lastUpdated, 0);
    }

    function testRecordFailedLearning() public {
        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REDUCE_LEVERAGE,
            65,
            false,
            -100e18
        );

        (
            uint256 totalAttempts,
            uint256 successfulAttempts,
            int256 netValueProtected,
            uint256 confidenceBps,

        ) = optimizer.actionStats(AIStrategyOptimizer.ActionType.REDUCE_LEVERAGE);

        assertEq(totalAttempts, 1);
        assertEq(successfulAttempts, 0);
        assertEq(netValueProtected, -100e18);
        assertEq(confidenceBps, 0);
    }

    function testConfidenceUpdatesAcrossMultipleRecords() public {
        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            90,
            true,
            1_000e18
        );

        optimizer.recordLearning(
            2,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            70,
            false,
            -100e18
        );

        assertEq(
            optimizer.getActionConfidence(AIStrategyOptimizer.ActionType.REPAY_DEBT),
            5_000
        );

        assertEq(
            optimizer.getSuccessRateBps(AIStrategyOptimizer.ActionType.REPAY_DEBT),
            5_000
        );
    }

    function testGetBestAction() public {
        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            90,
            true,
            1_000e18
        );

        optimizer.recordLearning(
            2,
            AIStrategyOptimizer.ActionType.REDUCE_LEVERAGE,
            60,
            false,
            -100e18
        );

        AIStrategyOptimizer.ActionType best = optimizer.getBestAction(
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            AIStrategyOptimizer.ActionType.REDUCE_LEVERAGE
        );

        assertEq(
            uint256(best),
            uint256(AIStrategyOptimizer.ActionType.REPAY_DEBT)
        );
    }

    function testCannotUseInvalidAction() public {
        vm.expectRevert(bytes("Invalid action"));

        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.NONE,
            50,
            true,
            100e18
        );
    }

    function testCannotUseInvalidRiskScore() public {
        vm.expectRevert(bytes("Invalid risk score"));

        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            101,
            true,
            100e18
        );
    }

    function testOnlyOwnerCanRecordLearning() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        optimizer.recordLearning(
            1,
            AIStrategyOptimizer.ActionType.REPAY_DEBT,
            90,
            true,
            1_000e18
        );
    }

    function testUpdateOwner() public {
        optimizer.updateOwner(attacker);

        assertEq(optimizer.owner(), attacker);
    }
}
