// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/WhaleDetector.sol";

contract WhaleDetectorTest is Test {
    WhaleDetector detector;

    address token = address(1);
    address whale = address(2);
    address exchange = address(3);
    address attacker = address(999);

    function setUp() public {
        detector = new WhaleDetector();
        detector.setExchangeWallet(exchange, true);
    }

    function testOwnerSetCorrectly() public {
        assertEq(detector.owner(), address(this));
    }

    function testReportWhaleTransfer() public {
        uint256 alertId = detector.reportTransfer(token, whale, exchange, 10_000_000e18, 10_000_000e18);

        assertEq(alertId, 0);
        assertEq(detector.totalAlerts(), 1);
    }

    function testBelowThresholdReturnsMax() public {
        uint256 alertId = detector.reportTransfer(token, whale, exchange, 100e18, 100e18);

        assertEq(alertId, type(uint256).max);
        assertEq(detector.totalAlerts(), 0);
    }

    function testExchangeInflowGetsHigherRisk() public {
        uint256 alertId = detector.reportTransfer(token, whale, exchange, 10_000_000e18, 10_000_000e18);

        WhaleDetector.WhaleAlert memory alert = detector.getAlert(alertId);

        assertEq(alert.riskScore, 90);
        assertEq(uint256(alert.direction), uint256(WhaleDetector.WhaleDirection.INFLOW));
    }

    function testOnlyOwnerCanReportTransfer() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        detector.reportTransfer(token, whale, exchange, 10_000_000e18, 10_000_000e18);
    }
}
