// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IAssetManager.sol"; // Make sure IAssetManager.sol is in the same directory or provide the correct path

/// @title RWA_Manager
/// @notice Implementation of the IAssetManager interface for managing Real World Assets.
/// @dev This contract allows for registration of assets and management of user portfolios.
/// It stores asset details and portfolio compositions, providing views for querying this data.
/// The actual calculation of portfolio values, risk analysis, and updates to category values
/// are assumed to be handled by other mechanisms or off-chain processes, which would then
/// call appropriate functions to update the state and emit events.
contract RWA_Manager is IAssetManager {

    // --- State Variables ---

    /// @notice The publicly visible name of this asset manager.
    string public managerName;

    /// @dev Array storing all registered assets. Primarily used for the getAllAssets() function.
    Asset[] internal _registeredAssetsArray;

    /// @dev Mapping from an asset ID to its Asset struct. Asset IDs start from 1.
    /// An ID of 0 is considered invalid or non-existent.
    mapping(uint256 => Asset) internal _assetsById;

    /// @dev Counter to generate unique asset IDs for newly registered assets. Starts at 1.
    uint256 internal _nextAssetId;

    /// @dev Internal struct to store detailed portfolio data for a user.
    /// This is the actual storage representation. The IAssetManager.Portfolio struct
    /// serves more as a conceptual model and a structure for return types.
    struct PortfolioStorage {
        mapping(uint256 => uint256) assetQuantities; // Mapping of asset ID to quantity owned
        RiskProfile userRiskProfile;                 // User-selected risk profile
        uint256 currentValue;                        // Auto-calculated by manager (e.g., via oracle prices)
        uint256 lastUpdated;                         // Timestamp of last auto-update by manager
        RiskProfile riskAnalysis;                    // Auto-calculated by manager (e.g., based on diversification)
        mapping(string => uint256) categoryTotalValues; // Auto-calculated: category name => total value in portfolio

        // Helper arrays to efficiently construct the return value for getPortfolio.
        // These arrays are assumed to be maintained by functions that add/remove assets
        // from the portfolio (which are not part of the IAssetManager interface itself).
        uint256[] ownedAssetIds;    // List of asset IDs currently held in the portfolio
        string[] activeCategories;  // List of category names that have a non-zero value in the portfolio
    }

    /// @dev Mapping from a user's address to their portfolio data.
    mapping(address => PortfolioStorage) internal _userPortfolios;

    // --- Constructor ---

    /// @dev Initializes the RWA_Manager contract with a specific name.
    /// @param initialName The desired name for this asset manager (e.g., "Redbelly RWA Portfolio Manager").
    constructor(string memory initialName) {
        require(bytes(initialName).length > 0, "RWA_Manager: Name cannot be empty");
        managerName = initialName;
        _nextAssetId = 1; // Asset IDs will start from 1.
    }

    // --- IAssetManager External View Functions ---

    /// @inheritdoc IAssetManager
    function name() external view virtual override returns (string memory) {
        return managerName;
    }

    /// @inheritdoc IAssetManager
    function getAsset(uint256 assetId) external view virtual override returns (Asset memory) {
        require(assetId > 0 && assetId < _nextAssetId, "RWA_Manager: Invalid asset ID or asset not yet registered");
        // Additional check to ensure the asset at this ID actually has data,
        // though the _nextAssetId check largely covers registration.
        require(_assetsById[assetId].contractAddress != address(0), "RWA_Manager: Asset data not found for ID");
        return _assetsById[assetId];
    }

    /// @inheritdoc IAssetManager
    function getAllAssets() external view virtual override returns (Asset[] memory) {
        return _registeredAssetsArray;
    }

    /// @inheritdoc IAssetManager
    function getPortfolio(address user) external view virtual override returns (
        uint256[] memory assetIds,
        uint256[] memory quantities,
        RiskProfile userRiskProfile,
        uint256 currentValue,
        uint256 lastUpdated,
        RiskProfile riskAnalysis,
        CategoryValue[] memory categoryValuesReturn
    ) {
        PortfolioStorage storage portfolio = _userPortfolios[user];

        // If a user has no portfolio (e.g., createPortfolio was never called for them,
        // or their portfolio is genuinely empty), this will return default/zero values
        // for value types and empty arrays for dynamic arrays. This is standard behavior.

        uint256 numOwnedAssets = portfolio.ownedAssetIds.length;
        assetIds = new uint256[](numOwnedAssets);
        quantities = new uint256[](numOwnedAssets);

        for (uint256 i = 0; i < numOwnedAssets; i++) {
            uint256 id = portfolio.ownedAssetIds[i];
            assetIds[i] = id;
            quantities[i] = portfolio.assetQuantities[id]; // Assumes assetQuantities[id] is populated
        }

        uint256 numActiveCategories = portfolio.activeCategories.length;
        categoryValuesReturn = new CategoryValue[](numActiveCategories);
        for (uint256 i = 0; i < numActiveCategories; i++) {
            string memory categoryName = portfolio.activeCategories[i];
            categoryValuesReturn[i] = CategoryValue({
                category: categoryName,
                totalValue: portfolio.categoryTotalValues[categoryName] // Assumes categoryTotalValues[categoryName] is populated
            });
        }

        userRiskProfile = portfolio.userRiskProfile;
        currentValue = portfolio.currentValue;
        lastUpdated = portfolio.lastUpdated;
        riskAnalysis = portfolio.riskAnalysis;

        return (
            assetIds,
            quantities,
            userRiskProfile,
            currentValue,
            lastUpdated,
            riskAnalysis,
            categoryValuesReturn
        );
    }

    // --- IAssetManager External State-Modifying Functions ---

    /// @inheritdoc IAssetManager
    /// @dev In a production system, this function should be restricted (e.g., onlyOwner or role-based access).
    function registerAsset(
        string memory assetName,
        address contractAddress,
        string memory category
    ) external virtual override returns (uint256) {
        // Access Control: Consider adding `onlyOwner` or a similar modifier.
        require(bytes(assetName).length > 0, "RWA_Manager: Asset name cannot be empty");
        require(contractAddress != address(0), "RWA_Manager: Contract address cannot be the zero address");
        require(bytes(category).length > 0, "RWA_Manager: Category cannot be empty");

        uint256 newAssetId = _nextAssetId;

        // Ensure we don't overflow _nextAssetId, though extremely unlikely with uint256.
        require(newAssetId > 0, "RWA_Manager: Asset ID overflow (highly unlikely)");

        Asset memory newAsset = Asset({
            name: assetName,
            contractAddress: contractAddress,
            category: category
        });

        _assetsById[newAssetId] = newAsset;
        _registeredAssetsArray.push(newAsset); // Stores a copy of the Asset struct.

        _nextAssetId++;

        // As per IAssetManager.sol, the AssetRegistered event does not include the category.
        emit AssetRegistered(newAssetId, assetName, contractAddress);
        return newAssetId;
    }

    /// @inheritdoc IAssetManager
    function createPortfolio(RiskProfile riskProfile) external virtual override {
        address user = msg.sender;
        PortfolioStorage storage portfolio = _userPortfolios[user];

        // This function sets or updates the user's chosen risk profile.
        // If the portfolio is new, other fields (currentValue, lastUpdated, riskAnalysis,
        // assetQuantities, categoryTotalValues, ownedAssetIds, activeCategories)
        // will remain at their default (zero/empty) values until updated by other
        // processes (e.g., asset deposits, periodic re-evaluations by the manager).
        portfolio.userRiskProfile = riskProfile;

        // The PortfolioUpdated event is specifically for when currentValue and riskAnalysis change.
        // Since createPortfolio only sets the user's preference and doesn't perform these
        // calculations, the event is not emitted here. It would be emitted by whatever
        // mechanism updates those calculated values.
    }

    /// @inheritdoc IAssetManager
    /// @dev In a production system, this function should be restricted (e.g., onlyOwner, role-based access, or specific authorized updater contract).
    function refreshPortfolio(
        address user,
        uint256[] memory newAssetIds,
        uint256[] memory newQuantities,
        uint256 newCurrentValue,
        RiskProfile newRiskAnalysis,
        CategoryValue[] memory newCategoryValues
    ) external virtual override {
        // Access Control: CRITICAL - This function should be heavily restricted.
        // For example, add `onlyOwner` or a role-based access control modifier.
        // As it's implemented now, anyone can call it to change any user's portfolio.

        require(newAssetIds.length == newQuantities.length, "RWA_Manager: Asset IDs and quantities length mismatch");

        PortfolioStorage storage portfolio = _userPortfolios[user];

        // Clear existing dynamic portfolio data before repopulating
        // Note: This clears the mappings and arrays. If an asset ID from newAssetIds
        // was previously in assetQuantities but is not in newAssetIds, its quantity will become 0.
        // For ownedAssetIds and activeCategories, we are rebuilding them from scratch.

        // Clear and rebuild asset holdings
        // First, clear old quantities for assets that might be removed.
        // A more gas-efficient way for assetQuantities might be to iterate newAssetIds and update,
        // then iterate old ownedAssetIds to zero out any not in newAssetIds.
        // However, for simplicity and given this is an external "full refresh", clearing and repopulating is straightforward.
        for (uint i = 0; i < portfolio.ownedAssetIds.length; i++) {
            delete portfolio.assetQuantities[portfolio.ownedAssetIds[i]];
        }
        delete portfolio.ownedAssetIds; // Deletes the array elements, sets length to 0

        portfolio.ownedAssetIds = newAssetIds; // Assign the new array of asset IDs
        for (uint256 i = 0; i < newAssetIds.length; i++) {
            portfolio.assetQuantities[newAssetIds[i]] = newQuantities[i];
        }

        // Clear and rebuild category values
        for (uint i = 0; i < portfolio.activeCategories.length; i++) {
            delete portfolio.categoryTotalValues[portfolio.activeCategories[i]];
        }
        delete portfolio.activeCategories; // Deletes the array elements, sets length to 0
        
        portfolio.activeCategories = new string[](newCategoryValues.length);
        for (uint256 i = 0; i < newCategoryValues.length; i++) {
            portfolio.categoryTotalValues[newCategoryValues[i].category] = newCategoryValues[i].totalValue;
            portfolio.activeCategories[i] = newCategoryValues[i].category;
        }

        // Update portfolio summary figures
        portfolio.currentValue = newCurrentValue;
        portfolio.riskAnalysis = newRiskAnalysis;
        portfolio.lastUpdated = block.timestamp;

        emit PortfolioUpdated(user, newCurrentValue, newRiskAnalysis);
    }

}