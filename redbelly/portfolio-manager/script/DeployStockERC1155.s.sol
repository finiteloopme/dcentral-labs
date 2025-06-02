// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Script.sol";
// import "../src/StockERC1155.sol"; // Adjust path if your contract is elsewhere

// /**
//  * @title DeployStockERC1155
//  * @dev Foundry script to deploy the StockERC1155 contract.
//  *
//  * How to use:
//  * 1. Set environment variables for your private key and RPC URL if deploying to a live network:
//  * export PRIVATE_KEY=your_private_key
//  * export RPC_URL=your_rpc_url
//  *
//  * 2. Run the script:
//  * forge script script/DeployStockERC1155.s.sol:DeployStockERC1155 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
//  * (Add --etherscan-api-key YOUR_ETHERSCAN_KEY for verification on live networks)
//  *
//  * For local deployment (e.g., Anvil):
//  * forge script script/DeployStockERC1155.s.sol:DeployStockERC1155 --fork-url http://localhost:8545 --broadcast -vvvv
//  * (Ensure Anvil is running: anvil)
//  */
// contract DeployStockERC1155 is Script {

//     // --- Script Configuration ---
//     uint256 private constant STOCK_TOKEN_ID = 0;
//     string private constant STOCK_NAME = "Example Corp";
//     string private constant STOCK_SYMBOL = "EXMPL";
//     uint256 private constant INITIAL_SUPPLY = 1000000 * (10**18); // Example: 1 million shares with 18 decimals
//                                                                 // ERC1155 does not enforce decimals, but it's common to think in terms of them.
//                                                                 // For stocks, you might represent 1 share as 1 unit of the token.
//                                                                 // Let's use 1,000,000 units for 1 million shares.

//     address private initialOwner; // Address to receive the initial supply. Will be set to deployer.

//     function setUp() public virtual {
//         // In a real deployment, you might get this from env or config
//         // For this script, we'll use the deployer's address (msg.sender in run())
//     }

//     function run() public returns (StockERC1155 stockToken) {
//         // Get the deployer's private key from environment variable or use a default for local testing
//         // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         // If no private key is found, vm.envUint returns 0.
//         // For local anvil node, it often pre-funds accounts. We can use one of those.
//         // Or, if PRIVATE_KEY is set, vm.startBroadcast will use it.
//         // If not set, and deploying to anvil, it might pick one of anvil's default accounts.

//         // If deploying to a live network, ensure PRIVATE_KEY is set.
//         // For local testing, if PRIVATE_KEY is not set, Foundry's `vm.broadcast()`
//         // can use a default Anvil account if you are running against Anvil.
//         // Alternatively, explicitly define the deployer.
//         // address deployer = address(uint160(uint256(keccak256(abi.encodePacked("foundry_deployer"))))); // Example deterministic deployer
//         // For simplicity, we'll let initialOwner be the msg.sender of the transaction.
//         // When using `forge script`, `msg.sender` in `run()` is the address derived from `PRIVATE_KEY`
//         // or one of Anvil's default accounts if `PRIVATE_KEY` is not provided and running locally.

//         // vm.startBroadcast(deployerPrivateKey); // Use private key if provided, otherwise relies on Anvil/local setup
//         vm.startBroadcast();

//         // Set the initial owner to the address executing the script
//         initialOwner = msg.sender;
//         if (initialOwner == address(0)) {
//             // This can happen if PRIVATE_KEY is not set and not running in a context where msg.sender is defined (e.g. anvil without --sender)
//             // Default to a known Anvil address for local tests if needed, or make it configurable.
//             // For now, assume `msg.sender` will be correctly populated by `forge script` execution.
//             initialOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil default #0
//             console.log("Warning: msg.sender was address(0), defaulting initialOwner to Anvil account 0.");
//         }


//         console.log("Deploying StockERC1155 contract...");
//         console.log("Stock Name:", STOCK_NAME);
//         console.log("Stock Symbol:", STOCK_SYMBOL);
//         console.log("Initial Supply (units):", INITIAL_SUPPLY);
//         console.log("Initial Owner:", initialOwner);


//         stockToken = new StockERC1155(
//             STOCK_NAME,
//             STOCK_SYMBOL,
//             INITIAL_SUPPLY,
//             initialOwner,
//             uint256(100)
//         );

//         vm.stopBroadcast();

//         console.log("StockERC1155 deployed successfully!");
//         console.log("Contract Address:", address(stockToken));
//         console.log("Stock Name:", stockToken.stockName());
//         console.log("Stock Symbol:", stockToken.stockSymbol());
//         console.log("Total Supply:", stockToken.totalSupply());
//         console.log("Balance of Initial Owner (%s): %s shares", initialOwner, stockToken.balanceOf(initialOwner, STOCK_TOKEN_ID));

//         return stockToken;
//     }
// }
