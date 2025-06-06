// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/StockRWA.sol";

contract DeployStockContract is Script {
    StockAsset stockAssetContract;

    function run() external {

        address deployer = msg.sender;
        vm.startBroadcast(deployer);

        // 1. Deploy StockAsset contract
        stockAssetContract = new StockAsset(deployer);
        console.log("StockAsset contract deployed at:", address(stockAssetContract));

        vm.stopBroadcast();
    }
}