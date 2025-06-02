// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";
// import "../src/StableCoin.sol"; // Assumes StableCoin.sol is in the src directory
// import "../src/RWA_Manager.sol"; // Adjust path if your RWA_Manager.sol is located elsewhere

// /**
//  * @title DeployStablecoins
//  * @notice Script to deploy multiple instances of the Stablecoin contract.
//  * @dev This script deploys 10 different stablecoins with predefined parameters.
//  *      To run this script:
//  *      1. Ensure your .env file has DEPLOYER_PRIVATE_KEY set, or pass --private-key via CLI.
//  *      2. Execute: forge script script/DeployStablecoins.s.sol:DeployStablecoins --rpc-url <YOUR_RPC_URL> --broadcast -vvvv
//  */
// contract DeployStablecoins is Script {
//     /**
//      * @dev Struct to hold the parameters for deploying a single Stablecoin.
//      * @param name The name of the stablecoin (e.g., "Digital Dollar").
//      * @param symbol The symbol of the stablecoin (e.g., "DUSD").
//      * @param decimalsVal The number of decimal places for the token.
//      * @param assetValuePerUnit The value assigned to one indivisible unit of this stablecoin (typically 1).
//      * @param initialSupply The initial total supply in indivisible units (e.g., for 100 tokens with 6 decimals, pass 100 * 10^6).
//      */
//     struct StablecoinDeploymentParams {
//         string name;
//         string symbol;
//         uint8 decimalsVal;
//         uint256 assetValuePerUnit;
//         uint256 initialSupply;
//     }

//     function run() external {
//         // Attempt to load deployer private key from environment variable, or use a default/sender.
//         uint256 deployerPrivateKey = vm.envOr("DEPLOYER_PRIVATE_KEY", vm.envOr("PRIVATE_KEY", uint256(0)));
//         address deployer;

//         if (deployerPrivateKey != 0) {
//             deployer = vm.rememberKey(deployerPrivateKey);
//         } else {
//             // Fallback to msg.sender if no private key is found in env.
//             // This means the script must be executed by an account with funds.
//             // e.g., forge script ... --sender <your_sender_address> --private-key <your_private_key_for_sender>
//             // or if foundry.toml has a default sender configured.
//             deployer = msg.sender;
//             console.log("Warning: DEPLOYER_PRIVATE_KEY not found in .env. Using msg.sender: %s", deployer);
//             require(deployer != address(0), "Deployer address is zero. Set DEPLOYER_PRIVATE_KEY or ensure msg.sender is valid.");
//         }

//         StablecoinDeploymentParams[] memory allParams = new StablecoinDeploymentParams[](10);
//         Stablecoin[] memory stablecoins = new Stablecoin[](10);

//         // Define parameters for 10 stablecoins
//         // Note: initialSupply should be total indivisible units (amount * 10^decimals)
//         allParams[0] = StablecoinDeploymentParams("Digital US Dollar", "DUSD", 6, 1, 1_000_000 * (10**6));
//         allParams[1] = StablecoinDeploymentParams("Digital Euro", "DEUR", 6, 1, 500_000 * (10**6));
//         allParams[2] = StablecoinDeploymentParams("Digital Yen", "DJPY", 2, 1, 100_000_000 * (10**2));
//         allParams[3] = StablecoinDeploymentParams("Digital Pound", "DGBP", 6, 1, 250_000 * (10**6));
//         allParams[4] = StablecoinDeploymentParams("Digital Swiss Franc", "DCHF", 6, 1, 100_000 * (10**6));
//         allParams[5] = StablecoinDeploymentParams("Digital Canadian Dollar", "DCAD", 6, 1, 300_000 * (10**6));
//         allParams[6] = StablecoinDeploymentParams("Digital Australian Dollar", "DAUD", 6, 1, 200_000 * (10**6));
//         allParams[7] = StablecoinDeploymentParams("Test Stable A", "TSA", 18, 1, 1_000 * (10**18));
//         allParams[8] = StablecoinDeploymentParams("Test Stable B", "TSB", 8, 1, 5_000 * (10**8));
//         allParams[9] = StablecoinDeploymentParams("Unit Value Coin", "UVC", 1, 1, 1_000_000 * (10**1)); // 1M whole tokens, 1 decimal
//         // 1. Deploy the Stablecoins
//         vm.startBroadcast(deployer);
//         console.log("For Owner: %s", deployer);
//         for (uint i = 0; i < allParams.length; i++) {
//             StablecoinDeploymentParams memory params = allParams[i];
//             Stablecoin stablecoin = new Stablecoin(
//                 deployer, // initialOwner
//                 params.name,
//                 params.symbol,
//                 params.decimalsVal,
//                 params.assetValuePerUnit,
//                 params.initialSupply
//             );
//             stablecoins[i] = stablecoin;
//             console.log("Deployed %s (%s) at address: %s", params.name, params.symbol, address(stablecoin));
//         }
//         vm.stopBroadcast();
//         address assetManagerAddress = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
//         require(assetManagerAddress != address(0), "DeployAndRegisterSovereignBonds: ASSET_MANAGER_ADDRESS environment variable not set or is the zero address.");
//         uint256 rwaDeployer = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
//         // address rwaSigner = vm.addr(rwaDeployer);
//         RWA_Manager manager = RWA_Manager(assetManagerAddress);
//         // 2. Register the Stablecoins
//         vm.startBroadcast(rwaDeployer);
//         for (uint i = 0; i < allParams.length; i++) {
//             manager.registerAsset(stablecoins[i].name(), address(stablecoins[i]), "Cash");
//         }
//         console.log("Registered stable coins with manager at address: %s", assetManagerAddress);
//         vm.stopBroadcast();
//     }
// }