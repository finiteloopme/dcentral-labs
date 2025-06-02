// // File: script/DeployStableCoin.s.sol
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Script.sol";
// import "../src/StableCoinERC1155.sol"; // Adjust path to your StableCoin.sol

// /**
//  * @title DeployStableCoin
//  * @dev Script to deploy the StableCoin contract.
//  * It reads deployment parameters from environment variables.
//  *
//  * Required Environment Variables:
//  * - DEPLOYER_PRIVATE_KEY: Private key of the account deploying the contract.
//  * - TOKEN_NAME: Name of the stablecoin (e.g., "My Stable Dollar").
//  * - TOKEN_SYMBOL: Symbol of the stablecoin (e.g., "MUSD").
//  * - FIAT_PEG: Fiat currency the coin is pegged to (e.g., "USD").
//  * - TOKEN_URI: Initial URI for token metadata (e.g., "https://api.example.com/token/musd.json").
//  * - ETH_RPC_URL: (Optional for local anvil) RPC URL for the target network.
//  *
//  * Example Usage (Anvil - local testnet):
//  * source .env # if you have a .env file with DEPLOYER_PRIVATE_KEY
//  * forge script script/DeployStableCoin.s.sol --rpc-url http://localhost:8545 --broadcast \
//  * --sig "run(string,string,string,string)" \
//  * "My Test Stablecoin" "MTS" "USD" "https://example.com/mts.json"
//  *
//  * Example Usage (Testnet/Mainnet - using env vars for secrets):
//  * forge script script/DeployStableCoin.s.sol:DeployStableCoin --rpc-url $ETH_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast \
//  * --sig "run(string,string,string,string)" \
//  * "$TOKEN_NAME" "$TOKEN_SYMBOL" "$FIAT_PEG" "$TOKEN_URI"
//  *
//  * Or, if you prefer to load all from env:
//  * forge script script/DeployStableCoin.s.sol:DeployStableCoin --rpc-url $ETH_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast
//  * (This would require the script to read all params from vm.envString)
//  */
// contract DeployStableCoin is Script {
//     StableCoin public stableCoin;

//     function run(
//         // string memory _name,
//         // string memory _symbol,
//         // string memory _fiatPeggedTo,
//         // string memory _uri
//     ) external returns (StableCoin) {
//         // Retrieve deployer private key from environment variable
//         // uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
//         // address deployerAddress = vm.addr(deployerPrivateKey);

//         // For simplicity in this example, we'll use msg.sender which Foundry sets
//         // based on --sender, --private-key, or its default (if using Anvil without explicit keys)
//         address deployerAddress = msg.sender; // This will be the address controlling the broadcast
//         string memory _name = "Default StableCoin";// vm.envOr("TOKEN_NAME", "Default StableCoin");
//         string memory _symbol = "USDD"; // vm.envOr("TOKEN_SYMBOL", "DSC");
//         string memory _fiatPeggedTo = "USD"; // vm.envOr("FIAT_PEG", "USD");
//         string memory _uri = "https://default.example.com/token.json"; // vm.envOr("TOKEN_URI", "https://default.example.com/token.json");

//         vm.startBroadcast(deployerAddress);

//         console.log("Deploying StableCoin with the following parameters:");
//         console.log("  Deployer:", deployerAddress);
//         console.log("  Name:", _name);
//         console.log("  Symbol:", _symbol);
//         console.log("  Fiat Peg:", _fiatPeggedTo);
//         console.log("  URI:", _uri);

//         stableCoin = new StableCoin(
//             deployerAddress, // Initial owner is the deployer
//             _name,
//             _symbol,
//             _fiatPeggedTo,
//             _uri
//         );

//         vm.stopBroadcast();

//         console.log("StableCoin deployed at:", address(stableCoin));
//         console.log("  Name:", stableCoin.name());
//         console.log("  Symbol:", stableCoin.symbol());
//         console.log("  Fiat Pegged To:", stableCoin.fiatPeggedTo());
//         console.log("  Owner:", stableCoin.owner());
//         console.log("  Decimals:", stableCoin.decimals());
//         console.log("  STABLECOIN_ID:", stableCoin.STABLECOIN_ID());
//         console.log("  Initial URI for ID 0:", stableCoin.uri(0));

//         return stableCoin;
//     }

//     // Fallback run function to load parameters from environment variables
//     // This allows running `forge script ... --broadcast` without explicit arguments
//     // if the environment variables are set.
//     // function run() external returns (StableCoin) {
//     //     string memory tokenName = "Default StableCoin";// vm.envOr("TOKEN_NAME", "Default StableCoin");
//     //     string memory tokenSymbol = "USDD"; // vm.envOr("TOKEN_SYMBOL", "DSC");
//     //     string memory fiatPeg = "USD"; // vm.envOr("FIAT_PEG", "USD");
//     //     string memory tokenUri = "https://default.example.com/token.json"; // vm.envOr("TOKEN_URI", "https://default.example.com/token.json");

//     //     return run(tokenName, tokenSymbol, fiatPeg, tokenUri);
//     // }
// }

