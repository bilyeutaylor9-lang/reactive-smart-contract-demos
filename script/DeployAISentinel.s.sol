// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../src/demos/hyperlane/HyperlaneOrigin.sol";
import "../src/demos/hyperlane/HyperlaneCrossChainExecutor.sol";
import "../src/demos/ai-sentinel/OutcomeTracker.sol";
import "../src/demos/ai-sentinel/AIStrategyOptimizer.sol";

contract DeployAISentinel is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address mockMailbox = vm.envOr("MOCK_MAILBOX", address(0x1000000000000000000000000000000000000001));

        vm.startBroadcast(deployerPrivateKey);

        HyperlaneOrigin origin = new HyperlaneOrigin(mockMailbox);
        HyperlaneCrossChainExecutor executor = new HyperlaneCrossChainExecutor(mockMailbox);
        OutcomeTracker tracker = new OutcomeTracker();
        AIStrategyOptimizer optimizer = new AIStrategyOptimizer();

        executor.setOutcomeTracker(address(tracker));
        tracker.updateOwner(address(executor));
        origin.setCrossChainExecutor(address(executor));

        vm.stopBroadcast();

        console2.log("HyperlaneOrigin:", address(origin));
        console2.log("HyperlaneCrossChainExecutor:", address(executor));
        console2.log("OutcomeTracker:", address(tracker));
        console2.log("AIStrategyOptimizer:", address(optimizer));
    }
}
