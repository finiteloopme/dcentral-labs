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
        // Ensure these arrays have at least NUM_INSTANCES_TO_DEPLOY elements
        string[] memory seriesNames = new string[](NUM_INSTANCES_TO_DEPLOY);
        string[] memory seriesSymbols = new string[](NUM_INSTANCES_TO_DEPLOY);
        // Sample data for 10 bonds
        seriesNames[0] = "US Treasury Note 2.0% 2025"; seriesSymbols[0] = "UST25";
        seriesNames[1] = "German Bund 0.5% 2026"; seriesSymbols[1] = "DEB26";
        seriesNames[2] = "UK Gilt 1.5% 2027"; seriesSymbols[2] = "UKG27";
        seriesNames[3] = "Japanese JGB 0.1% 2028"; seriesSymbols[3] = "JGB28";
        seriesNames[4] = "Canadian Bond 1.75% 2029"; seriesSymbols[4] = "CAN29";
        seriesNames[5] = "Australian Bond 1.25% 2030"; seriesSymbols[5] = "AUB30";
        seriesNames[6] = "French OAT 0.75% 2031"; seriesSymbols[6] = "FRO31";
        seriesNames[7] = "Italian BTP 2.5% 2032"; seriesSymbols[7] = "ITB32";
        seriesNames[8] = "Spanish Bono 1.0% 2033"; seriesSymbols[8] = "ESB33";
        seriesNames[9] = "Swiss Conf Bond 0.25% 2034"; seriesSymbols[9] = "CHB34";

        // 1. Deploy a new SovereignBond instance
        vm.startBroadcast();
        for (uint256 i = 0; i < NUM_INSTANCES_TO_DEPLOY; i++) {
            string memory currentSeriesName = seriesNames[i];
            string memory currentSeriesSymbol = seriesSymbols[i];
            
            // Realistic parameters for each bond series:
            // _valuePerUnit: Value of one indivisible unit (e.g., 1 cent if fractionalFactor is 100 for $1)
            uint256 currentUnitValue = 1; // e.g., 1 represents $0.01
            // _initialUnitSupply: Total supply of indivisible units.
            // e.g., for $10,000,000 total value, if 1 unit = $0.01, then supply = 10,000,000 * 100 = 1,000,000,000 units
            uint256 currentInitialSupply = 1_000_000_000; 
            // _fractionalFactor: How many indivisible units make one conceptual "whole" bond or currency unit.
            // e.g., 100 if smallest unit is cent and conceptual unit is dollar.
            uint256 currentFractionalFactor = 100; 

            SovereignBond newBond = new SovereignBond(
                currentSeriesName,
                currentSeriesSymbol,
                currentUnitValue,
                currentInitialSupply,
                currentFractionalFactor
            );
            // The ERC1155 URI is set inside SovereignBond constructor as: string.concat("https://global.bonds/", seriesSymbol)
            console.log(
                "Deployed SovereignBond contract for series '%s' (%s) at address: %s",
                currentSeriesName,
                currentSeriesSymbol,
                address(newBond)
            );
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
            // string memory bondContractSymbol = string.concat("SBC-", vm.toString(i + 1));
            assetManager.registerAsset(bonds[i].name(), address(bonds[i]), bondCategory);
            console.log("Registered '%s' (%s) with Asset Manager at %s", bonds[i].name(), address(bonds[i]), assetManagerAddress);
         }
         vm.stopBroadcast();
     }
 }