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
    string _name;                // Full descriptive name of the bond series
    string _symbol;              // Ticker symbol for the bond series
    uint256 _valuePerUnit;       // Value of one indivisible unit of the bond
    uint256 _currentTotalSupply; // Current total supply of indivisible units for this bond ID
    uint256 _fractionalFactor;   // How many indivisible units make one conceptual "whole" bond (e.g., 100 for cents in a dollar)
    bool initialized;           // Flag to check if the bond series has been created and metadata set

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
    event BondIssued(
        uint256 indexed id,
        string seriesName,
        string seriesSymbol,
        uint256 unitValue,
        uint256 initialUnitSupply,
        uint256 seriesFractionalFactor
    );

    /**
     * @dev Constructor to initialize the SovereignBond contract.
     * 
     */
    constructor(
        string memory seriesName,
        string memory seriesSymbol,
        uint256 unitValue,
        uint256 initialUnitSupply,
        uint256 seriesFractionalFactor
    ) ERC1155(string.concat("https://global.bonds/", seriesSymbol)) Ownable(msg.sender){
        // The Ownable constructor sets the initial owner.
        // The ERC1155 constructor sets the base URI for token metadata.
        initialized = true;
        createBondSeries(seriesName, seriesSymbol, unitValue, initialUnitSupply, seriesFractionalFactor);
    }

    // --- IAsset Implementation ---

    /**
     * @dev See {IAsset-name}.
     * Returns the name of the bond series for a given ID.
     * Reverts if the bond series ID has not been initialized.
     */
    function name() public view virtual override returns (string memory) {
        require(initialized, "SovereignBond: Bond series not initialized");
        return _name;
    }

    /**
     * @dev See {IAsset-symbol}.
     * Returns the symbol of the bond series for a given ID.
     * Reverts if the bond series ID has not been initialized.
     */
    function symbol() public view virtual override returns (string memory) {
        require(initialized, "SovereignBond: Bond series not initialized");
        return _symbol;
    }

    /**
     * @dev See {IAsset-value}.
     * Returns the value of a single indivisible unit of the bond for a given ID.
     * The interpretation of this value (e.g., currency, points) is defined by the system using this contract.
     * Reverts if the bond series ID has not been initialized.
     */
    function value() public view virtual override returns (uint256) {
        require(initialized, "SovereignBond: Bond series not initialized");
        return _valuePerUnit;
    }

    /**
     * @dev See {IAsset-totalSupply}.
     * Returns the total supply of indivisible units for the bond series (token ID).
     * Reverts if the bond series ID has not been initialized.
     */
    function totalSupply() public view virtual override returns (uint256) {
        require(initialized, "SovereignBond: Bond series not initialized");
        return _currentTotalSupply;
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
        require(initialized, "SovereignBond: Bond series not initialized");
        return _fractionalFactor;
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
    ) internal onlyOwner {
        require(initialized, "SovereignBond: Bond series ID already exists");
        require(bytes(seriesName).length > 0, "SovereignBond: Name cannot be empty");
        require(bytes(seriesSymbol).length > 0, "SovereignBond: Symbol cannot be empty");
        require(seriesFractionalFactor >= 1, "SovereignBond: Fractional factor must be at least 1");

        // _bondSeriesData = BondSeriesData({
        //     name: seriesName,
        //     symbol: seriesSymbol,
        //     valuePerUnit: unitValue,
        //     currentTotalSupply: initialUnitSupply,
        //     fractionalFactor: seriesFractionalFactor,
        //     initialized: true
        // });
        _name = seriesName;
        _symbol = seriesSymbol;
        _valuePerUnit = unitValue;
        _currentTotalSupply = initialUnitSupply;
        _fractionalFactor = seriesFractionalFactor;


        if (initialUnitSupply > 0) {
            super._mint(owner(), SOVEREIGN_BOND_ID, initialUnitSupply, ""); // Mint initial supply to the contract owner
        }

        emit BondIssued(SOVEREIGN_BOND_ID, seriesName, seriesSymbol, unitValue, initialUnitSupply, seriesFractionalFactor);
    }

    /**
     * @notice Mints additional units for an existing bond series.
     * @dev Can only be called by the contract owner.
     * Increases the total supply of the specified bond series and mints the new units to the contract owner.
     * @param amount The number of additional indivisible units to mint. Must be greater than zero.
     * @param data Optional data to pass to the `_mint` hook (relevant for ERC1155Receiver).
     */
    function mintAdditional(uint256 amount, bytes memory data) external onlyOwner {
        require(initialized, "SovereignBond: Bond series not initialized");
        require(amount > 0, "SovereignBond: Amount must be greater than zero");

        _currentTotalSupply += amount;
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
        require(initialized, "SovereignBond: Bond series not initialized");
        require(amount > 0, "SovereignBond: Amount must be greater than zero");
        // ERC1155's _burn function will check if `msg.sender` is `from` or approved by `from`.

        super._burn(from, SOVEREIGN_BOND_ID, amount);
        _currentTotalSupply -= amount;
    }
}