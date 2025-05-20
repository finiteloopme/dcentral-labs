// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for robust ownership management

/**
 * @title RWAAssetManager
 * @author Gemini
 * @notice This contract manages a list of smart contract addresses representing Real World Assets (RWAs).
 * It allows the owner to register new asset contracts, list all registered assets, and delete assets.
 * This contract is Ownable, meaning only the deployer (owner) can perform administrative actions.
 */
contract RWAAssetManager is Ownable {
    // --- State Variables ---

    // Array to store the addresses of the registered RWA contracts.
    address[] private registeredAssets;

    // Mapping to store the index of each asset in the `registeredAssets` array.
    // The index is stored as `actualIndex + 1` to differentiate non-existent assets (default value 0)
    // from an asset at index 0.
    mapping(address => uint256) private assetIndexes;

    // Mapping to quickly check if an asset address is currently registered.
    mapping(address => bool) private isAssetRegistered;

    // --- Events ---

    /**
     * @notice Emitted when a new asset contract is registered.
     * @param assetContract The address of the registered RWA contract.
     * @param registeredBy The address of the account (owner) that registered the asset.
     */
    event AssetRegistered(address indexed assetContract, address indexed registeredBy);

    /**
     * @notice Emitted when an asset contract is deleted from the registry.
     * @param assetContract The address of the RWA contract being deleted.
     * @param deletedBy The address of the account (owner) that deleted the asset.
     */
    event AssetDeleted(address indexed assetContract, address indexed deletedBy);

    // --- Constructor ---

    /**
     * @notice Sets the initial owner of the contract.
     * @param initialOwner The address of the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // The Ownable constructor sets the owner.
        // No further initialization needed here.
    }

    // --- Functions ---

    /**
     * @notice Registers a new RWA smart contract address.
     * @dev Only the contract owner can call this function.
     * The asset contract address cannot be the zero address.
     * The asset contract cannot already be registered.
     * @param _assetContract The address of the RWA smart contract to register.
     */
    function registerAsset(address _assetContract) external onlyOwner {
        // Input validation: ensure the asset contract address is not the zero address.
        require(_assetContract != address(0), "RWAAssetManager: Asset contract cannot be zero address");
        // Input validation: ensure the asset is not already registered.
        require(!isAssetRegistered[_assetContract], "RWAAssetManager: Asset already registered");

        // Add the asset to the array of registered assets.
        registeredAssets.push(_assetContract);
        // Store the index (plus 1) of the newly added asset.
        assetIndexes[_assetContract] = registeredAssets.length; // length is 1-based, perfect for index+1
        // Mark the asset as registered.
        isAssetRegistered[_assetContract] = true;

        // Emit an event to log the registration.
        emit AssetRegistered(_assetContract, msg.sender);
    }

    /**
     * @notice Deletes an RWA smart contract address from the registry.
     * @dev Only the contract owner can call this function.
     * The asset contract must be currently registered.
     * This function uses the "swap and pop" method for efficient deletion from the array.
     * @param _assetContract The address of the RWA smart contract to delete.
     */
    function deleteAsset(address _assetContract) external onlyOwner {
        // Input validation: ensure the asset is actually registered.
        require(isAssetRegistered[_assetContract], "RWAAssetManager: Asset not registered");

        // Retrieve the index of the asset to be deleted.
        // Subtract 1 because assetIndexes stores index + 1.
        uint256 assetToRemoveIndex = assetIndexes[_assetContract] - 1;

        // If the asset to delete is not the last asset in the array,
        // move the last asset into the position of the asset to be deleted.
        if (assetToRemoveIndex < registeredAssets.length - 1) {
            address lastAsset = registeredAssets[registeredAssets.length - 1];
            registeredAssets[assetToRemoveIndex] = lastAsset;
            // Update the index of the moved asset.
            assetIndexes[lastAsset] = assetToRemoveIndex + 1;
        }

        // Remove the last element from the array (either the original last or the one we just moved).
        registeredAssets.pop();

        // Clean up storage for the deleted asset.
        delete assetIndexes[_assetContract]; // Sets to 0
        delete isAssetRegistered[_assetContract]; // Sets to false

        // Emit an event to log the deletion.
        emit AssetDeleted(_assetContract, msg.sender);
    }

    /**
     * @notice Lists all currently registered RWA smart contract addresses.
     * @return address[] An array of registered asset contract addresses.
     */
    function listRegisteredAssets() external view returns (address[] memory) {
        return registeredAssets;
    }

    /**
     * @notice Checks if a given address is a registered RWA smart contract.
     * @param _assetContract The address to check.
     * @return bool True if the address is registered, false otherwise.
     */
    function isAsset(address _assetContract) external view returns (bool) {
        return isAssetRegistered[_assetContract];
    }

    /**
     * @notice Returns the number of registered assets.
     * @return uint256 The count of registered assets.
     */
    function getRegisteredAssetsCount() external view returns (uint256) {
        return registeredAssets.length;
    }
}
