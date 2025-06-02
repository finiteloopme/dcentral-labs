// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @notice Core interface for assets managed by the portfolio manager.
/// @title IAsset
/// @dev Interface for Real World Assets (RWA) on the chain.
/// @notice This interface defines the minimum required functions for any asset to be integrated into the portfolio manager.

interface IAsset {
    function getBuyPrice(uint256 id) external view returns (uint256);

    function getSellPrice(uint256 id) external view returns (uint256);

    function assetTotalSupply(uint256 id) external view returns (uint256);

    function assetName(uint256 id) external view returns (string memory);

    function assetSymbol(uint256 id) external view returns (string memory);
}