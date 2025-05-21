// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SovereignBond} from "../src/SovereignBondERC1155.sol";

contract DeploySovereignBond is Script {
    function run() external returns (SovereignBond) {
        uint256 BOND_ID = 0 ; //SovereignBond.BOND_TOKEN_ID; // Should be 0
        // Attempt to load deployer private key from environment variable
        // Ensure PRIVATE_KEY is set in your environment or .env file for actual deployments
        // e.g., `source .env` if PRIVATE_KEY is in .env
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // For simplicity in this example, we'll use msg.sender which Foundry sets
        // based on --sender, --private-key, or its default (if using Anvil without explicit keys)
        address deployerPrivateKey = msg.sender; // This will be the address controlling the broadcast
        // If no private key is found via env, broadcast will use a default sender 
        // from your Foundry configuration or a local development node.
        // For local testing (e.g., Anvil), you might not need to set PRIVATE_KEY explicitly here
        // if you use `vm.startBroadcast()` without arguments.
        vm.startBroadcast(deployerPrivateKey);

        // --- Customize Bond Parameters for Deployment ---
        string memory bondName = "My Gov Bond Series A 4.5% 2030";
        uint256 bondRateBps = 450; // 4.50%
        uint256 bondFaceValue = 1000; // e.g., Represents $1000 (or other currency units)
        uint256 bondExpiryTermSeconds = 5 * 365 days; // Expires in 5 years
        string memory countryOfIssue = "Republic of Ethereum";
        // IMPORTANT: Replace with your actual, publicly accessible metadata URI
        string memory initialTokenURI = "https://api.example.com/metadata/mygovbond_series_a.json"; 
        // This URI should point to a JSON file like:
        // {
        //   "name": "My Gov Bond Series A 4.5% 2030",
        //   "description": "A sovereign bond issued by the Republic of Ethereum, maturing in 2030 with a 4.5% annual coupon.",
        //   "image": "https://api.example.com/images/mygovbond_series_a.png", // Optional image
        //   "properties": {
        //     "issuing_country": "Republic of Ethereum",
        //     "face_value": 1000,
        //     "coupon_rate_bps": 450,
        //     "expiry_date_readable": "YYYY-MM-DD" // Add human-readable expiry if desired
        //   }
        // }

        console.log("Deploying SovereignBond contract...");
        console.log("  Name:", bondName);
        console.log("  Rate (bps):", bondRateBps);
        console.log("  Face Value:", bondFaceValue);
        console.log("  Expiry Term (s):", bondExpiryTermSeconds);
        console.log("  Country:", countryOfIssue);
        console.log("  Metadata URI:", initialTokenURI);

        SovereignBond bond = new SovereignBond(
            bondName,
            bondRateBps,
            bondFaceValue,
            bondExpiryTermSeconds,
            countryOfIssue,
            initialTokenURI
        );

        vm.stopBroadcast();

        console.log("-----------------------------------");
        console.log("SovereignBond contract deployed!");
        console.log("  Address:", address(bond));
        console.log("  Owner:", bond.owner());
        console.log("  Bond Name:", bond.name());
        console.log("  Expiry Date (Unix Timestamp):", bond.expiryDate());
        console.log("  Token URI for ID 0:", bond.uri(BOND_ID));
        console.log("-----------------------------------");

        return bond;
    }
}

