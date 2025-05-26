// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAsset
 * @dev Interface for a custom ERC1155 compliant token with Ownable features and asset-specific metadata.
 *
 * This interface combines standard ERC1155 functionality (via IERC1155) with ownership management
 * and additional properties to describe each token type (asset) managed by the contract.
 * These properties include its name, symbol, value per unit, total supply, and a fractional factor
 * to define its divisibility.
 *
 * Implementations of this interface are expected to be ERC1155 compliant and support ERC165 introspection.
 */
interface IAsset{
    // /**
    //  * @dev Emitted when the ownership of the contract is transferred.
    //  * @param previousOwner The address of the previous owner.
    //  * @param newOwner The address of the new owner.
    //  */
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner of the contract.
     * This owner typically has administrative privileges over the contract.
     */
    function owner() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Returns the name of the token.
     * For example, "Real Estate Share Series A".
     * @return The name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     * For example, "RESA".
     * @return The symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the value of a single unit of the token.
     * The interpretation of this value (e.g., currency, denomination) and whether it represents
     * the smallest indivisible unit or a "whole" unit (considering the fractional factor)
     * should be defined by the implementing contract.
     * @return The value per unit of the token.
     */
    function value() external view returns (uint256);

    /**
     * @dev Returns the total supply of the token.
     * This represents the total number of indivisible units minted for this specific token type.
     * @return The total supply of the token.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the fractional factor for the token.
     * This indicates how many of the smallest indivisible units of the token
     * constitute one whole conceptual unit of the asset.
     * For example, if an asset can be divided into 100 parts (like cents to a dollar),
     * the fractionalFactor would be 100. If the asset is not meant to be fractional
     * in this way (i.e., the smallest unit is the whole unit), it could return 1.
     * @return The fractional factor of the token.
     */
    function fractionalFactor() external view returns (uint256);

    // Note: All ERC1155 functions (balanceOf, safeTransferFrom, etc.) and events
    // are inherited from the IERC1155 interface.
}