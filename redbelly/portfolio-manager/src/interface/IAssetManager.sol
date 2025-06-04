// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AssetManager
/// @dev Interface for an asset manager.
interface IAssetManager {

    /// @dev Struct representing the details of a registered asset.
    struct Asset {
        string name;
        uint256 assetId;
        address contractAddress;
        string category;
    }

    /// @dev Enum representing the risk profile of a user's portfolio.
    enum RiskProfile {
        LOW,
        MEDIUM,
        HIGH
    }
    /// @dev Struct representing the total value of assets per category in a portfolio.
    struct CategoryValue {
        string category;
        uint256 totalValue;
    }

    /// @dev Struct representing the details of a user's portfolio.
    struct Portfolio {
        mapping(uint256 => uint256) assets; // Mapping of asset ID to quantity
        RiskProfile userRiskProfile; // Selected by the user 
        uint256 currentValue; // Calculated auto by the asset manager
        uint256 lastUpdated; // Timestamp of the last update by asset manager
        RiskProfile riskAnalysis; // Calculated auto by the asset manager
        mapping(string => CategoryValue) categoryValues; // Calculated auto by the asset manager
    }

    /// @dev Returns the name of the asset manager.
    function name() external view returns (string memory);

    /// @dev Returns the details of a registered asset by its ID.
    /// @param assetId The ID of the asset.
    /// @return The Asset struct containing the asset details.
    function getAsset(uint256 assetId) external view returns (Asset memory);

    /// @dev Returns the portfolio details for a given user.
    /// @param user The address of the user.
    function getPortfolio(address user) external view returns (
        uint256[] memory assetIds, 
        uint256[] memory quantities, 
        RiskProfile userRiskProfile, 
        uint256 currentValue, 
        uint256 lastUpdated, 
        RiskProfile riskAnalysis,
        CategoryValue[] memory categoryValues); 

    /// @dev Registers a new asset with the asset manager.
    /// @param name The name of the asset.
    /// @param contractAddress The contract address of the asset.
    /// @param category The category of the asset.
    /// @return The ID of the newly registered asset.
    function registerAsset(string memory name, address contractAddress, string memory category) external returns (uint256);

    /// @dev Creates a new portfolio for a user.
    /// @param riskProfile The initial risk profile for the portfolio.
    function createPortfolio(RiskProfile riskProfile) external;

    /// @dev Returns all registered assets.
    /// @return An array of Asset structs containing details of all registered assets.
    function getAllAssets() external view returns (Asset[] memory);

    /// @dev Updates the portfolio for a user with externally provided data.
    /// This function is used when an external application has calculated
    /// the new portfolio value, risk analysis, and category values.
    /// the new asset holdings, portfolio value, risk analysis, and category values.
    /// The asset manager will update these fields and the lastUpdated timestamp.
    /// @param user The address of the user whose portfolio is being updated.
    /// @param newAssetIds An array of asset IDs representing the user's new holdings.
    /// @param newQuantities An array of quantities corresponding to each asset ID in newAssetIds.
    /// @param newCurrentValue The new current value of the portfolio.
    /// @param newRiskAnalysis The new risk analysis of the portfolio.
    /// @param newCategoryValues An array of CategoryValue structs representing the new total values per category.
    function refreshPortfolio(
        address user,
        uint256[] memory newAssetIds,
        uint256[] memory newQuantities,
        uint256 newCurrentValue,
        RiskProfile newRiskAnalysis,
        CategoryValue[] memory newCategoryValues
    ) external;
    
    /// @dev Emitted when a user's portfolio is updated.
    /// @param user The address of the user whose portfolio was updated.
    /// @param currentValue The new current value of the portfolio.
    /// @param riskAnalysis The new risk analysis of the portfolio.
    event PortfolioUpdated(address indexed user, uint256 currentValue, RiskProfile riskAnalysis);

    /// @dev Emitted when a new asset is registered.
    /// @param assetId The ID of the newly registered asset.
    /// @param name The name of the registered asset.
    /// @param contractAddress The contract address of the registered asset.
    event AssetRegistered(uint256 indexed assetId, string name, address contractAddress);
}