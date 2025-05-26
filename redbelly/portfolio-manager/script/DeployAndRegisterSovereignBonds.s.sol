// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SovereignBond.sol"; // Adjust path if your SovereignBond.sol is located elsewhere
import "../src/RWA_Manager.sol"; // Adjust path if your RWA_Manager.sol is located elsewhere

// /**
//  * @title IAssetManagerRegistry
//  * @notice Minimal interface for an Asset Manager contract that allows registration of new assets.
//  * @dev This interface is used by the deployment script to interact with your asset manager.
//  *      Ensure your asset manager contract implements a function matching this signature.
//  */
// interface IAssetManagerRegistry {
//     /**
//      * @notice Registers a new asset contract with the asset manager.
//      * @param category The category of the asset (e.g., "Sovereign Bond").
//      * @param assetContractAddress The address of the deployed asset contract (e.g., SovereignBond).
//      * @param assetName A descriptive name for this specific asset contract instance.
//      * @param assetSymbol A symbol for this specific asset contract instance.
//      */
//     function registerAsset(
//         string calldata category,
//         address assetContractAddress,
//         string calldata assetName,
//         string calldata assetSymbol
//     ) external;
// }

/**
 * @title DeploySovereignBonds
 * @notice Script to deploy multiple instances of the SovereignBond contract.
 * @title DeployAndRegisterSovereignBonds
 * @notice Script to deploy multiple instances of the SovereignBond contract and register them
 *         with a specified Asset Manager.
 * @dev This script uses Foundry's scripting capabilities to deploy 10 instances
 *      of the SovereignBond contract. Each instance will have the deployer
 *      as its initial owner and a unique base URI. After deployment, each bond
 *      contract is registered with an Asset Manager whose address is provided
 *      via the ASSET_MANAGER_ADDRESS environment variable.
 *      The deployer account (msg.sender) must have permission to call the
 *      `registerAsset` function on the Asset Manager contract.
 */
contract DeployAndRegisterSovereignBonds is Script {
    uint256 public constant NUM_INSTANCES_TO_DEPLOY = 10;
    string public constant BASE_URI = "https://api.example.com/bonds/{id}/metadata.json"; // Example URI

    function run() external {
        SovereignBond[] memory bonds = new SovereignBond[](NUM_INSTANCES_TO_DEPLOY);
        // Read the Asset Manager contract address from an environment variable
        // address assetManagerAddress = vm.envAddress("ASSET_MANAGER_ADDRESS");
        address assetManagerAddress = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
        require(assetManagerAddress != address(0), "DeployAndRegisterSovereignBonds: ASSET_MANAGER_ADDRESS environment variable not set or is the zero address.");

        address deployer = msg.sender; // This address will own the bonds and call the asset manager

        // 1. Deploy a new SovereignBond instance
        vm.startBroadcast();
        for (uint256 i = 0; i < NUM_INSTANCES_TO_DEPLOY; i++) {
            // You could customize the URI per instance if needed, e.g., by appending 'i'
            // string memory instanceUri = string.concat(BASE_URI, vm.toString(i));
            string memory uniqueInstanceBaseUri = string.concat("https://api.example.com/bonds/contract", vm.toString(i), "/series/{id}"); // {id} is for ERC1155 token ID
            SovereignBond newBond = new SovereignBond(deployer, uniqueInstanceBaseUri);
            console.log("Deployed SovereignBond instance #%s at address: %s", i + 1, address(newBond));
            bonds[i] = newBond;
 
        }
 
        vm.stopBroadcast();
        // 2. Register the deployed bond contract with the Asset Manager
        uint256 rwaDeployer = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(rwaDeployer);
        RWA_Manager assetManager = RWA_Manager(assetManagerAddress);
        string memory bondCategory = "Sovereign Bond";
        for (uint256 i = 0; i < NUM_INSTANCES_TO_DEPLOY; i++) {
            // 2. Register the deployed bond contract with the Asset Manager
            string memory bondContractName = string.concat("Sovereign Bond Collection #", vm.toString(i + 1));
            // string memory bondContractSymbol = string.concat("SBC-", vm.toString(i + 1));
            assetManager.registerAsset(bondContractName, address(bonds[i]), bondCategory);
            console.log("Registered '%s' (%s) with Asset Manager at %s", bondContractName, address(bonds[i]), assetManagerAddress);
         }
         vm.stopBroadcast();
     }
 }