// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interface/IAsset.sol";

/**
 * @title SovereignBond
 * @dev Implementation of a Sovereign Bond as an ERC1155 token,
 * adhering to the IAsset interface. Each token ID represents a distinct
 * series or tranche of sovereign bonds (e.g., "5-Year Treasury Note Series A").
 *
 * The contract allows an owner to create new bond series, each with its unique
 * metadata including name, symbol, value per indivisible unit, total supply,
 * and a fractional factor to define divisibility.
 *
 * It inherits ERC1155 for multi-token functionality and Ownable for
 * administrative control over bond series creation and potential future
 * administrative actions.
 */
contract SovereignBond is IAsset, ERC1155, Ownable {
    uint256 SOVEREIGN_BOND_ID = 0;
    /**
     * @dev Struct to store metadata for each bond series (token ID).
     */
    struct BondSeriesData {
        string name;                // Full descriptive name of the bond series
        string symbol;              // Ticker symbol for the bond series
        uint256 valuePerUnit;       // Value of one indivisible unit of the bond
        uint256 currentTotalSupply; // Current total supply of indivisible units for this bond ID
        uint256 fractionalFactor;   // How many indivisible units make one conceptual "whole" bond (e.g., 100 for cents in a dollar)
        bool initialized;           // Flag to check if the bond series has been created and metadata set
    }

    // Mapping from token ID (bond series ID) to its specific data
    // mapping(uint256 => BondSeriesData) private _bondSeriesData;
    BondSeriesData private _bondSeriesData;

    // --- Events ---
    // OwnershipTransferred event is inherited from Ownable.
    // ERC1155 events (TransferSingle, TransferBatch, ApprovalForAll, URI) are inherited from ERC1155.

    /**
     * @dev See {Ownable-owner}.
     * Overrides the owner function to satisfy the IAsset interface requirement.
     */
    function owner() public view virtual override(Ownable, IAsset) returns (address) {
        return super.owner();
    }

    /**
     * @dev See {Ownable-transferOwnership}.
     * Overrides the transferOwnership function to satisfy the IAsset interface requirement.
     */
    function transferOwnership(address newOwner) public virtual override(Ownable, IAsset) onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Emitted when a new bond series is created.
     * @param id The ID of the new bond series.
     * @param seriesName The name of the bond series.
     * @param seriesSymbol The symbol of the bond series.
     * @param unitValue The value of one indivisible unit of the bond.
     * @param initialUnitSupply The initial total supply of indivisible units for this bond series.
     * @param seriesFractionalFactor The fractional factor for this bond series.
     */
    event BondSeriesCreated(
        uint256 indexed id,
        string seriesName,
        string seriesSymbol,
        uint256 unitValue,
        uint256 initialUnitSupply,
        uint256 seriesFractionalFactor
    );

    /**
     * @dev Constructor to initialize the SovereignBond contract.
     * @param initialOwner The address that will initially own the contract and have
     *                     administrative privileges (e.g., creating new bond series).
     * @param uri_ The base URI for token metadata, as per ERC1155 standards.
     *             It should contain '{id}' as a placeholder for the token ID,
     *             which will be replaced by the actual token ID (e.g., "https://api.example.com/tokens/{id}").
     */
    constructor(address initialOwner, string memory uri_) ERC1155(uri_) Ownable(initialOwner) {
        // The Ownable constructor sets the initial owner.
        // The ERC1155 constructor sets the base URI for token metadata.
        
    }

    // --- IAsset Implementation ---

    /**
     * @dev See {IAsset-name}.
     * Returns the name of the bond series for a given ID.
     * Reverts if the bond series ID has not been initialized.
     */
    function name() public view virtual override returns (string memory) {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        return _bondSeriesData.name;
    }

    /**
     * @dev See {IAsset-symbol}.
     * Returns the symbol of the bond series for a given ID.
     * Reverts if the bond series ID has not been initialized.
     */
    function symbol() public view virtual override returns (string memory) {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        return _bondSeriesData.symbol;
    }

    /**
     * @dev See {IAsset-value}.
     * Returns the value of a single indivisible unit of the bond for a given ID.
     * The interpretation of this value (e.g., currency, points) is defined by the system using this contract.
     * Reverts if the bond series ID has not been initialized.
     */
    function value() public view virtual override returns (uint256) {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        return _bondSeriesData.valuePerUnit;
    }

    /**
     * @dev See {IAsset-totalSupply}.
     * Returns the total supply of indivisible units for the bond series (token ID).
     * Reverts if the bond series ID has not been initialized.
     */
    function totalSupply() public view virtual override returns (uint256) {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        return _bondSeriesData.currentTotalSupply;
    }

    /**
     * @dev See {IAsset-fractionalFactor}.
     * Returns the fractional factor for a given bond series ID.
     * This indicates how many of the smallest indivisible units constitute one whole conceptual unit of the bond.
     * For example, if a bond can be divided into 100 parts (like cents to a dollar), fractionalFactor would be 100.
     * If the bond is not meant to be fractional (smallest unit is the whole unit), it should return 1.
     * Reverts if the bond series ID has not been initialized.
     */
    function fractionalFactor() public view virtual override returns (uint256) {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        return _bondSeriesData.fractionalFactor;
    }

    // owner() and transferOwnership(address newOwner) are inherited from Ownable and satisfy IAsset.

    // --- ERC165 / Interface Support ---

    /**
     * @dev See {IERC165-supportsInterface}.
     * Indicates whether this contract implements a given interface.
     * This contract supports IERC1155 (via ERC1155 base), IERC165 (via ERC1155 base), and IAsset.
     */
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
    //     return interfaceId == type(IAsset).interfaceId || super.supportsInterface(interfaceId);
    // }

    // --- Custom Functions for SovereignBond Management ---

    /**
     * @notice Creates a new series of sovereign bonds (a new token ID).
     * @dev Can only be called by the contract owner.
     * Mints the initial supply of the new bond series to the contract owner.
     * Emits a {BondSeriesCreated} event upon successful creation.
     * @param seriesName The descriptive name of the bond series (e.g., "Republic of Solidity 5Y Bond 2029"). Cannot be empty.
     * @param seriesSymbol The symbol for the bond series (e.g., "RSOL29"). Cannot be empty.
     * @param unitValue The value assigned to one indivisible unit of this bond series.
     * @param initialUnitSupply The total number of indivisible units to be minted for this series. Can be 0.
     * @param seriesFractionalFactor The factor indicating how many indivisible units form one conceptual "whole" bond. Must be at least 1.
     */
    function createBondSeries(
        string memory seriesName,
        string memory seriesSymbol,
        uint256 unitValue,
        uint256 initialUnitSupply,
        uint256 seriesFractionalFactor
    ) external onlyOwner {
        require(!_bondSeriesData.initialized, "SovereignBond: Bond series ID already exists");
        require(bytes(seriesName).length > 0, "SovereignBond: Name cannot be empty");
        require(bytes(seriesSymbol).length > 0, "SovereignBond: Symbol cannot be empty");
        require(seriesFractionalFactor >= 1, "SovereignBond: Fractional factor must be at least 1");

        _bondSeriesData = BondSeriesData({
            name: seriesName,
            symbol: seriesSymbol,
            valuePerUnit: unitValue,
            currentTotalSupply: initialUnitSupply,
            fractionalFactor: seriesFractionalFactor,
            initialized: true
        });

        if (initialUnitSupply > 0) {
            super._mint(owner(), SOVEREIGN_BOND_ID, initialUnitSupply, ""); // Mint initial supply to the contract owner
        }

        emit BondSeriesCreated(SOVEREIGN_BOND_ID, seriesName, seriesSymbol, unitValue, initialUnitSupply, seriesFractionalFactor);
    }

    /**
     * @notice Mints additional units for an existing bond series.
     * @dev Can only be called by the contract owner.
     * Increases the total supply of the specified bond series and mints the new units to the contract owner.
     * @param amount The number of additional indivisible units to mint. Must be greater than zero.
     * @param data Optional data to pass to the `_mint` hook (relevant for ERC1155Receiver).
     */
    function mintAdditional(uint256 amount, bytes memory data) external onlyOwner {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        require(amount > 0, "SovereignBond: Amount must be greater than zero");

        _bondSeriesData.currentTotalSupply += amount;
        super._mint(owner(), SOVEREIGN_BOND_ID, amount, data); // Mint additional supply to the contract owner
    }

    /**
     * @notice Burns (destroys) units of a bond series owned by an account.
     * @dev The caller must be the owner of the tokens or be approved to manage them.
     * Decreases the total supply of the specified bond series.
     * @param from The account from which to burn tokens.
     * @param amount The number of indivisible units to burn. Must be greater than zero.
     */
    function burn(address from, uint256 amount) external virtual {
        require(_bondSeriesData.initialized, "SovereignBond: Bond series not initialized");
        require(amount > 0, "SovereignBond: Amount must be greater than zero");
        // ERC1155's _burn function will check if `msg.sender` is `from` or approved by `from`.

        super._burn(from, SOVEREIGN_BOND_ID, amount);
        _bondSeriesData.currentTotalSupply -= amount;
    }
}