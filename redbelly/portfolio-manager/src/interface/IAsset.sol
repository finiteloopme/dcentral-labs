// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IAsset Interface
 * @dev Interface for managing assets, including issuing, buying, and selling.
 */
interface IAsset {
    event AssetIssued(
        uint256 indexed assetId,
        address indexed to,
        uint256 totalSupply,
        uint256 initialPrice,
        string name,
        string symbol,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an asset is bought.
     * @param assetId The ID of the asset.
     * @param buyer The address of the buyer.
     * @param tokenCount The amount of tokens bought.
     * @param price The price at which the tokens were bought.
     * @param name The name of the asset.
     * @param timestamp The timestamp of the transaction.
     */
    event AssetBought(
        uint256 indexed assetId,
        address indexed buyer,
        uint256 tokenCount,
        uint256 price,
        string name,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an asset is sold.
     * @param assetId The ID of the asset.
     * @param seller The address of the seller.
     * @param tokenCount The amount of tokens sold.
     * @param price The price at which the tokens were sold.
     * @param name The name of the asset.
     * @param timestamp The timestamp of the transaction.
     */
    event AssetSold(
        uint256 indexed assetId,
        address indexed seller,
        uint256 tokenCount,
        uint256 price,
        string name,
        uint256 timestamp
    );

    /**
     * @dev Gets the current buy price for a given asset.
     * @param id The ID of the asset.
     * @return The buy price of the asset.
     */
    function getBuyPrice(uint256 id) external view returns (uint256);

    /**
     * @dev Gets the current sell price for a given asset.
     * @param id The ID of the asset.
     * @return The sell price of the asset.
     */
    function getSellPrice(uint256 id) external view returns (uint256);

    /**
     * @dev Gets all asset IDs owned by a specific user.
     * @param user The address of the user.
     * @return An array of asset IDs owned by the user.
     */
    function getUserAssetIds(
        address user
    ) external view returns (uint256[] memory);

    /**
     * @dev Gets all asset IDs currently in existence.
     * @return An array of all asset IDs.
     */
    function getAllAssetIds() external view returns (uint256[] memory);

    /**
     * @dev Gets the total supply of a specific asset.
     * @param id The ID of the asset.
     * @return The total supply of the asset.
     */
    function assetTotalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Gets the name of a specific asset.
     * @param id The ID of the asset.
     * @return The name of the asset.
     */
    function assetName(uint256 id) external view returns (string memory);

    /**
     * @dev Gets the symbol of a specific asset.
     * @param id The ID of the asset.
     * @return The symbol of the asset.
     */
    function assetSymbol(uint256 id) external view returns (string memory);

    /**
     * @dev Buys a specified amount of an asset.
     * @param id The ID of the asset to buy.
     * @param tokenCount The amount of tokens to buy.
     * @notice The caller must have approved the contract to spend the required amount of the payment currency.
     */
    function buyAsset(uint256 id, uint256 tokenCount) external payable;

    /**
     * @dev Sells a specified amount of an asset.
     * @param id The ID of the asset to sell.
     * @param tokenCount The amount of tokens to sell.
     * @notice The caller must have approved the contract to spend the specified amount of the asset.
     */
    function sellAsset(uint256 id, uint256 tokenCount) external;
}