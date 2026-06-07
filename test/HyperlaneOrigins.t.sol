// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/hyperlane/HyperlaneOrigin.sol";

contract HyperlaneOriginTest is Test {
    HyperlaneOrigin hyperlane;

    address owner = address(this);
    address mailbox = address(100);
    address attacker = address(999);

    function setUp() public {
        hyperlane = new HyperlaneOrigin(mailbox);
    }

    function testOwnerSetCorrectly() public {
        assertEq(hyperlane.owner(), owner);
    }

    function testMailboxSetCorrectly() public {
        assertEq(hyperlane.mailbox(), mailbox);
    }

    function testDeploy() public {
        assertEq(hyperlane.totalSignals(), 0);
    }

    function testCreateGenericSignal() public {
        uint256 signalId = hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.GENERIC, HyperlaneOrigin.Urgency.MEDIUM, 50, 25, abi.encode("generic")
        );

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
        assertEq(hyperlane.criticalSignals(), 0);
    }

    function testCreateSignal() public {
        uint256 signalId = hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.AAVE_RISK, HyperlaneOrigin.Urgency.HIGH, 75, 0, abi.encode("test")
        );

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
    }

    function testCreateAaveRiskSignal() public {
        uint256 signalId = hyperlane.triggerAaveRiskSignal(8000, 75, abi.encode("aave-test"));

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
    }

    function testCreateWhaleSignal() public {
        uint256 signalId = hyperlane.triggerWhaleSignal(address(555), 1_000_000 ether, 80, abi.encode("whale-test"));

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
    }

    function testCreateOracleRiskSignal() public {
        uint256 signalId = hyperlane.triggerOracleRiskSignal(address(777), 90, abi.encode("oracle-test"));

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
        assertEq(hyperlane.criticalSignals(), 1);
    }

    function testCriticalSignalCounterByUrgency() public {
        hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.AAVE_RISK,
            HyperlaneOrigin.Urgency.CRITICAL,
            60,
            0,
            abi.encode("critical-urgency")
        );

        assertEq(hyperlane.criticalSignals(), 1);
    }

    function testCriticalSignalCounterByRiskScore() public {
        hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.ORACLE_RISK, HyperlaneOrigin.Urgency.HIGH, 95, 0, abi.encode("critical-risk")
        );

        assertEq(hyperlane.criticalSignals(), 1);
    }

    function testCannotUseInvalidRiskScore() public {
        vm.expectRevert(bytes("Invalid risk score"));

        hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.AAVE_RISK, HyperlaneOrigin.Urgency.HIGH, 101, 0, abi.encode("bad-risk")
        );
    }

    function testCannotUseInvalidOpportunityScore() public {
        vm.expectRevert(bytes("Invalid opportunity score"));

        hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.GENERIC, HyperlaneOrigin.Urgency.LOW, 50, 101, abi.encode("bad-opportunity")
        );
    }

    function testOnlyOwnerCanTriggerSignal() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.WHALE_ACTIVITY, HyperlaneOrigin.Urgency.HIGH, 80, 0, abi.encode("attacker")
        );
    }

    function testOnlyOwnerCanTriggerAaveRiskSignal() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        hyperlane.triggerAaveRiskSignal(8000, 75, abi.encode("attacker-aave"));
    }

    function testOnlyOwnerCanTriggerWhaleSignal() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        hyperlane.triggerWhaleSignal(address(555), 1_000_000 ether, 80, abi.encode("attacker-whale"));
    }

    function testOnlyOwnerCanTriggerOracleRiskSignal() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        hyperlane.triggerOracleRiskSignal(address(777), 90, abi.encode("attacker-oracle"));
    }

    function testOnlyMailboxCanHandleMessage() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        hyperlane.handle(8453, bytes32(uint256(uint160(address(123)))), abi.encode("bad-message"));
    }

    function testMailboxCanHandleMessage() public {
        vm.prank(mailbox);

        hyperlane.handle(8453, bytes32(uint256(uint160(address(123)))), abi.encode("valid-message"));
    }

    function testGetSignal() public {
        uint256 signalId = hyperlane.triggerIntelligenceSignal(
            HyperlaneOrigin.SignalType.AAVE_RISK, HyperlaneOrigin.Urgency.HIGH, 75, 10, abi.encode("stored-signal")
        );

        HyperlaneOrigin.IntelligenceSignal memory signal = hyperlane.getSignal(signalId);

        assertEq(uint256(signal.signalType), uint256(HyperlaneOrigin.SignalType.AAVE_RISK));
        assertEq(uint256(signal.urgency), uint256(HyperlaneOrigin.Urgency.HIGH));
        assertEq(signal.riskScore, 75);
        assertEq(signal.opportunityScore, 10);
        assertEq(signal.source, owner);
    }

    function testCannotGetMissingSignal() public {
        vm.expectRevert(bytes("Signal does not exist"));

        hyperlane.getSignal(999);
    }
}
