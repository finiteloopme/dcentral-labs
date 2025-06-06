// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/StockRWA.sol";
import "../src/RWA_Manager.sol";

contract DeployStocks is Script {
    StockAsset stockAssetContract;
    RWA_Manager rwaManagerContract;

    // Helper struct to keep track of created stock details
    struct StockDetails {
        string name;
        string symbol;
        uint256 internalId; // The ID returned by StockAsset.createStock
    }

    StockDetails[] public createdStocks;

    // Realistic stock data
    string[] stockNames = [
        "Apple Inc.", "Microsoft Corp.", "Amazon.com Inc.", "Alphabet Inc. (Class A)", "Tesla Inc.",
        "NVIDIA Corporation", "Meta Platforms Inc.", "Berkshire Hathaway Inc. (Class B)", "Johnson & Johnson", "Visa Inc."
    ];
    string[] stockSymbols = [
        "AAPL", "MSFT", "AMZN", "GOOGL", "TSLA",
        "NVDA", "META", "BRK.B", "JNJ", "V"
    ];
    // For simplicity, we'll use a base price and increment it.
    // In a real scenario, these would be fetched or defined more accurately.
    uint256 basePrice = 1 * 1 ether; // e.g., $1

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // require(deployerPrivateKey != 0, "PRIVATE_KEY environment variable not set.");
        // vm.startBroadcast(deployerPrivateKey);

        address deployer = msg.sender;
        vm.startBroadcast(deployer);

        // 1. StockAsset contract
        address stockAssetContractAddress = 0x663F3ad617193148711d28f5334eE4Ed07016602;
        stockAssetContract = StockAsset(stockAssetContractAddress);
        console.log("Using StockAsset contract deployed at:", address(stockAssetContract));

        // 2. Create 10 distinct stocks in StockAsset
        console.log("Creating 10 stocks in StockAsset...");
        require(stockNames.length == 10 && stockSymbols.length == 10, "Need 10 stock names and symbols.");

        for (uint256 i = 0; i < stockNames.length; i++) {
            string memory stockName = stockNames[i];
            string memory stockSymbol = stockSymbols[i];
            // Using arbitrary values for price and supply
            uint256 initialBuyPrice = basePrice + (i * 2 * 1 ether); // Increment price slightly for each stock
            uint256 initialSellPrice = initialBuyPrice - (1 * 1 ether); // Sell price slightly lower than buy
            uint256 initialTotalSupply = (1000000 + (i * 100000));    // Number of shares/tokens

            uint256 internalStockId = stockAssetContract.createStock(
                stockName,
                stockSymbol,
                initialBuyPrice,
                initialSellPrice,
                initialTotalSupply
            );

            createdStocks.push(StockDetails({
                name: stockName,
                symbol: stockSymbol,
                internalId: internalStockId
            }));
            console.log(" - Created: %s (%s) with internal ID: %s", stockName, stockSymbol, internalStockId);
        }

        // 3. Deploy RWA_Manager contract
        // string memory managerName = "Global RWA Portfolio Manager";
        // rwaManagerContract = new RWA_Manager(managerName);
        address assetManagerAddress = 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
        require(assetManagerAddress != address(0), "DeployStocks: ASSET_MANAGER_ADDRESS environment variable not set or is the zero address.");
        // uint256 rwaDeployer = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // address rwaSigner = vm.addr(rwaDeployer);
        rwaManagerContract = RWA_Manager(assetManagerAddress);
        console.log("RWA_Manager contract deployed at:", address(rwaManagerContract));
        console.log("RWA_Manager name set to:", rwaManagerContract.name());

        // 4. Register each stock in RWA_Manager
        // The `contractAddress` for RWA_Manager will be the StockAsset contract for all these stocks.
        // The `assetName` will be the specific stock's name.
        console.log("Registering stocks in RWA_Manager...");
        for (uint8 i = 0; i < createdStocks.length; i++) {
            StockDetails memory stockInfo = createdStocks[i];
            string memory category = "Public Equity"; // Example category

            uint256 rwaManagerAssetId = rwaManagerContract.registerAsset(
                stockInfo.name,             // Specific name of the stock, e.g., "Tokenized Stock 1"
                address(stockAssetContract),// Address of the single StockAsset contract
                category
            );
            console.log(" - Registered in RWA_Manager: %s | Asset ID: %s | Category: %s", stockInfo.name, rwaManagerAssetId, category);
        }

        vm.stopBroadcast();
    }
}