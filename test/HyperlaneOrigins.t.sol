// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/hyperlane/HyperlaneOrigin.sol";

contract HyperlaneOriginTest is Test {
    HyperlaneOrigin hyperlane;

    function setUp() public {
        hyperlane = new HyperlaneOrigin(address(100));
    }

    function testDeploy() public {
        assertEq(hyperlane.totalSignals(), 0);
    }

    function testCreateSignal() public {
        uint256 signalId =
            hyperlane.triggerIntelligenceSignal(
                HyperlaneOrigin.SignalType.AAVE_RISK,
                HyperlaneOrigin.Urgency.HIGH,
                75,
                0,
                abi.encode("test")
            );

        assertEq(signalId, 0);
        assertEq(hyperlane.totalSignals(), 1);
    }
}
