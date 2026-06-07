// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @title AIExecutionRouter
/// @notice Routes AI Sentinel decisions to the correct chain, executor, and action target.
contract AIExecutionRouter {
    enum AgentDecision {
        NONE,
        MONITOR,
        PAUSE_AUTOMATION,
        REDUCE_LEVERAGE,
        REPAY_DEBT,
        MOVE_COLLATERAL,
        EMERGENCY_PROTECT
    }

    struct Route {
        uint32 destinationDomain;
        bytes32 recipient;
        address target;
        bool active;
        string label;
    }

    struct RoutedExecution {
        uint256 decisionId;
        AgentDecision decision;
        uint32 destinationDomain;
        bytes32 recipient;
        address target;
        bytes payload;
        uint256 timestamp;
    }

    event RouteUpdated(
        AgentDecision indexed decision,
        uint32 destinationDomain,
        bytes32 recipient,
        address target,
        bool active,
        string label
    );

    event ExecutionRouted(
        uint256 indexed routeId,
        uint256 indexed decisionId,
        AgentDecision indexed decision,
        uint32 destinationDomain,
        bytes32 recipient,
        address target,
        bytes payload
    );

    address public owner;
    uint256 public totalRoutedExecutions;

    mapping(AgentDecision => Route) public routes;
    mapping(uint256 => RoutedExecution) public routedExecutions;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setRoute(
        AgentDecision decision,
        uint32 destinationDomain,
        bytes32 recipient,
        address target,
        bool active,
        string calldata label
    ) external onlyOwner {
        require(decision != AgentDecision.NONE, "Invalid decision");
        require(destinationDomain != 0, "Invalid domain");
        require(recipient != bytes32(0), "Invalid recipient");
        require(target != address(0), "Invalid target");

        routes[decision] = Route({
            destinationDomain: destinationDomain,
            recipient: recipient,
            target: target,
            active: active,
            label: label
        });

        emit RouteUpdated(decision, destinationDomain, recipient, target, active, label);
    }

    function routeExecution(
        uint256 decisionId,
        AgentDecision decision,
        bytes calldata payload
    ) external onlyOwner returns (uint256 routeId) {
        require(decision != AgentDecision.NONE, "Invalid decision");

        Route memory route = routes[decision];

        require(route.active, "Route inactive");
        require(route.destinationDomain != 0, "Route not configured");

        routeId = totalRoutedExecutions;

        routedExecutions[routeId] = RoutedExecution({
            decisionId: decisionId,
            decision: decision,
            destinationDomain: route.destinationDomain,
            recipient: route.recipient,
            target: route.target,
            payload: payload,
            timestamp: block.timestamp
        });

        totalRoutedExecutions++;

        emit ExecutionRouted(
            routeId,
            decisionId,
            decision,
            route.destinationDomain,
            route.recipient,
            route.target,
            payload
        );
    }

    function getRoute(AgentDecision decision) external view returns (Route memory) {
        return routes[decision];
    }

    function getRoutedExecution(uint256 routeId) external view returns (RoutedExecution memory) {
        require(routeId < totalRoutedExecutions, "Route execution does not exist");
        return routedExecutions[routeId];
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}
