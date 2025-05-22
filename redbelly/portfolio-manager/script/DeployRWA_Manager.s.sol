// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RWA_Manager.sol";

/**
 * @title DeployRWA_Manager
 * @author Gemini
 * @notice Script to deploy the RWA_Manager contract.
 */
contract DeployRWA_Manager is Script {
    function run() external returns (RWA_Manager) {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // If PRIVATE_KEY is not set, Foundry's `vm.broadcast()` will use a default test account
        // or one specified by --from, --private-key CLI args, or configured in foundry.toml
        // uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // vm.startBroadcast(deployerPrivateKey);
        string memory mngrName = "Redbelly Asset Magician";

        vm.startBroadcast();

        RWA_Manager rwaManager = new RWA_Manager(mngrName);

        vm.stopBroadcast();

        console.log("RWA_Manager deployed to:", address(rwaManager));
        console.log("Owner of RWA_Manager:", rwaManager.owner());
        console.log("Name of RWA_Manager:", rwaManager.name());
        
        return rwaManager;
    }
}

