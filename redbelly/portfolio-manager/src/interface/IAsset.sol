// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IAsset Interface
 * @dev Interface for managing financial assets.
 */
interface IAsset {
    /// @notice Emitted when a new asset is issued.
    event AssetIssued(
        uint256 indexed assetId,
        address indexed to,
        uint256 totalSupply,
        uint256 initialPrice,
        string name,
        string symbol,
        uint256 timestamp
    );

    /// @notice Emitted when an asset is bought.
    event AssetBought(
        uint256 indexed assetId,
        address indexed buyer,
        uint256 tokenCount,
        uint256 price,
        string name,
        uint256 timestamp
    );

    /// @notice Emitted when an asset is sold.
    event AssetSold(
        uint256 indexed assetId,
        address indexed seller,
        uint256 tokenCount,
        uint256 price,
        string name,
        uint256 timestamp
    );

    /**
     * @notice Gets the current buy price of an asset.
     * @param id The ID of the asset.
     * @return The buy price of the asset.
     */
    function getBuyPrice(uint256 id) external view returns (uint256);

    /**
     * @notice Gets the current sell price of an asset.
     * @param id The ID of the asset.
     * @return The sell price of the asset.
     */
    function getSellPrice(uint256 id) external view returns (uint256);

    /**
     * @notice Gets all asset IDs.
     * @return An array of all asset IDs.
     */
    function getAllAssetIds() external view returns (uint256[] memory);

    /**
     * @notice Gets the total supply of an asset.
     * @param id The ID of the asset.
     * @return The total supply of the asset.
     */
    function assetTotalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Gets the name of an asset.
     * @param id The ID of the asset.
     * @return The name of the asset.
     */
    function assetName(uint256 id) external view returns (string memory);

    /**
     * @notice Gets the symbol of an asset.
     * @param id The ID of the asset.
     * @return The symbol of the asset.
     */
    function assetSymbol(uint256 id) external view returns (string memory);

    /**
     * @notice Allows a user to buy an asset.
     * @param _id The ID of the asset to buy.
     */
    function buy(uint256 _id) external payable;

    /**
     * @notice Allows a user to sell an asset.
     * @param _id The ID of the asset to sell.
     */
    function sell(uint256 _id) external payable;
}