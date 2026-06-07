// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/demos/ai-sentinel/AISentinelRiskEngine.sol";

contract AISentinelRiskEngineTest is Test {
    AISentinelRiskEngine engine;

    address attacker = address(999);

    function setUp() public {
        engine = new AISentinelRiskEngine();
    }

    function testOwnerSetCorrectly() public {
        assertEq(engine.owner(), address(this));
    }

    function testEvaluateAaveCriticalRisk() public {
        AISentinelRiskEngine.RiskResult memory result = engine.evaluateAaveRisk(1, 1e18, 20, 20);

        assertEq(result.score, 100);
        assertEq(uint256(result.regime), uint256(AISentinelRiskEngine.RiskRegime.CRITICAL));
        assertEq(uint256(result.action), uint256(AISentinelRiskEngine.RecommendedAction.EMERGENCY_PROTECT));
    }

    function testEvaluateOracleRisk() public {
        AISentinelRiskEngine.RiskResult memory result = engine.evaluateOracleRisk(2, 40, 25, 20);

        assertEq(result.score, 85);
        assertEq(uint256(result.regime), uint256(AISentinelRiskEngine.RiskRegime.WARNING));
        assertEq(uint256(result.action), uint256(AISentinelRiskEngine.RecommendedAction.REPAY_DEBT));
    }

    function testEvaluateWhaleRisk() public {
        AISentinelRiskEngine.RiskResult memory result = engine.evaluateWhaleRisk(3, 20, 20, 20);

        assertEq(result.score, 60);
        assertEq(uint256(result.regime), uint256(AISentinelRiskEngine.RiskRegime.WATCH));
        assertEq(uint256(result.action), uint256(AISentinelRiskEngine.RecommendedAction.REDUCE_LEVERAGE));
    }

    function testOnlyOwnerCanEvaluate() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Not authorized"));

        engine.evaluateGenericRisk(4, 10, 10, 10);
    }
}
