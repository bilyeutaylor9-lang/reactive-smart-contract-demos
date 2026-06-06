// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AISentinelCallback {

    event ActionExecuted(
        string action,
        uint256 timestamp
    );

    function executeAction(
        string calldata action
    ) external {

        emit ActionExecuted(
            action,
            block.timestamp
        );
    }
}