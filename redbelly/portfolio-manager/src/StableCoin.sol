// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interface/IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For type(IERC20).interfaceId, if needed for registration

/**
 * @title Stablecoin
 * @dev Implementation of a stablecoin as an ERC20 token,
 * adhering to the IAsset interface.
 * This contract represents a single type of stablecoin.
 * For the IAsset interface functions that take an `id`, this contract
 * uses `ASSET_ID` (0) for its single asset type.
 * It uses ERC165 to declare support for IAsset.
 */
contract Stablecoin is ERC20, ERC20Burnable, Ownable, ERC165, IAsset {
    // --- IAsset specific metadata ---

    // The value of one indivisible unit of the stablecoin.
    // For a stablecoin pegged 1:1 to USD with 6 decimals, 1 token = 1 USD.
    // 1 indivisible unit = 0.000001 USD.
    // If `_assetValuePerUnit` is 1, it implies the smallest unit has a nominal value of 1 (e.g., 1 micro-USD).
    // The interpretation of this "1" (e.g., its relation to a fiat currency) is external.
    uint256 private _assetValuePerUnit;

    // `fractionalFactor` for IAsset: how many indivisible units make one conceptual "whole" unit.
    // This is equivalent to 10^decimals().
    uint256 private _fractionalFactor;

    // Constant ID for the single asset type managed by this contract, as per IAsset.
    uint256 public constant ASSET_ID = 0;

    /**
     * @dev Constructor to initialize the Stablecoin.
     * @param initialOwner The address that will initially own the contract (for minting, admin actions).
     * @param name_ The name of the stablecoin (e.g., "Digital Dollar").
     * @param symbol_ The symbol of the stablecoin (e.g., "DUSD").
     * @param decimals_ The number of decimal places for the token.
     * @param assetValuePerUnit_ The value assigned to one indivisible unit of this stablecoin.
     *                           Typically 1, representing the smallest unit's nominal value.
     * @param initialSupply_ The initial total supply of the stablecoin, minted to the `initialOwner`.
     *                       Supply is in indivisible units (e.g., for 100 tokens with 6 decimals, pass 100 * 10^6).
     */
    constructor(
        address initialOwner,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 assetValuePerUnit_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) Ownable(initialOwner) ERC165() {
        require(decimals_ >= 1 && decimals_ <= 18, "Stablecoin: Decimals must be between 1 and 18"); // Common practical range
        // super._setupDecimals(decimals_); // Sets the ERC20 decimals

        require(assetValuePerUnit_ > 0, "Stablecoin: Asset value per unit must be positive");
        _assetValuePerUnit = assetValuePerUnit_;
        _fractionalFactor = 10**uint256(decimals_);

        if (initialSupply_ > 0) {
            _mint(initialOwner, initialSupply_);
        }

        // Register support for the IAsset interface
        // super._registerInterface(type(IAsset).interfaceId);
        // _registerInterface(type(IERC20).interfaceId); // ERC20s are typically not registered via ERC165 this way
    }

    // --- IAsset Implementation ---

    /**
     * @dev See {IAsset-name}. Returns the name of the stablecoin.
     */
    function name() public view virtual override(ERC20, IAsset) returns (string memory) {
        // require(id == ASSET_ID, "Stablecoin: Invalid asset ID");
        return super.name(); // Returns ERC20 name
    }

    /**
     * @dev See {IAsset-symbol}. Returns the symbol of the stablecoin.
     */
    function symbol() public view virtual override(ERC20, IAsset) returns (string memory) {
        // require(id == ASSET_ID, "Stablecoin: Invalid asset ID");
        return super.symbol(); // Returns ERC20 symbol
    }

    /**
     * @dev See {IAsset-value}. Returns the configured value of one indivisible unit of the stablecoin.
     */
    function value() public view virtual override(IAsset) returns (uint256) {
        // require(id == ASSET_ID, "Stablecoin: Invalid asset ID");
        return _assetValuePerUnit;
    }

    /**
     * @dev See {IAsset-totalSupply}. Returns the total supply of the stablecoin in indivisible units.
     */
    function totalSupply() public view virtual override(ERC20, IAsset) returns (uint256) {
        // require(id == ASSET_ID, "Stablecoin: Invalid asset ID");
        return super.totalSupply(); // Returns ERC20 totalSupply
    }

    /**
     * @dev See {IAsset-fractionalFactor}. Returns 10 raised to the power of `decimals`.
     * This indicates how many indivisible units make one whole conceptual unit of the stablecoin.
     * The `id` parameter must be `ASSET_ID`.
     */
    function fractionalFactor() public view virtual override(IAsset) returns (uint256) {
        // require(id == ASSET_ID, "Stablecoin: Invalid asset ID");
        return _fractionalFactor;
    }

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

    // // --- ERC165 / Interface Support ---

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  * Leverages ERC165's implementation. Interfaces are registered in the constructor.
    //  */
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // --- Stablecoin specific functions ---

    /**
     * @notice Mints new stablecoins and assigns them to an account.
     * @dev Can only be called by the contract owner. Increases the total supply.
     * @param to The account that will receive the minted tokens.
     * @param amount The amount of tokens to mint (in indivisible units).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // `burn(uint256 amount)` and `burnFrom(address account, uint256 amount)` are inherited from ERC20Burnable.
}