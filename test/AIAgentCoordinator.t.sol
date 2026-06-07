// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/AIAgentCoordinator.sol";

contract AIAgentCoordinatorTest is Test {
    AIAgentCoordinator coordinator;

    address target = address(123);
    address attacker = address(999);

    function setUp() public {
        coordinator = new AIAgentCoordinator();
    }

    function testOwnerSetCorrectly() public {
        assertEq(coordinator.owner(), address(this));
    }

    function testCoordinateAaveEmergencyDecision() public {
        uint256 decisionId = coordinator.coordinateAaveAlert(1, 11e17, 95, target, abi.encode("aave emergency"));

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(decisionId, 0);
        assertEq(coordinator.totalDecisions(), 1);
        assertEq(uint256(decision.source), uint256(AIAgentCoordinator.AlertSource.AAVE));
        assertEq(uint256(decision.decision), uint256(AIAgentCoordinator.AgentDecision.EMERGENCY_PROTECT));
        assertEq(uint256(decision.status), uint256(AIAgentCoordinator.DecisionStatus.PENDING));
    }

    function testCoordinateAaveRepayDebtDecision() public {
        uint256 decisionId = coordinator.coordinateAaveAlert(2, 14e17, 81, target, abi.encode("repay debt"));

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(uint256(decision.decision), uint256(AIAgentCoordinator.AgentDecision.REPAY_DEBT));
    }

    function testCoordinateWhaleDecision() public {
        uint256 decisionId = coordinator.coordinateWhaleAlert(3, 80, target, abi.encode("whale reduce leverage"));

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(uint256(decision.source), uint256(AIAgentCoordinator.AlertSource.WHALE));
        assertEq(uint256(decision.decision), uint256(AIAgentCoordinator.AgentDecision.REDUCE_LEVERAGE));
    }

    function testCoordinateOracleDecision() public {
        uint256 decisionId = coordinator.coordinateOracleAlert(4, 75, target, abi.encode("pause automation"));

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(uint256(decision.source), uint256(AIAgentCoordinator.AlertSource.ORACLE));
        assertEq(uint256(decision.decision), uint256(AIAgentCoordinator.AgentDecision.PAUSE_AUTOMATION));
    }

    function testApproveAndExecuteDecision() public {
        uint256 decisionId = coordinator.coordinateWhaleAlert(5, 80, target, abi.encode("execute"));

        coordinator.approveDecision(decisionId);
        coordinator.markExecuted(decisionId);

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(uint256(decision.status), uint256(AIAgentCoordinator.DecisionStatus.EXECUTED));
    }

    function testMarkFailed() public {
        uint256 decisionId = coordinator.coordinateOracleAlert(6, 75, target, abi.encode("fail"));

        coordinator.markFailed(decisionId);

        AIAgentCoordinator.CoordinatedDecision memory decision = coordinator.getDecision(decisionId);

        assertEq(uint256(decision.status), uint256(AIAgentCoordinator.DecisionStatus.FAILED));
    }

    function testOnlyOwnerCanCoordinate() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        coordinator.coordinateWhaleAlert(1, 80, target, abi.encode("attacker"));
    }

    function testCannotUseInvalidRiskScore() public {
        vm.expectRevert(bytes("Invalid risk score"));

        coordinator.coordinateOracleAlert(1, 101, target, abi.encode("bad risk"));
    }

    function testCannotUseInvalidTarget() public {
        vm.expectRevert(bytes("Invalid target"));

        coordinator.coordinateAaveAlert(1, 11e17, 95, address(0), abi.encode("bad target"));
    }
}
