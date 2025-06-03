// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/IAsset.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title StockAsset
/// @notice Represents real-world stock assets on the blockchain as ERC1155 tokens.
/// @dev Implements the IAsset interface for compatibility with portfolio managers.
/// This contract can manage multiple stock types.
contract StockAsset is IAsset, ERC1155, Ownable {
    struct StockData {
        string name;
        string symbol;
        uint256 buyPrice;  // Conceptual buy price, not enforced by ERC1155 transfer
        uint256 sellPrice; // Conceptual sell price, not enforced by ERC1155 transfer
        uint256 currentTotalSupply; // Tracks the total minted supply for this stock type
        bool exists; // To check if a stock ID is valid
    }

    mapping(uint256 => StockData) private _stocks;
    uint256 private _nextStockId; // Also serves as the ERC1155 token ID

    /// @notice Emitted when the price of the asset is updated.
    /// @param id The ID of the asset.
    /// @param newBuyPrice The new buy price.
    /// @param newSellPrice The new sell price.
    event PriceUpdated(uint256 indexed id, uint256 newBuyPrice, uint256 newSellPrice);
    
    // TotalSupplyUpdated event is kept for IAsset compatibility, 
    // though ERC1155 Transfer events (with zero address) also signify supply changes.
    /// @notice Emitted when the conceptual total supply of the asset is updated.
    /// @param id The ID of the asset.
    /// @param newTotalSupply The new total supply.
    event TotalSupplyUpdated(uint256 indexed id, uint256 newTotalSupply);

    /// @notice Constructor to initialize the StockAsset contract.
    /// @param initialOwner The initial owner of the contract.
    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) { 
        _transferOwnership(initialOwner);
        _nextStockId = 0; // Start with ID 0 for the first stock
    }

    /// @notice Creates a new stock type managed by this contract.
    /// @dev Only callable by the contract owner.
    /// @return newStockId The ID of the newly created stock.
    function createStock(
        string memory initialName,
        string memory initialSymbol,
        uint256 initialBuyPrice,
        uint256 initialSellPrice,
        uint256 initialTotalSupply
    ) external onlyOwner returns (uint256) {
        uint256 newStockId = _nextStockId;
        require(!_stocks[newStockId].exists, "StockAsset: Stock ID already in use");

        _stocks[newStockId] = StockData({
            name: initialName,
            symbol: initialSymbol,
            buyPrice: initialBuyPrice,
            sellPrice: initialSellPrice,
            currentTotalSupply: initialTotalSupply, // Store the minted supply
            exists: true
        });

        // Mint the initial supply to the contract owner
        if (initialTotalSupply > 0) {
            _mint(owner(), newStockId, initialTotalSupply, "");
        }

        emit AssetIssued(newStockId, owner(), initialTotalSupply, initialBuyPrice, initialName, initialSymbol, block.timestamp);
        _nextStockId++;
        return newStockId;
    }

    /// @inheritdoc IAsset
    function getBuyPrice(uint256 id) external view override returns (uint256) {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        return _stocks[id].buyPrice;
    }

    /// @inheritdoc IAsset
    function getSellPrice(uint256 id) external view override returns (uint256) {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        return _stocks[id].sellPrice;
    }

    /// @inheritdoc IAsset
    /// @notice Returns the current total minted supply for the asset.
    function assetTotalSupply(uint256 id) external view override returns (uint256) {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        return _stocks[id].currentTotalSupply;
    }

    /// @inheritdoc IAsset
    function assetName(uint256 id) external view override returns (string memory) {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        return _stocks[id].name;
    }

    /// @inheritdoc IAsset
    function assetSymbol(uint256 id) external view override returns (string memory) {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        return _stocks[id].symbol;
    }

    /// @notice Updates the buy and sell price for a specific stock asset.
    /// @dev Only callable by the contract owner.
    /// @param id The ID of the stock asset to update.
    /// @param newBuyPrice The new buy price.
    /// @param newSellPrice The new sell price.
    function updatePrice(uint256 id, uint256 newBuyPrice, uint256 newSellPrice) external onlyOwner {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        _stocks[id].buyPrice = newBuyPrice;
        _stocks[id].sellPrice = newSellPrice;
        emit PriceUpdated(id, newBuyPrice, newSellPrice);
    }

    /// @notice Updates the total supply for a specific stock asset by minting or burning tokens.
    /// @dev Tokens are minted to or burned from the contract owner.
    ///      Only callable by the contract owner.
    /// @param id The ID of the stock asset to update.
    /// @param newTotalSupply The new total supply.
    function updateTotalSupply(uint256 id, uint256 newTotalSupply) external onlyOwner {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        
        uint256 currentSupply = _stocks[id].currentTotalSupply;
        address stockManager = owner();

        if (newTotalSupply > currentSupply) {
            uint256 amountToMint = newTotalSupply - currentSupply;
            _mint(stockManager, id, amountToMint, "");
        } else if (newTotalSupply < currentSupply) {
            uint256 amountToBurn = currentSupply - newTotalSupply;
            _burn(stockManager, id, amountToBurn);
        }

        _stocks[id].currentTotalSupply = newTotalSupply;
        emit TotalSupplyUpdated(id, newTotalSupply); // IAsset specific event
    }

    /// @inheritdoc IAsset
    function getAllAssetIds() external view override returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_nextStockId);
        for (uint256 i = 0; i < _nextStockId; i++) {
            // Assumes IDs from 0 to _nextStockId-1 are potentially valid.
            ids[i] = i;
        }
        return ids;
    }

    /// @inheritdoc IAsset
    /// @notice Returns asset IDs owned by a specific user.
    function getUserAssetIds(
        address user
    ) external view override returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _nextStockId; i++) {
            if (_stocks[i].exists && balanceOf(user, i) > 0) {
                count++;
            }
        }

        uint256[] memory ownedIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _nextStockId; i++) {
            if (_stocks[i].exists && balanceOf(user, i) > 0) {
                ownedIds[index++] = i;
            }
        }
        return ownedIds;
    }

    // --- ERC1155 Required Overrides ---

    /// @notice Returns the URI for a given token ID.
    /// @dev In a production scenario, this should point to a JSON metadata file.
    /// @param id The token ID.
    /// @return The URI string.
    function uri(uint256 id) public view virtual override returns (string memory) {
        require(_stocks[id].exists, "StockAsset: URI query for non-existent token ID");
        // Example: "https://api.example.com/metadata/stockasset/{symbol}/{id}"
        // This should be a URL pointing to a JSON file conforming to the ERC1155 metadata URI JSON Schema.
        return string(abi.encodePacked("https://api.example.com/metadata/stockasset/", _stocks[id].symbol, "/", Strings.toString(id)));
    }

    // --- IAsset Implementation: Buy/Sell ---

    /// @inheritdoc IAsset
    /// @notice Allows a user to buy a specific amount of stock tokens.
    /// @dev The user must send the exact amount of ETH calculated by `tokenCount * buyPrice`.
    ///      Tokens are transferred from the contract owner's balance.
    ///      The contract owner must have approved this contract to transfer their tokens.
    ///      ETH sent by the buyer is held by this contract.
    /// @param id The ID of the stock asset to buy.
    /// @param tokenCount The amount of stock tokens to buy.
    function buyAsset(uint256 id, uint256 tokenCount) external payable override {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        require(tokenCount > 0, "StockAsset: Token count must be positive");

        StockData storage stock = _stocks[id];
        uint256 totalPrice = stock.buyPrice * tokenCount; // Solidity ^0.8.0 checks for overflow
        require(msg.value == totalPrice, "StockAsset: Incorrect ETH amount sent for buy order");

        // The owner() is the source of the tokens.
        // This contract facilitates the transfer. ETH (msg.value) remains with this contract.
        // Requires owner() to have approved this contract (address(this)) as an operator for their tokens
        // (e.g., owner() should call setApprovalForAll(address(this), true) on this contract instance).
        require(balanceOf(owner(), id) >= tokenCount, "StockAsset: Owner has insufficient stock balance for sale");
        
        _safeTransferFrom(owner(), msg.sender, id, tokenCount, ""); // Transfer tokens from owner to buyer

        // ETH (msg.value) is now held by this contract.
        // This ETH can be used for sellAsset payouts or withdrawn by the owner via a separate function (not implemented in this scope).

        emit AssetBought(id, msg.sender, tokenCount, stock.buyPrice, stock.name, block.timestamp);
    }

    /// @inheritdoc IAsset
    /// @notice Allows a user to sell a specific amount of their stock tokens.
    /// @dev Tokens are transferred from the seller (msg.sender) to the contract owner.
    ///      The seller must have approved this contract to transfer their tokens.
    ///      The contract pays the seller in ETH from its own balance.
    /// @param id The ID of the stock asset to sell.
    /// @param tokenCount The amount of stock tokens to sell.
    function sellAsset(uint256 id, uint256 tokenCount) external override {
        require(_stocks[id].exists, "StockAsset: Invalid or non-existent asset ID");
        require(tokenCount > 0, "StockAsset: Token count must be positive");

        StockData storage stock = _stocks[id];
        uint256 totalPayment = stock.sellPrice * tokenCount; // Solidity ^0.8.0 checks for overflow

        require(address(this).balance >= totalPayment, "StockAsset: Contract has insufficient ETH to fulfill sell order");
        // The seller (msg.sender) transfers tokens to the owner().
        // This contract facilitates the transfer and pays the seller from its ETH balance.
        // Requires msg.sender to have approved this contract (address(this)) as an operator for their tokens
        // (e.g., msg.sender should call setApprovalForAll(address(this), true) on this contract instance).
        require(balanceOf(msg.sender, id) >= tokenCount, "StockAsset: Seller has insufficient stock balance");

        _safeTransferFrom(msg.sender, owner(), id, tokenCount, ""); // Transfer tokens from seller to owner

        (bool success, ) = msg.sender.call{value: totalPayment}("");
        require(success, "StockAsset: ETH transfer to seller failed");

        emit AssetSold(id, msg.sender, tokenCount, stock.sellPrice, stock.name, block.timestamp);
    }
}