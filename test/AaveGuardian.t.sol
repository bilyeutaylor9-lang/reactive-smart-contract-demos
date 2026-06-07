// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/AaveGuardian.sol";

contract AaveGuardianTest is Test {
    AaveGuardian guardian;

    address user = address(123);
    address attacker = address(999);

    function setUp() public {
        guardian = new AaveGuardian();
    }

    function testOwnerSetCorrectly() public {
        assertEq(guardian.owner(), address(this));
    }

    function testSafePosition() public {
        uint256 alertId = guardian.evaluatePosition(
            user,
            25e17,
            1000e18,
            200e18,
            500e18
        );

        AaveGuardian.PositionAlert memory alert =
            guardian.getAlert(alertId);

        assertEq(alert.riskScore, 10);
        assertEq(
            uint256(alert.status),
            uint256(AaveGuardian.PositionStatus.SAFE)
        );
    }

    function testWatchPosition() public {
        uint256 alertId = guardian.evaluatePosition(
            user,
            19e17,
            1000e18,
            400e18,
            100e18
        );

        AaveGuardian.PositionAlert memory alert =
            guardian.getAlert(alertId);

        assertEq(alert.riskScore, 50);
        assertEq(
            uint256(alert.status),
            uint256(AaveGuardian.PositionStatus.WATCH)
        );
    }

    function testWarningPosition() public {
        uint256 alertId = guardian.evaluatePosition(
            user,
            14e17,
            1000e18,
            700e18,
            50e18
        );

        AaveGuardian.PositionAlert memory alert =
            guardian.getAlert(alertId);

        assertEq(alert.riskScore, 75);
        assertEq(
            uint256(alert.status),
            uint256(AaveGuardian.PositionStatus.WARNING)
        );
    }

    function testCriticalPosition() public {
        uint256 alertId = guardian.evaluatePosition(
            user,
            11e17,
            1000e18,
            900e18,
            10e18
        );

        AaveGuardian.PositionAlert memory alert =
            guardian.getAlert(alertId);

        assertEq(alert.riskScore, 95);
        assertEq(
            uint256(alert.status),
            uint256(AaveGuardian.PositionStatus.CRITICAL)
        );
    }

    function testOnlyOwnerCanEvaluate() public {
        vm.prank(attacker);

        vm.expectRevert(bytes("Not authorized"));

        guardian.evaluatePosition(
            user,
            11e17,
            1000e18,
            900e18,
            10e18
        );
    }

    function testCannotUseZeroAddress() public {
        vm.expectRevert(bytes("Invalid user"));

        guardian.evaluatePosition(
            address(0),
            15e17,
            1000e18,
            500e18,
            100e18
        );
    }

    function testUpdateThresholds() public {
        guardian.updateThresholds(
            3e18,
            2e18,
            15e17
        );

        assertEq(guardian.watchHealthFactor(), 3e18);
        assertEq(guardian.warningHealthFactor(), 2e18);
        assertEq(guardian.criticalHealthFactor(), 15e17);
    }
}
