// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/RWA_Manager.sol";

/// @title DeployRwaManagerScript
/// @notice Script to deploy multiple instances of the RWA_Manager contract.
/// @dev This script uses Foundry's scripting capabilities to deploy contracts.
/// It will deploy 5 instances of RWA_Manager, each with a unique name.
contract DeployRwaManagerScript is Script {
    /// @notice The number of RWA_Manager instances to deploy.
    uint256 public constant NUM_MANAGERS_TO_DEPLOY = 5;

    /// @notice Base name for the deployed RWA_Manager instances.
    string public constant MANAGER_BASE_NAME = "Redbelly RWA Portfolio Manager";

    /// @notice Entry point for the script.
    function run() external returns (RWA_Manager[] memory managers) {
        managers = new RWA_Manager[](NUM_MANAGERS_TO_DEPLOY);

        vm.startBroadcast();

        for (uint256 i = 0; i < NUM_MANAGERS_TO_DEPLOY; i++) {
            // Create a unique name for each manager instance
            string memory managerName = string(abi.encodePacked(MANAGER_BASE_NAME, " #", vm.toString(i + 1)));
            
            managers[i] = new RWA_Manager(managerName);
            
            console.log("Deployed RWA_Manager '%s' at address: %s", managerName, address(managers[i]));
        }

        vm.stopBroadcast();
        return managers;
    }
}