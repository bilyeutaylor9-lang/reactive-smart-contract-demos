// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/OracleGuardian.sol";

contract OracleGuardianTest is Test {
    OracleGuardian guardian;

    address oracle = address(1);
    address asset = address(2);
    address attacker = address(999);

    function setUp() public {
        guardian = new OracleGuardian();
    }

    function testOwnerSetCorrectly() public {
        assertEq(guardian.owner(), address(this));
    }

    function testReportSafeOracleData() public {
        uint256 alertId = guardian.reportOracleData(oracle, asset, 100e8, 100e8, block.timestamp);

        assertEq(alertId, 0);
        assertEq(guardian.totalAlerts(), 1);

        OracleGuardian.OracleAlert memory alert = guardian.getAlert(alertId);

        assertEq(alert.deviationBps, 0);
        assertEq(alert.riskScore, 0);
        assertEq(uint256(alert.status), uint256(OracleGuardian.OracleStatus.SAFE));
    }

    function testReportWarningDeviation() public {
        uint256 alertId = guardian.reportOracleData(oracle, asset, 110e8, 100e8, block.timestamp);

        OracleGuardian.OracleAlert memory alert = guardian.getAlert(alertId);

        assertEq(alert.deviationBps, 1_000);
        assertEq(alert.riskScore, 40);
        assertEq(uint256(alert.status), uint256(OracleGuardian.OracleStatus.WATCH));
    }

    function testReportCriticalDeviationAndStalePrice() public {
        uint256 alertId = guardian.reportOracleData(oracle, asset, 120e8, 100e8, block.timestamp - 7 hours);

        OracleGuardian.OracleAlert memory alert = guardian.getAlert(alertId);

        assertEq(alert.deviationBps, 2_000);
        assertEq(alert.riskScore, 100);
        assertEq(uint256(alert.status), uint256(OracleGuardian.OracleStatus.CRITICAL));
    }

    function testOnlyOwnerCanReportOracleData() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        guardian.reportOracleData(oracle, asset, 100e8, 100e8, block.timestamp);
    }

    function testCannotUseInvalidOracle() public {
        vm.expectRevert(bytes("Invalid oracle"));

        guardian.reportOracleData(address(0), asset, 100e8, 100e8, block.timestamp);
    }

    function testCannotUseFutureTimestamp() public {
        vm.expectRevert(bytes("Invalid update time"));

        guardian.reportOracleData(oracle, asset, 100e8, 100e8, block.timestamp + 1);
    }

    function testUpdateThresholds() public {
        guardian.updateThresholds(300, 1_000, 30 minutes, 3 hours);

        assertEq(guardian.warningDeviationBps(), 300);
        assertEq(guardian.criticalDeviationBps(), 1_000);
        assertEq(guardian.staleThresholdSeconds(), 30 minutes);
        assertEq(guardian.criticalStaleSeconds(), 3 hours);
    }

    function testOnlyOwnerCanUpdateThresholds() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        guardian.updateThresholds(300, 1_000, 30 minutes, 3 hours);
    }
}
