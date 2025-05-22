// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RWA_Manager
 * @author Gemini
 * @notice This contract manages a catalog of Real World Assets (RWAs),
 * where each asset is represented by a smart contract address and has a category.
 * The owner of this contract (as defined by OpenZeppelin's Ownable) can register
 * new assets, list all registered assets, and delete assets from the catalog.
 */
contract RWA_Manager is Ownable {
    /**
     * @notice Represents a registered Real World Asset.
     * @param contractAddress The address of the smart contract representing the RWA.
     * @param category A string describing the category of the RWA (e.g., "Real Estate", "Art", "Bonds").
     */
    struct Asset {
        address contractAddress;
        string category;
    }

    // The 'owner' variable and 'onlyOwner' modifier are inherited from Ownable.sol

    /// @notice An array storing all registered assets.
    string public name;

    /// @notice An array storing all registered assets.
    Asset[] public assets;

    /// @notice Mapping from an asset's contract address to its index (plus 1) in the `assets` array.
    /// @dev We store index + 1 to distinguish between a non-existent asset (value 0) and an asset at index 0.
    mapping(address => uint256) public assetIndex;

    /// @notice Emitted when a new asset is successfully registered.
    /// @param assetContract The address of the registered asset contract.
    /// @param category The category of the registered asset.
    /// @param registrar The address that performed the registration (the owner).
    event AssetRegistered(address indexed assetContract, string category, address indexed registrar);

    /// @notice Emitted when an asset is successfully deleted.
    /// @param assetContract The address of the deleted asset contract.
    /// @param remover The address that performed the deletion (the owner).
    event AssetDeleted(address indexed assetContract, address indexed remover);

    /**
     * @notice Sets the deployer of the contract as the owner.
     * @param _name The name of the RWA Manager.
     * @dev The Ownable constructor handles setting the initial owner to msg.sender.
     * The initialOwner parameter for Ownable (Solidity 0.8.20+) is used here.
     */
    constructor(string memory _name) Ownable(msg.sender) {
        // The owner is set by the Ownable constructor.
        name = _name;
        // No need for: owner = msg.sender;
    }

    // The custom onlyOwner modifier is removed as we use the one from Ownable.sol

    /**
     * @notice Registers a new RWA smart contract.
     * @dev Only the owner can call this function (enforced by Ownable's onlyOwner modifier).
     * The asset contract address must not be the zero address.
     * The asset contract must not already be registered.
     * @param _assetContract The address of the RWA's smart contract.
     * @param _category The category of the RWA.
     */
    function registerAsset(address _assetContract, string calldata _category) external onlyOwner {
        require(_assetContract != address(0), "RWA_Manager: Asset contract address cannot be zero");
        require(assetIndex[_assetContract] == 0, "RWA_Manager: Asset already registered");
        require(bytes(_category).length > 0, "RWA_Manager: Category cannot be empty");

        assets.push(Asset({contractAddress: _assetContract, category: _category}));
        assetIndex[_assetContract] = assets.length; // Store index + 1

        emit AssetRegistered(_assetContract, _category, msg.sender);
    }

    /**
     * @notice Deletes an RWA from the catalog.
     * @dev Only the owner can call this function (enforced by Ownable's onlyOwner modifier).
     * The asset contract must be already registered.
     * Uses the "swap and pop" method for efficient array element removal.
     * @param _assetContract The address of the RWA's smart contract to delete.
     */
    function deleteAsset(address _assetContract) external onlyOwner {
        require(assetIndex[_assetContract] != 0, "RWA_Manager: Asset not found");

        uint256 indexToRemove = assetIndex[_assetContract] - 1; // Convert to 0-based index
        uint256 lastIndex = assets.length - 1;

        if (indexToRemove != lastIndex) {
            // If the asset to remove is not the last one, swap it with the last one
            Asset memory lastAsset = assets[lastIndex];
            assets[indexToRemove] = lastAsset;
            assetIndex[lastAsset.contractAddress] = indexToRemove + 1; // Update index of the moved asset
        }

        // Remove the last element (either the original last or the one swapped into place)
        assets.pop();
        // Clear the index mapping for the removed asset
        delete assetIndex[_assetContract];

        emit AssetDeleted(_assetContract, msg.sender);
    }

    /**
     * @notice Retrieves all registered RWAs.
     * @return An array of Asset structs, each containing the contract address and category.
     */
    function getAllAssets() external view returns (Asset[] memory) {
        return assets;
    }

    /**
     * @notice Retrieves the details of a specific RWA.
     * @param _assetContract The address of the RWA's smart contract.
     * @return contractAddress_ The address of the asset contract.
     * @return category_ The category of the asset.
     */
    function getAssetDetails(address _assetContract) external view returns (address contractAddress_, string memory category_) {
        require(assetIndex[_assetContract] != 0, "RWA_Manager: Asset not found");
        uint256 index = assetIndex[_assetContract] - 1;
        Asset memory asset = assets[index];
        return (asset.contractAddress, asset.category);
    }

    /**
     * @notice Gets the current count of registered assets.
     * @return The total number of registered assets.
     */
    function getAssetCount() external view returns (uint256) {
        return assets.length;
    }

    /**
     * @notice Returns the address of the current owner.
     * @dev This function is inherited from Ownable.sol.
     * This is just an explicit declaration for clarity if needed, but not strictly necessary
     * as `owner()` is already public in Ownable.
     */
    // function owner() public view virtual override returns (address) {
    //     return super.owner();
    // }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev Can only be called by the current owner. This function is inherited from Ownable.sol.
     */
    // function transferOwnership(address newOwner) public virtual override onlyOwner {
    //     super.transferOwnership(newOwner);
    // }

    /**
     * @notice Renounces ownership of the contract.
     * @dev Can only be called by the current owner.
     * Leaves the contract without an owner, thereby removing any functionality that is only available to the owner.
     * This function is inherited from Ownable.sol.
     */
    // function renounceOwnership() public virtual override onlyOwner {
    //     super.renounceOwnership();
    // }
}
