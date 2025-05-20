// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RWAAssetManager.sol"; // Adjust path if your contract is in a different directory

/**
 * @title DeployRWAAssetManager
 * @author Gemini
 * @notice Script to deploy the RWAAssetManager contract.
 */
contract DeployRWAAssetManager is Script {
    /**
     * @notice Main function to run the deployment script.
     * @return managerAddress The address of the deployed RWAAssetManager contract.
     */
    function run() external returns (address managerAddress) {
        // Retrieve the deployer's private key from environment variables
        // or use a local anvil/testnet deployer key.
        // For local testing with Anvil, Anvil often provides default private keys.
        // For real deployments, ensure this is handled securely (e.g., via environment variables or hardware wallet).
        // TODO: handle this gracefully
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // if (deployerPrivateKey == 0) {
        //     // Fallback to a default Anvil private key if PRIVATE_KEY is not set
        //     // This is one of the default private keys Anvil provides on startup.
        //     // DO NOT USE THIS KEY FOR MAINNET DEPLOYMENTS.
        //     deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // }
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions. All subsequent state-changing calls will be sent to the network.
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the RWAAssetManager contract, passing the deployer's address as the initial owner.
        RWAAssetManager rwaManager = new RWAAssetManager(deployerAddress);
        managerAddress = address(rwaManager);

        // Stop broadcasting.
        vm.stopBroadcast();

        console.log("RWAAssetManager deployed by:", deployerAddress);
        console.log("RWAAssetManager contract address:", managerAddress);

        return managerAddress;
    }
}
