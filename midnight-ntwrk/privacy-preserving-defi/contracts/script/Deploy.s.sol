// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../MockUSDC.sol";
import "../DeFiVault.sol";
import "../ComplianceRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockUSDC
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        // Deploy ComplianceRegistry
        ComplianceRegistry compliance = new ComplianceRegistry();
        console.log("ComplianceRegistry deployed at:", address(compliance));

        // Deploy DeFiVault
        DeFiVault vault = new DeFiVault(address(usdc), address(compliance));
        console.log("DeFiVault deployed at:", address(vault));

        // Mint some USDC for testing
        usdc.mint(msg.sender, 1000000 * 10**6); // 1M USDC
        console.log("Minted 1M USDC to deployer");

        vm.stopBroadcast();

        // Save addresses to file
        string memory addresses = string(abi.encodePacked(
            "{\n",
            '  "mock_usdc": "', vm.toString(address(usdc)), '",\n',
            '  "defi_vault": "', vm.toString(address(vault)), '",\n',
            '  "compliance_registry": "', vm.toString(address(compliance)), '"\n',
            "}"
        ));
        
        vm.writeFile("./addresses.json", addresses);
        console.log("Contract addresses saved to addresses.json");
    }
}